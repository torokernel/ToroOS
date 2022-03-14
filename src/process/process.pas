//
// process.pas
//
// This unit contains functions to handle processes.
// 
// Copyright (c) 2003-2022 Matias Vara <matiasevara@gmail.com>
// All Rights Reserved
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
Unit process;

interface

uses memory, printk, arch, filesystem;

 Const
{ POSIX error codes

  Definitions taken from the POSIX programmer's guide }
   MAX_ERROR = 124;
 EPERM		 = 1;	{ Operation not permitted }
 ENOENT		 = 2;	{ No such file or directory }
 ESRCH		 = 3;	{ No such process }
 EINTR		 = 4;	{ Interrupted system call }
 EIO		 = 5;	{ I/O error }
 ENXIO		 = 6;	{ No such device or address }
 E2BIG		 = 7;	{ Arg list too long }
 ENOEXEC	 = 8;	{ Exec format error }
 EBADF		 = 9;	{ Bad file number }
 ECHILD		 = 10;	{ No child processes }
 EAGAIN	 	 = 11;	{ Try again }
 ENOMEM		 = 12;	{ Out of memory }
 EACCES		 = 13;	{ Permission denied }
 EFAULT		 = 14;	{ Bad address }
 ENOTBLK	 = 15;	{ Block device required }
 EBUSY		 = 16;	{ Device or resource busy }
 EEXIST		 = 17;	{ File exists }
 EXDEV		 = 18;	{ Cross-device link }
 ENODEV		 = 19;	{ No such device }
 ENOTDIR	 = 20;	{ Not a directory }
 EISDIR		 = 21;	{ Is a directory }
 EINVAL		 = 22;	{ Invalid argument }
 ENFILE		 = 23;	{ File table overflow }
 EMFILE		 = 24;	{ Too many open files }
 ENOTTY		 = 25;	{ Not a typewriter }
 ETXTBSY	 = 26;	{ Text file busy }
 EFBIG		 = 27;	{ File too large }
 ENOSPC		 = 28;	{ No space left on device }
 ESPIPE		 = 29;	{ Illegal seek }
 EROFS		 = 30;	{ Read-only file system }
 EMLINK		 = 31;	{ Too many links }
 EPIPE		 = 32;	{ Broken pipe }
 EDOM		 = 33;	{ Math argument out of domain of func }
 ERANGE		 = 34;	{ Math result not representable }
 EDEADLK	 = 35;	{ Resource deadlock would occur }
 ENAMETOOLONG	 = 36;	{ File name too long }
 ENOLCK		 = 37;	{ No record locks available }
 ENOSYS		 = 38;	{ Function not implemented }
 ENOTEMPTY	 = 39;	{ Directory not empty }
 ELOOP		 = 40;	{ Too many symbolic links encountered }
 EWOULDBLOCK	 = EAGAIN;	{ Operation would block }
 ENOMSG		 = 42;	{ No message of desired type }
 EIDRM		 = 43;	{ Identifier removed }
 ECHRNG		 = 44;	{ Channel number out of range }
 EL2NSYNC	 = 45;	{ Level 2 not synchronized }
 EL3HLT		 = 46;	{ Level 3 halted }
 EL3RST		 = 47;	{ Level 3 reset }
 ELNRNG		 = 48;	{ Link number out of range }
 EUNATCH	 = 49;	{ Protocol driver not attached }
 ENOCSI		 = 50;	{ No CSI structure available }
 EL2HLT		 = 51;	{ Level 2 halted }
 EBADE		 = 52;	{ Invalid exchange }
 EBADR		 = 53;	{ Invalid request descriptor }
 EXFULL		 = 54;	{ Exchange full }
 ENOANO		 = 55;	{ No anode }
 EBADRQC	 = 56;	{ Invalid request code }
 EBADSLT	 = 57;	{ Invalid slot }
 EDEADLOCK	 = EDEADLK;
 EBFONT		 = 59;	{ Bad font file format }
 ENOSTR		 = 60;	{ Device not a stream }
 ENODATA	 = 61;	{ No data available }
 ETIME		 = 62;	{ Timer expired }
 ENOSR		 = 63;	{ Out of streams resources }
 ENONET		 = 64;	{ Machine is not on the network }
 ENOPKG		 = 65;	{ Package not installed }
 EREMOTE	 = 66;	{ Object is remote }
 ENOLINK	 = 67;	{ Link has been severed }
 EADV		 = 68;	{ Advertise error }
 ESRMNT		 = 69;	{ Srmount error }
 ECOMM		 = 70;	{ Communication error on send }
 EPROTO		 = 71;	{ Protocol error }
 EMULTIHOP	 = 72;	{ Multihop attempted }
 EDOTDOT	 = 73;	{ RFS specific error }
 EBADMSG	 = 74;	{ Not a data message }
 EOVERFLOW	 = 75;	{ Value too large for defined data type }
 ENOTUNIQ	 = 76;	{ Name not unique on network }
 EBADFD		 = 77;	{ File descriptor in bad state }
 EREMCHG	 = 78;	{ Remote address changed }
 ELIBACC	 = 79;	{ Can not access a needed shared library }
 ELIBBAD	 = 80;	{ Accessing a corrupted shared library }
 ELIBSCN	 = 81;	{ .lib section in a.out corrupted }
 ELIBMAX	 = 82;	{ Attempting to link in too many shared libraries }
 ELIBEXEC	 = 83;	{ Cannot exec a shared library directly }
 EILSEQ		 = 84;	{ Illegal byte sequence }
 ERESTART	 = 85;	{ Interrupted system call should be restarted }
 ESTRPIPE	 = 86;	{ Streams pipe error }
 EUSERS		 = 87;	{ Too many users }
 ENOTSOCK	 = 88;	{ Socket operation on non-socket }
 EDESTADDRREQ	 = 89;	{ Destination address required }
 EMSGSIZE	 = 90;	{ Message too long }
 EPROTOTYPE	 = 91;	{ Protocol wrong type for socket }
 ENOPROTOOPT	 = 92;	{ Protocol not available }
 EPROTONOSUPPORT	= 93;	{ Protocol not supported }
 ESOCKTNOSUPPORT	= 94;	{ Socket type not supported }
 EOPNOTSUPP	 = 95;	{ Operation not supported on transport endpoint }
 ENOTSUP	 = EOPNOTSUPP; { Operation not supported on transport endpoint }
 EPFNOSUPPORT	 = 96;	{ Protocol family not supported }
 EAFNOSUPPORT	 = 97;	{ Address family not supported by protocol }
 EADDRINUSE	 = 98;	{ Address already in use }
 EADDRNOTAVAIL	 = 99;	{ Cannot assign requested address }
 ENETDOWN	 = 100;	{ Network is down }
 ENETUNREACH	 = 101;	{ Network is unreachable }
 ENETRESET	 = 102;	{ Network dropped connection because of reset }
 ECONNABORTED	 = 103;	{ Software caused connection abort }
 ECONNRESET	 = 104;	{ Connection reset by peer }
 ENOBUFS	 = 105;	{ No buffer space available }
 EISCONN	 = 106;	{ Transport endpoint is already connected }
 ENOTCONN	 = 107;	{ Transport endpoint is not connected }
 ESHUTDOWN	 = 108;	{ Cannot send after transport endpoint shutdown }
 ETOOMANYREFS	 = 109;	{ Too many references: cannot splice }
 ETIMEDOUT	 = 110;	{ Connection timed out }
 ECONNREFUSED	 = 111;	{ Connection refused }
 EHOSTDOWN	 = 112;	{ Host is down }
 EHOSTUNREACH	 = 113;	{ No route to host }
 EALREADY	 = 114;	{ Operation already in progress }
 EINPROGRESS	 = 115;	{ Operation now in progress }
 ESTALE		 = 116;	{ Stale NFS file handle }
 EUCLEAN	 = 117;	{ Structure needs cleaning }
 ENOTNAM	 = 118;	{ Not a XENIX named type file }
 ENAVAIL	 = 119;	{ No XENIX semaphores available }
 EISNAM		 = 120;	{ Is a named type file }
 EREMOTEIO	 = 121;	{ Remote I/O error }
 EDQUOT		 = 122;	{ Quota exceeded }
 ENOMEDIUM	 = 123;	{ No medium found }
 EMEDIUMTYPE	 = 124;	{ Wrong medium type }
 EEOF = 125 ;
 
Stack_Page = $80000000;

 Quantum = 100;

 Max_HashPid = 1000 ;

 Tarea_Lista=1;
 Tarea_Corriendo=2;
 Tarea_Interrumpida=4;
 Tarea_Zombie=5;

 nice_bajo = 1 ;
 nice_normal = 2 ;
 nice_alto = 3 ;

 Nr_Syscall=50;

 Sched_Fifo = $1 ;
 Sched_RR   = $2 ;

Max_Signal = 31;

Sig_Morir   = 0;
Sig_Detener = 1;
Sig_Alarm   = 2;
Sig_ili  = 3;
Sig_Segv = 4;
Sig_DivE = 5 ;
Sig_FpuE = 6 ;
Sig_BrkPoint = 7 ;
Sig_OverFlow = 8 ;
Sig_Reanudar = 12 ;
Sig_Hijo = 13 ;
Sig_Usr  = 30;
Sig_Usr1 = 31;

Sig_Name : array[0..8] of string[20] = ('Sig_Morir'#0,' ',' ','Sig_ili'#0,
                                        'Sig_Segv'#0 , 'Sig_DivE'#0 ,
                                        'Sig_FpuE'#0 , 'Sig_BrkPoint'#0 ,
                                        'Sig_Overflow'#0 );
Type
 p_struc_timer=^struc_timer;

 struc_timer = record
 interval : dword ;
 time_action:dword;
 end;

 p_timer_kernel = ^struc_timer_kernel ;

 struc_timer_kernel = record
 timer : struc_timer ;
 handler : procedure ( param : dword ) ;
 param : dword ;
 next_timer : p_timer_kernel ;
 prev_timer : p_timer_kernel ;
 end;


 p_timer_user = ^struc_timer_user ;

 struc_timer_user = record
 timer : struc_timer;
 tarea:pointer;
 estado:boolean;
 next_timer:p_timer_user;
 prev_timer:p_timer_user;

end;
 p_Tarea_struc=^Tarea_struc;

 Tarea_struc=record

 pid : dword;           
 PaDre_Pid : dword;     
 estado : byte;         
 Terminacion : byte;   
 Politica : byte; 

 quantum_a : byte;
 errno : dword ;

 virtual_time : dword ;

 real_time : dword ;
 nice : word ;

 tss_descp : word;
 tss_p : ^struc_descriptor;

 reg:tss_struc;

 ret_eip  , ret_esp : pointer;

 signals : array[0..31] of pointer;
 flags_de_signal : dword;

 dir_page : pointer;

 stack0_page : pointer;

 text_area  : vmm_area_struc;
 data_area  : vmm_area_struc;
 stack_area : vmm_area_struc;

 Despertador : struc_timer;
 Timer : struc_timer_user;

 Archivos:array[0..32] of file_t;
 cwd:p_inode_t;

 next_tarea:p_tarea_struc;
 prev_tarea:p_tarea_struc;
 hash_next:p_tarea_struc;
 hash_prev:p_tarea_struc;
 end;
 
const Tq_WaitPid : p_tarea_struc = nil ;
      Tq_Zombies : p_tarea_struc = nil ;
      tq_ktimers: p_timer_kernel = nil;
      tq_Alarmas: p_timer_user = nil;
      tq_Dormidas : p_tarea_Struc = nil;

var Pid_T:dword;
    Tq_Interrumpidas : p_tarea_struc ;
    Hash_Pid : array[1..Max_HashPid] of p_tarea_struc;

procedure proceso_eliminar(Tarea:p_tarea_struc);
procedure proceso_interrumpir(Tarea:p_tarea_struc ; var Cola : p_tarea_struc);
procedure proceso_reanudar(Tarea:p_tarea_struc;var Cola : p_tarea_struc );
procedure Process_init ;
procedure scheduler_init;
procedure scheduling ;
procedure vmm_copy(Task_Ori,Task_Dest:p_tarea_struc;vmm_area_ori,vmm_area_dest:p_vmm_area);
function vmm_clone(Task_P,Task_H:p_tarea_struc;vmm_area_p,vmm_area_h:p_vmm_area):dword;
function vmm_free(Task:p_tarea_struc;vmm_area:p_vmm_area):dword;
function vmm_alloc(Task:p_tarea_struc;vmm_area:p_vmm_area;size:dword):dword;
function vmm_map(page:pointer;Task:p_tarea_struc;vmm_area:p_vmm_area):dword;
function proceso_crear (ppid:dword;sched:word):p_tarea_struc;
procedure add_task(tarea:p_tarea_struc);
procedure lock (queue : p_wait_queue);
procedure unlock (queue : p_wait_queue);
procedure wait_long_irq(Irq:byte);
procedure add_timer ( timer : p_timer_kernel ) ;
procedure del_timer ( timer : p_timer_kernel ) ;
procedure wait_short_irq(Irq:byte;Handler:pointer);
function sys_waitpid(var status:dword):dword;cdecl;
function sys_readerrno : dword ; cdecl ;
function sys_fork:dword;cdecl;
procedure sys_exit(status:word);cdecl;

var
  Gdt_wait: wait_queue;
  Mem_wait: wait_queue;
  Tarea_Actual : p_tarea_struc;
  Contador: dword;

implementation

{$I ../arch/macros.inc}


{$DEFINE gdt_lock := lock (@gdt_wait) }
{$DEFINE gdt_unlock := unlock (@gdt_wait) }
{$DEFINE mem_lock := lock (@mem_wait) ; }
{$DEFINE mem_unlock := unlock (@mem_wait) ;}

const tq_rr : p_tarea_struc = nil ;
      tq_fifo : p_tarea_struc = nil ;

var  need_sched : boolean;
     Irq_Wait : array [ 0..15] of p_tarea_struc ;
     irq_flags : word ;

const Tq_WaitIrq : p_tarea_struc = nil ;


procedure signaling; forward;
procedure Pop_Task(Nodo : p_tarea_struc;var Nodo_tail : p_tarea_struc); forward;
procedure Push_Task(Nodo: p_tarea_struc; var nodo_tail: p_tarea_struc); forward;
function Hash_Get (Pid : dword) : p_tarea_struc; forward;
procedure Hash_Push(Tarea:p_tarea_struc); forward;
procedure Hash_Pop(Tarea:p_tarea_struc); forward;
procedure signal_send(Tarea:p_tarea_struc;signal:word); forward;
procedure add_interrupt_task ( tarea : p_tarea_struc ); forward;

procedure lock (queue : p_wait_queue);
begin
if queue^.lock then proceso_interrumpir (tarea_actual,queue^.lock_wait);
cerrar;
queue^.lock := true ;
abrir;
end;

procedure unlock (queue : p_wait_queue) ;
begin
cerrar;
queue^.lock := false ;
proceso_reanudar (queue^.lock_wait,queue^.lock_wait);
abrir;
end;

function nuevo_pid:dword;
begin
pid_t += 1;
exit (pid_t);
end;

function thread_crear(Kernel_IP:pointer):p_tarea_struc;
var stack,stack0:pointer;
    nuevo_tss,cont:word;
    tmp:^struc_descriptor;
    begin

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

Thread_Crear := get_free_kpage;

stack := get_free_kpage;

nuevo_tss := Gdt_Set_Tss(@Thread_Crear^.reg);

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

function proceso_crear (ppid:dword;sched:word):p_tarea_struc;
var nuevo_tss , ret : word;
    stack0 , pdt : pointer;

begin

Gdt_Lock;
Mem_Lock;

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

Proceso_Crear := get_free_kpage;
stack0 := get_free_kpage;

pdt   := get_free_kpage;

nuevo_tss := Gdt_Set_Tss(@Proceso_Crear^.reg);

Mem_Unlock;
Gdt_Unlock;

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

  ret_esp := reg.esp0 - 8 ;
  ret_eip := reg.esp0 - 20;

  reg.eflags:=$202;

  flags_de_signal:=0;

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

Hash_Push(Proceso_Crear);

end;

function proceso_clonar(Tarea_Padre:p_tarea_struc):p_tarea_struc;
var size,tmp:dword;
    tarea_hijo:p_tarea_struc;
    ret:dword;
    ori,dest:pointer;
begin


tarea_hijo := Proceso_Crear(Tarea_Padre^.pid,Tarea_Padre^.Politica);

If tarea_hijo=nil then exit(nil);

size := Tarea_Padre^.text_area.size + Tarea_Padre^.data_area.size + Tarea_Padre^.stack_area.size;

Mem_Lock;

If nr_free_page < (size div Page_Size) then
 begin
 Mem_Unlock;
 Proceso_Eliminar (Tarea_Hijo);
 exit(nil);
 end;

Save_Cr3;
Load_Kernel_Pdt;

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


  vmm_alloc(Tarea_Hijo,@Tarea_Hijo^.text_area,Tarea_Padre^.text_area.size);
  vmm_copy(Tarea_Padre,Tarea_Hijo,@Tarea_Padre^.text_area,@Tarea_Hijo^.text_area);


  vmm_alloc(Tarea_hijo,@Tarea_Hijo^.stack_area,Tarea_Padre^.stack_area.size);
  vmm_copy(Tarea_Padre,Tarea_Hijo,@Tarea_Padre^.stack_area,@Tarea_Hijo^.stack_area);

Mem_Unlock;

for ret:= 0 to NR_OPEN do Clone_Filedesc(@Tarea_Padre^.Archivos[ret],@Tarea_Hijo^.Archivos[ret]);

Tarea_hijo^.cwd := Tarea_Padre^.cwd ;
Tarea_hijo^.cwd^.count += 1;

Restore_Cr3;

exit(Tarea_Hijo);
end;

procedure proceso_interrumpir(Tarea:p_tarea_struc ; var Cola : p_tarea_struc);
begin

cerrar;

If Tarea^.estado = Tarea_Interrumpida Then exit;

Tarea^.estado := Tarea_Interrumpida;

Push_Task(tarea,Cola);

Scheduling;

Signaling;
end;

procedure proceso_reanudar(Tarea:p_tarea_struc;var Cola : p_tarea_struc );
begin

if (Tarea = nil ) or (Cola = nil ) then exit ;

Tarea^.estado := Tarea_Lista ;

Pop_Task (tarea,Cola);

add_interrupt_task (tarea);

if Tarea_Actual <> tarea then need_sched := true
end;

procedure proceso_eliminar(Tarea:p_tarea_struc);
begin
Hash_Pop(Tarea);
free_page(Tarea^.stack0_page);
Gdt_Quitar(Tarea^.tss_descp);
free_page(Tarea^.dir_page);
free_page(Tarea);
end;

procedure proceso_destruir(Tarea:p_tarea_struc);
var padre,hijos:p_tarea_struc;
    tmp:word;
begin

{$IFDEF DEBUG}
 printk('/VProcesos/n : Tiempo de vida de Pid %d : /V%d \n',[tarea^.pid , contador - tarea^.real_time],[]);
{$ENDIF}

put_dentry (Tarea_actual^.cwd^.i_dentry);

Load_Kernel_Pdt;

vmm_free(Tarea,@Tarea^.text_area);
vmm_free(Tarea,@Tarea^.stack_area);

for tmp := 0 to Nr_Open do If Tarea^.Archivos[tmp].f_op <> nil then  Sys_Close(tmp);

hijos := Tq_Zombies;

If hijos = nil then
 else

 repeat

  If hijos^.padre_pid=Tarea^.padre_pid then hijos^.padre_pid:=1;
  hijos := hijos^.next_tarea;

 until (Hijos = Tq_Zombies);

Tarea^.estado := Tarea_Zombie;

Push_Task (Tarea,Tq_Zombies);

padre := Tq_WaitPid;

If padre = nil then
 else
  begin

  repeat
   If padre^.pid = Tarea^.padre_pid then
    begin
     Proceso_Reanudar( Padre , Tq_WaitPid );
     exit;
    end;

  padre := Padre^.next_tarea;

  until (Padre = Tq_WaitPid);

 end;

padre := Hash_Get (Tarea^.padre_pid);

Signal_Send (padre , Sig_Hijo);
end;

procedure esperar_hijo(Tarea_Padre:p_tarea_struc;var PidH:dword;var err_code:word);
var tmp:p_tarea_struc;
label 1,2;
begin


1 : tmp := Tq_Zombies ;

If (tmp = nil) then goto 2;

repeat

 If (tmp^.padre_pid = Tarea_Padre^.pid) then
  begin

  PidH := tmp^.pid;
  err_code := tmp^.terminacion;

  Pop_Task(tmp,Tq_Zombies);

  Proceso_Eliminar (tmp);
  exit;
 end;

 tmp := tmp^.next_tarea;

until (tmp=nil) or (tmp=Tq_Zombies);

2 : Proceso_Interrumpir (Tarea_Padre , Tq_WaitPid);

goto 1;
end;

procedure load_task(tarea : p_tarea_struc);
begin
FARJUMP((Tarea^.tss_descp-1)*8,nil);
end;

procedure Pop_Task(Nodo : p_tarea_struc;var Nodo_tail : p_tarea_struc);inline;
begin

If (nodo_tail= nodo) and (nodo_tail^.next_tarea = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_tarea := nil;
 nodo^.next_tarea := nil;
 exit;
end;

if (Nodo_tail = nodo) then Nodo_tail := Nodo^.next_tarea ;

nodo^.prev_tarea^.next_tarea := nodo^.next_tarea ;
nodo^.next_tarea^.prev_tarea := nodo^.prev_tarea ;
nodo^.next_tarea := nil ;
nodo^.prev_tarea := nil;
end;

procedure Push_Task(Nodo: p_tarea_struc; var nodo_tail: p_tarea_struc);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_tarea := Nodo ;
 nodo^.prev_tarea := Nodo ;
 exit;
end;

nodo^.prev_tarea := nodo_tail^.prev_tarea ;
nodo^.next_tarea := nodo_tail ;
nodo_tail^.prev_tarea^.next_tarea := Nodo ;
nodo_tail^.prev_tarea := Nodo ;
end;

procedure Push_Task_First ( nodo : p_tarea_struc; var Nodo_Tail : p_tarea_struc) ; inline ;
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_tarea := Nodo ;
 nodo^.prev_tarea := Nodo ;
 exit;
end;

nodo^.prev_tarea := nodo_tail^.prev_tarea;
nodo^.next_tarea := nodo_tail ;
nodo_tail^.prev_tarea^.next_tarea := nodo;
nodo_tail^.prev_tarea := nodo ;
nodo_tail := nodo ;
end;

function Hash_Get (Pid : dword) : p_tarea_struc;
var pos:dword;
    l:p_tarea_struc;
begin

pos := Pid mod Max_HashPid ;

If Hash_Pid[pos]^.pid = Pid  then
 exit(Hash_Pid[pos])
 else
  begin
   l := Hash_Pid[pos] ;

   repeat
   If l^.pid = Pid then exit(l);
   l := l^.hash_next;
   until (l = Hash_Pid[pos]);
  end;
exit(nil);
end;

procedure Hash_Push(Tarea:p_tarea_struc);inline;
var pos:dword;
begin

pos := Tarea^.pid mod Max_HashPid ;

 If Hash_Pid[pos] = nil then
  begin
  Hash_Pid[pos] := Tarea;
  Tarea^.hash_next := Tarea;
  Tarea^.hash_prev := Tarea;
  end
   else
    begin
      Tarea^.hash_next := Hash_Pid[pos]^.hash_next ;
      Tarea^.hash_next := Hash_Pid[pos];
      Hash_Pid[pos]^.hash_prev^.hash_next := Tarea ;
      Hash_Pid[pos]^.hash_prev := tarea ;
   end;
end;

procedure Hash_Pop(Tarea:p_tarea_struc);inline;
var pos:dword;
begin

pos := Tarea^.pid mod Max_HashPid ;


 If Hash_Pid[pos] = Tarea then
  begin
   Hash_Pid[pos] := nil ;
   Tarea^.hash_prev := nil ;
   Tarea^.hash_next := nil ;
  end
   else
    begin
    Tarea^.hash_prev^.hash_next:=tarea^.hash_next;
    Tarea^.hash_next^.hash_prev:=tarea^.hash_prev;
    Tarea^.hash_prev:=nil;
    Tarea^.hash_next:=nil;
    end;
end;

procedure add_task(tarea:p_tarea_struc) ;
begin
case Tarea^.politica of
Sched_RR : Push_Task(Tarea,Tq_rr);
Sched_FIFO : Push_Task (Tarea,Tq_FIFO);
end;
end;

procedure remove_task(tarea:p_tarea_struc) ;
begin
case Tarea^.politica of
Sched_RR : Pop_Task (Tarea,Tq_rr);
Sched_FIFO : Pop_Task (Tarea , Tq_FIFO);
end;
end;

procedure add_interrupt_task ( tarea : p_tarea_struc ) ;
begin
if tarea^.politica = sched_fifo then Push_Task_first (tarea , tq_fifo)
 else Push_Task_first (tarea ,tq_rr);
end;

procedure Push_Timer(Nodo : p_timer_kernel);
begin

If tq_ktimers = nil then
 begin
 tq_ktimers := Nodo ;
 nodo^.next_timer := Nodo ;
 nodo^.prev_timer := Nodo ;
 exit;
end;

nodo^.prev_timer := tq_ktimers^.prev_timer ;
nodo^.next_timer := tq_ktimers ;
tq_ktimers^.prev_timer^.next_timer := Nodo ;
tq_ktimers^.prev_timer := nodo ;
end;

procedure Pop_Timer(Nodo : p_timer_kernel);
begin

If (tq_ktimers= nodo) and (tq_ktimers^.next_timer = tq_ktimers) then
 begin
 tq_ktimers := nil ;
 nodo^.prev_timer := nil;
 nodo^.next_timer := nil;
 exit;
end;

nodo^.prev_timer^.next_timer := nodo^.next_timer ;
nodo^.next_timer^.prev_timer := nodo^.prev_timer ;
end;

procedure Pop_User_Timer(Nodo : p_timer_user);
begin

If (tq_alarmas= nodo) and (tq_alarmas^.next_timer = tq_alarmas) then
 begin
 tq_alarmas := nil ;
 nodo^.prev_timer := nil;
 nodo^.next_timer := nil;
 exit;
end;

nodo^.prev_timer^.next_timer := nodo^.next_timer ;
nodo^.next_timer^.prev_timer := nodo^.prev_timer ;
end;

procedure add_timer ( timer : p_timer_kernel ) ;
begin
cerrar;
timer^.timer.time_action := contador + timer^.timer.interval ;
push_timer(timer);
abrir;
end;

procedure del_timer ( timer : p_timer_kernel ) ;
begin
cerrar;
pop_timer (timer);
abrir;
end;

procedure do_ktimer;
var tm , tmp : p_timer_kernel ;
begin

if tq_ktimers = nil then exit ;

tm := tq_ktimers ;


repeat

 if (tm^.timer.time_action <= contador ) then
  begin
   tmp := tm^.next_timer ;
   del_timer (tm) ;
   tm^.handler (tmp^.param) ;
   tm := tmp ;
  end
   else tm := tm^.next_timer ;

until ( tm = tq_ktimers) or ( tq_ktimers = nil) ;

end;

procedure timer_Inc;
var tarea_d,Tarea_p : p_tarea_struc;
    timer_tmp  , timer_t : p_timer_user;

begin

contador += 1;

tarea_d := tq_dormidas;

 If (tq_dormidas <> nil) then
  begin

    repeat

      if (tarea_d^.Despertador.time_action <= contador) then
       begin
        Tarea_p := Tarea_d^.prev_tarea;
        Proceso_Reanudar (tarea_d , tq_dormidas);
        Tarea_d := Tarea_p;
       end;

    Tarea_d := Tarea_d^.next_tarea;
    until (Tarea_D=tq_dormidas) or (tq_dormidas=nil) ;

  end;

if (tq_alarmas = nil) then exit;

timer_tmp := tq_alarmas;

  repeat

  if (Timer_tmp^.timer.time_action <= contador) then
   begin
    timer_tmp^.estado := false;
    timer_t := timer_tmp^.prev_timer ;

    Pop_User_Timer(timer_tmp);
    Signal_Send(Timer_tmp^.tarea,SIG_ALARM);

    timer_tmp := timer_t ;
    end;

  timer_tmp := timer_tmp^.next_timer;

  until (Timer_tmp = tq_alarmas);

end;

procedure scheduler_handler;interrupt;
label _back , _sched ;
begin
enviar_byte ($20,$20);

do_ktimer ;

timer_inc;

Tarea_Actual^.virtual_time += 1;

if need_sched then goto _sched ;

if Tarea_Actual^.politica = Sched_FIFO then goto _back;

Tarea_Actual^.quantum_a += 1;

if (Tarea_Actual^.quantum_a <> quantum) then goto _back;

 _sched :

 Push_Task (Tarea_Actual,Tq_rr);
 Tarea_Actual^.estado := Tarea_Lista ;
 Scheduling;

_back:

Signaling;

end;

procedure scheduling ;
label _load , _fifo ;
var  task_sched : p_tarea_struc ;
begin

cerrar;

_fifo :

        if Tq_fifo <> nil then
         begin
          task_sched := Tq_fifo ;
         goto _load ;
         end;

        if tq_rr = nil then
         begin
          abrir ;
          while (tq_rr = nil ) do  if (tq_fifo <> nil) then goto _fifo ;
         end;

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

function enpilar_signal (new_ret : pointer ) : dword ;
var tmp , esp : ^dword ;
    s : dword ;
begin

tmp := Tarea_Actual^.ret_eip ;

s := tmp^ ;

tmp^ := longint(new_ret);

tmp := Tarea_Actual^.ret_esp ;

tmp^ -= 4;

esp := pointer(tmp^) ;

esp^ := s ;

exit(0);
end;

procedure kernel_signal_handler;
var tarea:pointer ;
begin

//printk('$d',[],[Tarea_Actual^.pid]);
printkf('/nMuerte por Se¤al : %s \n',[dword(@Sig_name[tarea_actual^.terminacion][1])]);

Proceso_destruir (Tarea_Actual);

scheduling;
end;

procedure signaling;
var tmp  , ret : dword ;
    ret2 : word;
    signal_handler , tarea: pointer ;
begin

for tmp:= 0 to 31 do
 begin

  if Bit_Test(@Tarea_Actual^.flags_de_signal,tmp) then
   begin

   signal_handler := Tarea_actual^.signals[tmp];

   bit_reset(@Tarea_Actual^.flags_de_signal,tmp);

   case tmp of
   Sig_Hijo : begin
              Esperar_Hijo (Tarea_Actual,ret,ret2);
              continue;
              end;
   Sig_Morir:begin

              Tarea_Actual^.terminacion := Sig_Morir ;
              Proceso_Destruir (Tarea_Actual) ;

              Scheduling;

              exit;
             end;
   Sig_Detener:begin
                Proceso_Interrumpir (Tarea_Actual,Tq_Interrumpidas);
                exit;
               end;
   Sig_Alarm:begin
              Enpilar_signal (signal_handler);
              Tarea_Actual^.signals[Sig_Alarm] := nil ;
             end;
   Sig_ili : begin

             if signal_handler = nil then
              begin
               Tarea_actual^.terminacion := Sig_ili ;
               kernel_signal_handler;
              end;

             end;
   Sig_Segv : begin

              if signal_handler = nil then
               begin
                Tarea_actual^.terminacion := Sig_Segv ;
                kernel_signal_handler;
               end;

              end;
   Sig_Dive : begin

              if signal_handler = nil then
               begin
                Tarea_actual^.terminacion := Sig_Dive ;
                kernel_signal_handler;
               end;

              end;
   Sig_Fpue : begin

              if signal_handler = nil then
               begin
                Tarea_actual^.terminacion := Sig_Fpue ;
                kernel_signal_handler;
               end;

              end;
   Sig_BrkPoint : begin

                  if signal_handler = nil then
                   begin
                    Tarea_Actual^.terminacion := Sig_brkpoint ;
                    kernel_signal_handler;
                   end;

                  end;
   Sig_OverFlow : begin

                  if signal_handler = nil then
                   begin
                    Tarea_Actual^.terminacion := Sig_Overflow ;
                    kernel_signal_handler;
                   end;

                  end;


       end;

   Enpilar_Signal (signal_handler);
   Tarea_Actual^.signals[tmp] := nil ;
   end;
  end;

end;

procedure signal_send(Tarea:p_tarea_struc;signal:word);
begin

cerrar;

if Tarea_Actual= nil then Panic ('/nImposible cargar toro  , excepcion desconocida !!!!\n');

if Bit_test(@tarea^.flags_de_signal,signal) then exit;

Bit_Set(@Tarea^.flags_de_signal,signal);

abrir;

{$IFDEF DEBUG}
  printkf('/nSignal : %d /n --> Pid : %d /V Send\n',[signal,Tarea_actual^.pid]);
{$ENDIF}

end;

Procedure irq_master;interrupt;
var irq:byte;
begin
asm
mov dx , $20                            
mov al , $b                             
out dx , al                             
nop
nop
nop
xor ax , ax
in  al , dx                             
mov irq , al
xor ax , ax

mov ax , $20                            
out dx , al
end;


irq := bin_to_dec (irq) ;

If Irq = -1 then exit;

Bit_Reset (@irq_flags,irq);
Proceso_Reanudar(Irq_Wait[irq] , Tq_WaitIrq);
abrir;
end;

procedure irq_esclavo;interrupt;
var irq:byte;
begin
asm
mov dx , $A0
mov al , $b
out dx , al
nop
nop
nop
xor ax , ax
in  al , dx
mov irq , al

mov ax , $20
out dx , al
end;

irq := bin_to_dec (irq);

If Irq = -1 then exit;

irq += 8 ;

bit_reset (@irq_flags,irq);

Proceso_Reanudar(Irq_Wait[irq] , Tq_WaitIrq);

abrir;
end;

procedure wait_long_irq(Irq:byte);
var cont : dword ;
begin
cerrar;

If Bit_Test(@Irq_Flags,Irq) then exit
 else Bit_Set(@Irq_Flags,Irq);

Irq_Wait[Irq] := Tarea_Actual ;

Habilitar_irq(irq);
Proceso_Interrumpir(Tarea_Actual , Tq_WaitIrq);

Dhabilitar_irq (irq);

abrir;
end;

procedure wait_short_irq(Irq:byte;Handler:pointer);
begin
If Bit_Test(@Irq_Flags,Irq) then exit
 else Bit_Set(@Irq_Flags,Irq);
set_int_gate(Irq + 32 , Handler);
Habilitar_Irq(irq);
end;

function vmm_map(page:pointer;Task:p_tarea_struc;vmm_area:p_vmm_area):dword;
var total_pg,tmp:dword;
    at:word;
begin
 at:=0;

 case vmm_area^.flags of
 VMM_WRITE:at:=Present_Page or User_Mode or Write_page;
 VMM_READ :at:=Present_Page or User_Mode;
 end;

 vmm_area^.add_l_fin += 1;

 umapmem(page,vmm_area^.add_l_fin ,task^.dir_page,at);
 vmm_area^.add_l_fin+=Page_Size - 1 ;

 vmm_area^.size+=Page_Size;

exit(0);
end;

function vmm_alloc(Task:p_tarea_struc;vmm_area:p_vmm_area;size:dword):dword;
var total_pg,tmp:dword;
    page,add_l:pointer;
    at:word;
begin

total_pg := (size div Page_Size);
If (size mod Page_Size)=0 then else total_pg+=1;

If total_pg > nr_free_page then exit(-1);

for tmp:= 1 to total_pg do
 begin
 page := get_free_page;
 vmm_map(page,Task,vmm_area);
 end;

exit(0);
end;

function vmm_free(Task:p_tarea_struc;vmm_area:p_vmm_area):dword;
var i,f:dword;
    pg,fpg:pointer;
Begin

If vmm_area^.size = 0 then exit;

pg:=vmm_area^.add_l_comienzo;

repeat
Unload_Page_Table(pg,Task^.dir_page);
pg += Page_Size * 1024;
until (vmm_area^.add_l_comienzo <= vmm_area^.add_l_fin);

vmm_area^.add_l_comienzo:=nil;
vmm_area^.add_l_fin:=nil;
vmm_area^.size:=0;
vmm_area^.flags:=0;

exit(0);

end;

function vmm_clone(Task_P,Task_H:p_tarea_struc;vmm_area_p,vmm_area_h:p_vmm_area):dword;
var add_f:pointer;
    total_tp,tmp:dword;
    i,fin:indice;
    pt_p,pt_h:^dword;
begin


i := Get_Page_Index(vmm_area_p^.add_l_comienzo);
fin := Get_Page_Index(vmm_area_p^.add_l_fin);
pt_p := Task_P^.dir_page;
pt_h := Task_H^.dir_page;

for tmp:= i.dir_I to fin.dir_i do
  begin
  add_f := pointer(longint(pt_p[tmp]) and $FFFFF000);

  dup_page_table(add_f);

  pt_h[tmp] := pt_p[tmp];
end;

vmm_area_h^:=vmm_area_p^;

exit(0);
end;

procedure vmm_copy(Task_Ori,Task_Dest:p_tarea_struc;vmm_area_ori,vmm_area_dest:p_vmm_area);
var tmp:dword;
    ori,dest:pointer;
begin
for tmp:= 0 to (vmm_area_ori^.size div Page_Size)-1 do
 begin
 ori := vmm_area_ori^.add_l_comienzo + (tmp * Page_Size);
 ori := Get_Phys_Add(ori,Task_Ori^.dir_page);
 dest := vmm_area_dest^.add_l_comienzo + (tmp * Page_Size);
 dest := Get_Phys_Add(dest,Task_Dest^.dir_page);
 memcopy(ori,dest,Page_Size);
 end;
end;

procedure iniciar_relog;
begin

asm
          mov eax,1191180
          mov ebx,1000
          xor edx,edx
          div ebx
          mov ecx,eax
          mov al,52
          out $43,al
          mov al,cl
          out $40,al
          mov al,ch
          out $40,al

end;
end;

//TODO: handle this better
procedure excep_Ignore;[nostackframe];assembler;
asm
xor eax, eax
pop eax
pop ecx
mov ebx, $1235
cli
hlt
end;


procedure excep_0;
begin
Signal_Send (Tarea_Actual,Sig_DivE);
Signaling;
end;


procedure excep_2;
begin
{Exceciones NMI}
Panic('/nExecp NMI!!!!\n');
asm
hlt
end;
end;


procedure excep_3;
begin
Signal_Send (Tarea_Actual,Sig_Brkpoint);
Signaling;
end;


procedure excep_4;
begin
Signal_Send (Tarea_Actual,Sig_Overflow);
Signaling;
end;


procedure excep_5;
begin
Signal_Send (Tarea_Actual,Sig_Morir);
Signaling;
end;



procedure excep_6;
begin
Signal_Send (Tarea_Actual,Sig_ili);
Signaling;
end;



procedure excep_7;
begin
Signal_Send (Tarea_Actual,Sig_Morir);
Signaling;
end;


procedure excep_8;
begin
Signal_Send (Tarea_Actual,Sig_Morir);
Signaling;
end;


procedure excep_9;
begin
Signal_Send (Tarea_Actual,Sig_morir);
Signaling;
end;


procedure excep_10;
begin
Signal_Send (Tarea_Actual,Sig_Morir);
Signaling;
end;


procedure excep_11;
begin
Signal_Send (Tarea_Actual,Sig_Segv);
Signaling;
end;


procedure excep_12;
begin
Signal_Send (Tarea_Actual,Sig_Segv);
Signaling;
end;


procedure excep_13;
begin
Signal_Send (Tarea_Actual,Sig_Segv);
Signaling;
end;

procedure excep_14;
begin
Signal_Send (Tarea_Actual,Sig_Segv);
Signaling;
end;

procedure excep_16;
begin
Signal_Send (Tarea_Actual,Sig_Fpue);
Signaling;
end;

procedure excep_init;
var m: dword;
begin
set_int_gate(0,@Excep_0);
set_int_gate(1,@Excep_ignore);
set_int_gate(2,@Excep_2);
set_int_gate(3,@Excep_3);
set_int_gate(4,@Excep_4);
set_int_gate(5,@Excep_5);
set_int_gate(6,@Excep_6);
set_int_gate(7,@Excep_7);
set_int_gate(8,@excep_8);
set_int_gate(10,@excep_10);
set_int_gate(11,@excep_11);
set_int_gate(12,@excep_12);
set_int_gate(13,@excep_13);
set_int_gate(14,@excep_14);
set_int_gate(15,@Excep_ignore);
set_int_gate(16,@excep_16);
end;

function sys_waitpid(var status:dword):dword;cdecl;
var pid:dword;
    err:word;
begin
esperar_hijo(Tarea_Actual,Pid,err);
status:=err;
exit(pid);
end;

{$DEFINE set_errno := Tarea_Actual^.errno  }
{$DEFINE clear_errno := Tarea_Actual^.errno := 0 }

function sys_readerrno : dword ; cdecl ;
var errno : dword ;
begin
errno := set_errno ;
clear_errno ;
exit(errno);
end;

function sys_fork:dword;cdecl;
var hijo:p_tarea_struc;
    err:word;
    ip_ret,esp_ret,ebp_ret,eflags_ret:dword;
    l:dword;
begin


asm
mov eax , [ebp + 44]
mov ip_ret , eax
mov eax , [ebp + 28]
mov ebp_ret , eax
mov eax , [ebp + 56]
mov esp_ret , eax
mov eax , [ebp + 52 ]
mov eflags_ret , eax
end;


Hijo := Proceso_Clonar(Tarea_Actual);

If hijo = nil then exit(0);


Hijo^.reg.eip := pointer(ip_ret) ;
Hijo^.reg.esp := pointer(esp_ret) ;
Hijo^.reg.ebp := pointer(ebp_ret);
Hijo^.reg.eax := 0 ;

add_task (Hijo);
exit(hijo^.pid);
end;

procedure sys_exit(status:word);cdecl;
begin
cerrar;
Tarea_actual^.terminacion:= status;
Signal_Send(Tarea_Actual,Sig_Morir);
Signaling;
end;

procedure Process_init ;
var ret : dword ;
begin
Pid_t := 0 ;
Tq_Interrumpidas := nil ;
Tarea_Actual := nil ;
contador := 0 ;
for ret := 1 to Max_HashPid do Hash_Pid[ret] := nil;
// irqs
irq_flags := 0 ;
for ret:= 0 to 15 do Irq_Wait[ret] := nil ;
for ret:= 33 to 39 do set_int_gate(ret,@Irq_Master);
for ret:= 40 to 47 do set_int_gate(ret,@Irq_Esclavo);
excep_init;
gdt_wait.lock_wait := nil ;
mem_wait.lock_wait := nil ;
end;

procedure scheduler_init;
begin
Wait_Short_Irq(0,@Scheduler_Handler);
need_sched := false;
Iniciar_Relog;
end;


end.
