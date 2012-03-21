Unit Procesos;

{ * Procesos :                                                           *
  *                                                                      *
  * Esta unidad se encarga de la creacion y eliminacion de procesos      *
  * aqui no estan implementadas las llamadas al sistema ,                *
  *                                                                      *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>           *
  * All Rights Reserved                                                  *
  *                                                                      *
  * Versiones :                                                          *
  *                                                                      *
  * 05 / 07 / 04 : Se aplica el modelo de memoria paginada               *
  *                                                                      *
  * 20 / 03 / 04 : Depuracion                                            *
  *                                                                      *
  * 20 / 12 / 03 : Primera Version                                       *
  *                                                                      *
  ************************************************************************

}

interface

{DEFINE DEBUG}
{DEFINE STAT}

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Toro/signal.inc}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/gdt.h}
{$I ../Include/Head/signal.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/open.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/paging.h}
{$I ../Include/Head/vmalloc.h}
{$I ../Include/Head/inodes.h}
{$I ../Include/Head/itimer.h}
{$I ../Include/Head/dcache.h}

{$DEFINE Use_Hash}
{$DEFINE Use_Tail}

{$DEFINE nodo_struct := p_tarea_struc }
{$DEFINE next_nodo := next_tarea }
{$DEFINE prev_nodo := prev_tarea }


{ colas que aqui son manipuladas }
const Tq_WaitPid : p_tarea_struc = nil ;
      Tq_Zombies : p_tarea_struc = nil ;


var Pid_T:dword;
    Tq_Interrumpidas : p_tarea_struc ;
    Hash_Pid : array[1..Max_HashPid] of p_tarea_struc;


procedure proceso_eliminar(Tarea:p_tarea_struc);
procedure proceso_interrumpir(Tarea:p_tarea_struc ; var Cola : p_tarea_struc);
procedure proceso_reanudar(Tarea:p_tarea_struc;var Cola : p_tarea_struc );



implementation


{$I ../Include/Head/list.h}
{$I ../Include/Head/lock.h}


function nuevo_pid:dword;
begin
pid_t += 1;
exit (pid_t);
end;



{ * Thread_Crear :                                                      *
  *                                                                     *
  * Kernel_Ip : Puntero a codigo del kernel                             *
  * Retorno : puntero al thread o nil se falla                          *
  *                                                                     *
  * Funcion que crea un thread de kernel , por ahora no estan implemen  *
  * tados dentro del sistema                                            *
  *                                                                     *
  ***********************************************************************
}
function thread_crear(Kernel_IP:pointer):p_tarea_struc;[public , alias : 'THREAD_CREAR'];
var stack,stack0:pointer;
    nuevo_tss,cont:word;
    tmp:^struc_descriptor;
    begin

{ son protegidos los recursos }
Gdt_Lock;
Mem_Lock;

If ( Gdt_Huecos_Libres = 0 ) then
  begin
   Gdt_Unlock;
   Mem_Unlock;
   exit(nil);
  end;

If (nr_free_page < 3) then
  begin
   Gdt_Unlock;
   Mem_Unlock;
   exit(nil);
  end;

{ Se pide memoria para la imagen de thread y el stack }
Thread_Crear := get_free_kpage;

stack := get_free_kpage;

nuevo_tss := Gdt_Set_Tss(@Thread_Crear^.reg);

{ son liberados los recursos }
Mem_Unlock;
Gdt_Unlock;

with Thread_Crear^ do
 begin
 Politica := Sched_RR;
 pid := Nuevo_Pid;
 Padre_Pid := 0;
 quantum_a := 0;
 tss_Descp := nuevo_tss;
 tss_p   := pointer(GDT_NUEVA +(nuevo_tss -1 )*8);
 dir_page:= Kernel_Pdt;
 reg.cr3 := Kernel_Pdt;
 reg.cs  := KERNEL_CODE_SEL;
 reg.ds  := KERNEL_DATA_SEL;
 reg.es  := KERNEL_DATA_SEL;
 reg.gs  := KERNEL_DATA_SEL;
 reg.ss  := KERNEL_DATA_SEL;
 reg.fs  := KERNEL_DATA_SEL;
 reg.esp := stack + Page_Size - 1;
 reg.eip := Kernel_IP;
 reg.eflags := $202;
 flags_de_signal := 0;
 virtual_time := 0 ;
 real_time := contador ;
 nice := 0 ;
 for cont:= 0 to NR_OPEN do Archivos[cont].f_op := nil;
 end;

 {$IFDEF DEBUG}
  printk('/nThread Nuevo ---> Pid /V %d \n',[Thread_Crear^.pid],[]);
 {$ENDIF}

add_task(Thread_Crear);

exit(Thread_Crear);
end;



