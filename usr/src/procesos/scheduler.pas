Unit Scheduler;

{ * Scheduler:                                                        *
  *                                                                   *
  * Esta Unidad esta destinada a planificar la tarea que se ejecutara *
  * segun la implementacion de 2 algotimos FIFO Y ROUND ROBIN , se    *
  * de captar las IRQ del relog e incrementar el contador             *
  *                                                                   *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>        *
  * All Rights Reserved                                               *
  *                                                                   *
  * Versiones :                                                       *
  *                                                                   *
  * 04 / 01 / 06 : Es reescrito el modelo de planificacion            *
  *                                                                   *
  * 26 / 04 / 05 : Es reescrito todo el planificador y la mayor parte *
  * del esquema de planificacion  , tambien con creadas nuevas sys    *
  * calls para manipular el scheduler .                               *
  *                                                                   *
  * 6 / 12 / 03 :  Version Inicial                                    *
  *                                                                   *
  *********************************************************************

}


interface

{DEFINE DEBUG}

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/irq.h}
{$I ../Include/Head/gdt.h}
{$I ../Include/Head/idt.h}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/itimer.h}
{$I ../Include/Head/ktimer.h}
{$I ../Include/Head/signal.h}
{$I ../Include/Head/printk_.h}

{$DEFINE Use_Tail}
{$DEFINE Use_Hash}
{$DEFINE nodo_struct := p_tarea_struc }
{$DEFINE next_nodo := next_tarea }
{$DEFINE prev_nodo := prev_tarea }

{ colas aqui manipuladas }
const tq_rr : p_tarea_struc = nil ;
      tq_fifo : p_tarea_struc = nil ;


var  Tarea_Actual : p_tarea_struc;
     need_sched : boolean;


procedure Scheduling ;

implementation

{$I ../Include/Head/ioport.h}
{$I ../Include/Head/list.h}


procedure load_task(tarea : p_tarea_struc);inline;
begin
FARJUMP((Tarea^.tss_descp-1)*8,nil);
end;


{ * Agrega una tarea a alguna de las dos colas de tareas convencionales * }

procedure add_task(tarea:p_tarea_struc) ; [public ,alias : 'ADD_TASK'];
begin
case Tarea^.politica of
Sched_RR : Push_Node(Tarea,Tq_rr);
Sched_FIFO : Push_node (Tarea,Tq_FIFO);
end;
end;


{ * Quita una tarea de alguna de las dos colas de tareas convecionales  * }

procedure remove_task(tarea:p_tarea_struc) ; [public , alias : 'REMOVE_TASK'];
begin
case Tarea^.politica of
Sched_RR : Pop_Node (Tarea,Tq_rr);
Sched_FIFO : Pop_Node (Tarea , Tq_FIFO);
end;
end;

{ * agrega una tarea que estubo bloqueada a la cola de listas * }

procedure add_interrupt_task ( tarea : p_tarea_struc ) ; [public , alias : 'ADD_INTERRUPT_TASK'];
begin
if tarea^.politica = sched_fifo then push_node_first (tarea , tq_fifo)
 else push_node_first (tarea ,tq_rr);
end;





{ * Scheduler_Handler:                                                     *
  *                                                                        *
  * Este procedimiento declarado como interrupt , se encarga de captar las *
  * interrupciones generadas por el relog del sistma IRQ 0 , suma el       *
  * contador de quantums de la tarea actual y si su tiempo expira llama al *
  * scheduling que planifica otra tarea                                    *
  *                                                                        *
  **************************************************************************
}
procedure scheduler_handler;interrupt;[public , alias :'SCHEDULER_HANDLER'];
label _back , _sched ;
begin

enviar_byte ($20,$20);

{ or la ejecucion de timers del nucleo }
do_ktimer ;

{ Incremento el contador de tiemers de usuarios  }
timer_inc;

{ incremento del tiempo virtual del proceso }
Tarea_Actual^.virtual_time += 1;

{ Se solicito que se llame al planificador }
if need_sched then goto _sched ;

{ las tareas fifo no poseen quantums y no pueden ser desalojadas }
if Tarea_Actual^.politica = Sched_FIFO then goto _back;

Tarea_Actual^.quantum_a += 1;

if (Tarea_Actual^.quantum_a <> quantum) then goto _back;

 _sched :

 { La tarea vuelve a la cola listos  , solo las rr llegan aqui}
 push_node (Tarea_Actual,Tq_rr);
 Tarea_Actual^.estado := Tarea_Lista ;
 Scheduling;

_back:

{ Se verifican las se¤ales pendientes }
Signaling;

end;