{ * Proceso_Crear :                                                      *
  *                                                                      *
  * Ppid : Pid del Padre                                                 *
  * Politica : Politica para la planif el proceso                        *
  *                                                                      *
  * Esta funcion devuelve un puntero a una nueva tarea , esta es creada  *
  * pero no agregada a la cola de listas  , tampoco el PDT de usuario    *
  * El proceso es creado "limpio"                                        *
  * Trabaja sobre la zona alta                                           *
  *                                                                      *
  ************************************************************************
}

function proceso_crear (ppid:dword;sched:word):p_tarea_struc;[public , alias : 'PROCESO_CREAR' ];
var nuevo_tss , ret : word;
    stack0 , pdt : pointer;

begin

{ Es protegido el acceso a los recursos }
Gdt_Lock;
Mem_Lock;

{ ahora se vera si hay recursos para la operacion }
If (Gdt_Huecos_Libres = 1) then
 begin
  Mem_Unlock;
  Gdt_Unlock;
  exit(nil);
 end;

If nr_free_page < 3 then
 begin
  Mem_Unlock;
  Gdt_Unlock;
  exit(nil);
 end;

{ estas llamadas no pueden devolver nil }
Proceso_Crear := get_free_kpage;
stack0 := get_free_kpage;

pdt   := get_free_kpage;
nuevo_tss := Gdt_Set_Tss(@Proceso_Crear^.reg);

{ son liberados }
Mem_Unlock;
Gdt_Unlock;


{ Es copiada la zona baja donde se encuentra el codigo  y datos del kernel }
{ en maquinas en que la memoria supere 1GB , el kernel no puede acceder con }
{ el pdt del usuario a mas alla de el primer GB , por lo tanto devera abrir }
{ el Kernel_PDT y luego restaurarlo }

memcopy(Kernel_Pdt , pdt , Page_Size);

With Proceso_Crear^ do
 begin

  Politica  := Sched ;
  pid       := Nuevo_Pid;
  Padre_pid := PPid;
  quantum_a := 0;
  Tss_Descp := nuevo_tss;
  Tss_P     := pointer(GDT_NUEVA +(nuevo_tss -1 )*8);

  stack0_page := stack0;
  dir_page   := pdt;
  reg.cr3    := pdt;

  reg.eip :=nil;
  reg.esp :=nil;
  reg.cs  :=USER_CODE_SEL;
  reg.ds  :=USER_DATA_SEL;
  reg.ss  :=USER_DATA_SEL;
  reg.es  :=USER_DATA_SEL;
  reg.fs  :=USER_DATA_SEL;
  reg.gs  :=USER_DATA_SEL;
  reg.ss0 :=KERNEL_DATA_SEL;
  reg.esp0:= stack0 + Page_Size -1;

  { Punteros de retorno del proceso del modo nucleo }
  ret_esp := reg.esp0 - 8 ;
  ret_eip := reg.esp0 - 20;

  reg.eflags:=$202;

  flags_de_signal:=0;

  { Directorio de inicio }
  cwd := nil ;

  for ret:= 0 to NR_OPEN do
   begin
   Archivos[ret].f_op := nil;
   Archivos[ret].inodo := nil;
  end;

  for ret:= 0 to 31 do signals[ret] := nil ;

  timer.estado := false ;
  timer.tarea := Proceso_Crear;
  nice := 0 ;

  real_time := contador ;
  virtual_time := 0 ;
  end;

{ Cola ordenada por nacimiento }
Hash_Push(Proceso_Crear);

end;



{ * Proceso_Clonar                                                      *
  *                                                                     *
  * Tarea_Padre : Tarea que sera clonada                                *
  * Retorno : Puntero a la nueva tarea o nil si falla                   *
  *                                                                     *
  * Esta funcion se encarga de crear un copia exacta del proceso dado   *
  * y de todas las area de memoria , estas son recreadas y no comparti  *
  * das                                                                 *
  *                                                                     *
  ***********************************************************************
}
function proceso_clonar(Tarea_Padre:p_tarea_struc):p_tarea_struc;[ Public , Alias : 'PROCESO_CLONAR'];
var size,tmp:dword;
    tarea_hijo:p_tarea_struc;
    ret:dword;
    ori,dest:pointer;
begin


tarea_hijo := Proceso_Crear(Tarea_Padre^.pid,Tarea_Padre^.Politica);

If tarea_hijo=nil then exit(nil);

{ Tama¤o del proceso padre }
size := Tarea_Padre^.text_area.size + Tarea_Padre^.data_area.size + Tarea_Padre^.stack_area.size;

Mem_Lock;

{ Hay memoria para clonar el proceso? }
If nr_free_page < (size div Page_Size) then
 begin
 Mem_Unlock;
 Proceso_Eliminar (Tarea_Hijo);
 exit(nil);
 end;

Save_Cr3;
Load_Kernel_Pdt;

{ Son creadas las areas vmm }
With Tarea_Hijo^ do
 begin
 text_area.size := 0;
 text_area.flags := VMM_WRITE;
 text_area.add_l_comienzo := pointer(HIGH_MEMORY);
 text_area.add_l_fin := pointer(HIGH_MEMORY - 1) ;

 stack_area.size :=0;
 stack_area.flags := VMM_WRITE;
 stack_area.add_l_comienzo := pointer(STACK_PAGE);
 stack_area.add_l_fin := pointer(STACK_PAGE);
end;


  { La zona de codigo es duplicada }
  vmm_alloc(Tarea_Hijo,@Tarea_Hijo^.text_area,Tarea_Padre^.text_area.size);
  vmm_copy(Tarea_Padre,Tarea_Hijo,@Tarea_Padre^.text_area,@Tarea_Hijo^.text_area);


  { El area de pila es alocada y copiada tal cual }
  vmm_alloc(Tarea_hijo,@Tarea_Hijo^.stack_area,Tarea_Padre^.stack_area.size);
  vmm_copy(Tarea_Padre,Tarea_Hijo,@Tarea_Padre^.stack_area,@Tarea_Hijo^.stack_area);

Mem_Unlock;

{ Se heredan los desc de archivos }
for ret:= 0 to NR_OPEN do Clone_Filedesc(@Tarea_Padre^.Archivos[ret],@Tarea_Hijo^.Archivos[ret]);

{ es heredado el inodo de trabajo }
Tarea_hijo^.cwd := Tarea_Padre^.cwd ;
Tarea_hijo^.cwd^.count += 1;

Restore_Cr3;

exit(Tarea_Hijo);
end;




{ * Proceso_Interrumpir:                                                  *
  *                                                                       *
  * Tarea:Tarea que sera interrumpida                                     *
  * Cola : Cola donde se encuentra interrumpida                           *
  *                                                                       *
  * Este procedimiento detiene la ejecucion de un procedimiento           *
  * que no estuviese ya interrumpido . Luego de detenerlo llama al        *
  * planificador para que cambie de tarea                                 *
  *                                                                       *
  *************************************************************************
}

procedure proceso_interrumpir(Tarea:p_tarea_struc ; var Cola : p_tarea_struc);[public , alias :'PROCESO_INTERRUMPIR'];
begin

{ Zona critica }
cerrar;

{ Esto nunca puede ocurrir }
If Tarea^.estado = Tarea_Interrumpida Then exit;

{ Pasa a estado interrumpida }
Tarea^.estado := Tarea_Interrumpida;

{ Es agregada a la cola de interrumpidas }
Push_Node(tarea,Cola);

{ Re planificar }
Scheduling;

{ Aqui vuelve y son manejadas las se¤ales }
Signaling;

end;



{ * Proceso_Reanudar                                                      *
  *                                                                       *
  * Tarea : Puntero a la tarea interrumpida                               *
  * Cola : Cola ligada donde se encuentra la tarea                        *
  *                                                                       *
  * Este procedimiento Reanuda una tarea que estubiese interrumpiada      *
  * por IO o por un despertador                                           *
  *                                                                       *
  *************************************************************************
}
procedure proceso_reanudar(Tarea:p_tarea_struc;var Cola : p_tarea_struc ); [public , alias :'PROCESO_REANUDAR'];
begin

if (Tarea = nil ) or (Cola = nil ) then exit ;

Tarea^.estado := Tarea_Lista ;

{ Se quita la tarea de la cola interrumpida }
Pop_Node (tarea,Cola);

{ la tarea pasa a la cola para ser planificado rapidamente }
add_interrupt_task (tarea);

{ se llamara al planificador en la proxima irq de relog }
if Tarea_Actual <> tarea then need_sched := true

end;




{ * Proceso_Eliminar :                                                  *
  *                                                                     *
  * Tarea : Puntero a la tarea eliminada                                *
  *                                                                     *
  * Procedimiento usado pocas veces para eliminar un proceso totalmente *
  * de la memoria                                                       *
  *                                                                     *
  ***********************************************************************
}
procedure proceso_eliminar(Tarea:p_tarea_struc);[public , alias :'PROCESO_ELIMINAR'];
begin
Hash_Pop(Tarea);
free_page(Tarea^.stack0_page);
Gdt_Quitar(Tarea^.tss_descp);
free_page(Tarea^.dir_page);
free_page(Tarea);
end;