{ * Scheduling:                                                           *
  *                                                                       *
  * Aqui se encuentra todo el proceso de planificacion se poseen dos al   *
  * goritmos FIFO y RR                                                    *
  *                                                                       *
  * Versiones :                                                           *
  *                                                                       *
  * 04 / 01 / 2006 : Es modificada la planificacion para optimizar los    *
  * procesos con mucha io                                                 *
  *                                                                       *
  * 05 / 04 / 2005 : Se aplica el nuevo modelo de planificacion           *
  *                                                                       *
  * ?? / ?? / ???? : Primera Version                                      *
  *************************************************************************
}

procedure scheduling ; [public , alias :'SCHEDULING'];
label _load , _fifo ;
var  task_sched : p_tarea_struc ;
begin

cerrar;

        { las fifo se encuentran por sobre las RR }

_fifo :

        if Tq_fifo <> nil then
         begin
          task_sched := Tq_fifo ;
         goto _load ;
         end;

        { si no hay ninguna tarea aguardo por alguna irq }

        if tq_rr = nil then
         begin
          abrir ;
          while (tq_rr = nil ) do  if (tq_fifo <> nil) then goto _fifo ;
         end;

         { simple turno rotatorio RR }
         Task_sched := Tq_rr ;

_load :

        remove_task (Task_sched);
        need_sched:= false ;

        Task_sched^.quantum_a := 0 ;

        if (Tarea_Actual = task_sched ) then exit ;

        Tarea_Actual := Task_sched ;

        Tarea_Actual^.estado := Tarea_Corriendo;
        Tarea_Actual^.tss_p^.tipo := TSS_SIST_LIBRE;

        Load_Task ( Tarea_Actual );

end;



{ * Sys_SetScheduler :                                                  *
  *                                                                     *
  * Pid : Pid de la tarea que modificara su scheduler                   *
  * politica : Numero planificador                                      *
  * prioridad : No implementada                                         *
  * Retorno : 0 si ok o -1 si falla                                     *
  *                                                                     *
  * Llamada al sistema que modifica el planificador de la tarea dada en *
  * pid , dado que se trabaja con prioridad estaticas por ahora no se   *
  * implementa el campo prioridad                                       *
  *                                                                     *
  ***********************************************************************
}
function sys_setscheduler ( pid , politica , prioridad : dword ) : dword ; cdecl ; [public , alias : 'SYS_SETSCHEDULER'];
var task : p_tarea_struc ;
begin

task := Hash_Get (pid) ;

set_errno := -ESRCH ;

if task = nil then exit(-1);

{solo las propias tareas y los padres pueden modificar un planificador}
if tarea_actual^.pid = task^.pid then
 else if (Tarea_Actual^.pid <> task^.padre_pid) then
  begin
   set_errno := -ECHILD ;
   exit (-1);
  end;

set_errno := -EINVAL ;

case politica of
SCHED_RR : begin
            task^.politica := SCHED_RR ;
            task^.estado := Tarea_Lista ;
            clear_errno ;
           end;
SCHED_FIFO : begin
              task^.politica := SCHED_FIFO ;
              task^.estado := Tarea_Lista ;
              Push_Node (task,Tq_fifo);
              Scheduling;
              clear_errno ;
             end;
else  exit(-1);


exit(0);
end;

exit(0);

end;




{ * Sys_GetScheduler :                                                  *
  *                                                                     *
  * Pid : Pid de la tarea de la que se devolvera el planificador        *
  * Retorno : la politica o -1 si falla                                 *
  *                                                                     *
  * Llamada al sistema que devuelve la politica implementada en la tarea*
  * dada en pid                                                         *
  *                                                                     *
  ***********************************************************************
}
function sys_getscheduler (pid : dword ) : dword ; cdecl ; [public , alias : 'SYS_GETSCHEDULER'];
var task : p_tarea_struc ;
begin

set_errno := -ESRCH ;

task := Hash_Get (pid) ;

if (task = nil) then exit(-1);

clear_errno;
exit(task^.politica);
end;


{ * Scheduler_Init :                                                     *
  *                                                                      *
  * Procediemiento que inicializa la tarea del sched y crear sus reg     *
  * coloca la INT CALL en la IDT al manejador del INT del relog , inicia *
  * el PIT a 1000HZ y Habilita la IRQ 0                                  *
  *                                                                      *
  ************************************************************************
}

procedure scheduler_init;[public,alias :'SCHEDULER_INIT'];
begin
contador := 0;
Wait_Short_Irq(0,@Scheduler_Handler);
need_sched := false;
Iniciar_Relog;
end;

end.