{ * Proceso_Destruir :                                                 *
  *                                                                    *
  * Tarea : Tarea q sera destruida                                     *
  *                                                                    *
  * llamada para destruir un proceso , que puede ser provocada por una *
  * execpcion o una se¤al  , si es un proceso padre es eliminada tota  *
  * talmente del sistema pero si posee padre , se vuelve un zombie , y *
  * sera destruida cuando el padre realice un WAITPID                  *
  *                                                                    *
  **********************************************************************
}

procedure proceso_destruir(Tarea:p_tarea_struc);[public , alias :'PROCESO_DESTRUIR'];
var padre,hijos:p_tarea_struc;
    tmp:word;
begin

{$IFDEF DEBUG}
 printk('/VProcesos/n : Tiempo de vida de Pid %d : /V%d \n',[tarea^.pid , contador - tarea^.real_time],[]);
{$ENDIF}

{ es devuelto el inodo de trabajo }
put_dentry (Tarea_actual^.cwd^.i_dentry);

Load_Kernel_Pdt;

{ las areas de codigo son liberadas }
vmm_free(Tarea,@Tarea^.text_area);
vmm_free(Tarea,@Tarea^.stack_area);

{ Son cerrados todos los archivos }
for tmp := 0 to Nr_Open do If Tarea^.Archivos[tmp].f_op <> nil then  Sys_Close(tmp);

{ Si el proceso padre tuviera hijos al morir este todos los hijos }
{se volverian hijos directos de INIT }

hijos := Tq_Zombies;

If hijos = nil then
 else

 { se rastrea la cola en busca de hijos }
 repeat

  If hijos^.padre_pid=Tarea^.padre_pid then hijos^.padre_pid:=1;
  hijos := hijos^.next_tarea;

 until (Hijos = Tq_Zombies);

{ La tarea ahora sera zombie }
Tarea^.estado := Tarea_Zombie;

{ Se agrega a la cola de zombies }
Push_Node (Tarea,Tq_Zombies);


{ Si el padre estubiese esperando en la cola WaitPid , se reanuda }
{para que mate al proceso hijo }

padre := Tq_WaitPid;

If padre = nil then
 else
  begin

  { Se rastrea todo la cola en busca del padre }
  repeat
   If padre^.pid = Tarea^.padre_pid then
    begin
     Proceso_Reanudar( Padre , Tq_WaitPid );
     exit;
    end;

  padre := Padre^.next_tarea;

  until (Padre = Tq_WaitPid);

 end;

{ el padre esta interrumpido o en la cola listos }
padre := Hash_Get (Tarea^.padre_pid);

{ se le avisa al padre que devera hacer Wait_Pid }
Signal_Send (padre , Sig_Hijo);

end;



{ * Esperar_Hijo :                                                      *
  *                                                                     *
  * Tarea_Padre : Puntero a la tarea en busca de hijos                  *
  * Pidh : Devuelve el Pid del hijo muerto                              *
  * Err_code : devuelve el numero de error del proceso hijo             *
  *                                                                     *
  * Se encarga de devolver la causa de terminacion de un proceso hijo   *
  *  y si no hubiese ninguno se interrumpe en espera de un proceso hijo *
  *                                                                     *
  ***********************************************************************
}
procedure esperar_hijo(Tarea_Padre:p_tarea_struc;var PidH:dword;var err_code:word);[public , alias :'ESPERAR_HIJO'];
var tmp:p_tarea_struc;
label 1,2;
begin


1 : tmp := Tq_Zombies ;

If (tmp = nil) then goto 2;

repeat

 { la tarea busca a sus hijos }

 { se encontro un hijo }
 If (tmp^.padre_pid = Tarea_Padre^.pid) then
  begin

  PidH := tmp^.pid;
  err_code := tmp^.terminacion;

  { se quita de la cola zombie }
  Pop_Node(tmp,Tq_Zombies);

  { Es eliminada todo la memoria que queda del proceso }
  Proceso_Eliminar (tmp);
  exit;
 end;

 tmp := tmp^.next_tarea;

until (tmp=nil) or (tmp=Tq_Zombies);

{ Parece que no hay hijos la tarea es interrumpida }
2 : Proceso_Interrumpir (Tarea_Padre , Tq_WaitPid);

goto 1;
end;


{ * Proceso_Init :                                                      *
  *                                                                     *
  * Aqui se inicializan las variables de la unidad procesos             *
  *                                                                     *
  ***********************************************************************
}
procedure proceso_init ; [public,alias:'PROCESO_INIT'];
var ret : dword ;
begin
Pid_t := 0 ;
Tq_Interrumpidas := nil ;
Tarea_Actual := nil ;
contador := 0 ;

{ Son inicializadas todas las colas }
for ret := 1 to Max_HashPid do Hash_Pid[ret] := nil ;

end;



end.
