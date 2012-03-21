Unit Sys_Procesos;

{ * Sys_Procesos :
  *                                                            *
  * Implementacion de las llamadas al sistema de los procesos  *
  * algunas no estan provadas hasta el momento                 *
  *                                                            *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com> *
  * All Rights Reserved                                        *
  *                                                            *
  * Versiones   :                                              *
  * 30 - 03 - 04 :Version Inicial                              *
  *                                                            *
  **************************************************************
}

interface

{DEFINE DEBUG}


{$I ../Include/Head/asm.h}
{$I ../Include/Toro/procesos.inc}
{$I ../Include/Toro/signal.inc}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/signal.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/read_write.h}
{$I ../Include/Head/printk_.h}

{$DEFINE Use_Hash}

implementation

{$I ../Include/Head/list.h}


{ * Sys_Getpid :
  *                                                             *
  * Retorno : Numero de pid de la tarea actual                  *
  *                                                             *
  * Llamada al sistema que devuelve el pid de la tarea actual   *
  *                                                             *
  ***************************************************************
}
function sys_getpid:dword;cdecl;[public , alias :'SYS_GETPID'];
begin
exit(Tarea_actual^.pid);
end;



{ * Sys_GetPpid :                                               *
  *                                                             *
  * Retorno : Pid del proceso padre de la tarea actual          *
  *                                                             *
  * Llamada al sistema que devuelve el pid de padre del proceso *
  *                                                             *
  ***************************************************************
}
function sys_getppid:dword;cdecl;[public , alias :'SYS_GETPPID'];
begin
exit(Tarea_actual^.padre_pid);
end;


{ * Sys_Detener :                                                        *
  *                                                                      *
  * Pid : Numero Pid de la tarea                                         *
  *                                                                      *
  * Llamada al sistema que Detiene la ejecucion de un proceso , enviando *
  * la se¤al SIG_DETENER , por ahora el proceso no puede ser despertado  *
  *                                                                      *
  ************************************************************************
}
function sys_detener(Pid:dword):dword;cdecl;[public , alias :'SYS_DETENER'];
var tmp,tarea:p_tarea_struc;
begin

tmp := Hash_Get(Pid);

If tmp = nil then
 begin
  set_errno := -ESRCH ;
  exit(-1);
 end;

If tmp^.Padre_Pid=Tarea_Actual^.pid then
 Signal_Send(tmp,SIG_DETENER)
 else
  begin
   set_errno := -ECHILD ;
   exit(-1);
  end;

clear_errno ;
exit(0);
end;


{ * Sys_Fork :                                                        *
  *                                                                   *
  * Unas de las mas importantes llamadas al sistema , puesto que crea *
  * un proceso a partir del proceso padre , es una copia exacta del   *
  * padre                                                             *
  *                                                                   *
  * Versiones :                                                       *
  * 4 / 01 / 2005 : Primera Version                                   *
  *                                                                   *
  *********************************************************************
}
function sys_fork:dword;cdecl;[public , alias :'SYS_FORK'];
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
Hijo^.reg.eax := 0 ; { Resultado de operacion para el hijo }

add_task (Hijo);
exit(hijo^.pid);
end;


{ * Sys_WaitPid :                                                          *
  *                                                                        *
  * status : Causa de la terminacion                                       *
  * Retorno : Pid del proceso Hijo                                         *
  *                                                                        *
  * Llamada al sistema que duerme a un padre que espera por la terminacion *
  * de un hijo y devuelve la causa de terminacion                          *
  *                                                                        *
  **************************************************************************
}
function sys_waitpid(var status:dword):dword;cdecl;[public , alias :'SYS_WAITPID'];
var pid:dword;
    err:word;
begin
esperar_hijo(Tarea_Actual,Pid,err);
status:=err;
exit(pid);
end;


{ * Sys_Exit :                                                        *
  *                                                                   *
  * status : Causa de la muerte                                       *
  *                                                                   *
  * Llamada al sistema que envia la se¤al de muerte al proceso actual *
  *                                                                   *
  *********************************************************************
}
procedure sys_exit(status:word);cdecl;[public , alias :'SYS_EXIT'];
begin
cerrar;
Tarea_actual^.terminacion:= status;
Signal_Send(Tarea_Actual,Sig_Morir);
Signaling;
end;


{ * Sys_Kill :                                                          *
  *                                                                     *
  * Pid : Numero de proceso                                             *
  * Signal : Numero de se¤al a enviar                                   *
  *                                                                     *
  * Esta es la implementacion de la llamada al sistema Kill() , que     *
  * envia la se¤al indicada en Signal , al proceso indicado en Pid ,    *
  * siempre que el pid de la tarea solicitante sea igual al padre_pid   *
  * de Pid . Las Sig_Alarma  y las se¤ales del kernel no pueden ser en  *
  * viadas por el usuario                                               *
  *                                                                     *
  ***********************************************************************
}
function sys_kill(Pid:dword;Signal:word):dword;cdecl;[public , alias :'SYS_KILL'];
var tmp:p_tarea_struc;
begin
If Signal > 31 then exit(-1);

If  (Signal = Sig_Detener) or (Signal = Sig_Alarm) or (Signal = Sig_Hijo) then
 begin
  set_errno := -EPERM ;
  exit(-1);
 end;

tmp := Hash_Get(Pid) ;

If tmp  = nil then
 begin
  set_errno := -ESRCH ;
  exit(-1);
 end;

If tmp^.padre_pid <> Tarea_Actual^.pid then
 begin
  set_Errno := -ECHILD ;
  exit(-1);
 end;

Signal_Send(tmp,Signal);
exit(0);
end;



{ * Sys_Signal :                                                        *
  *                                                                     *
  * Handler : Puntero al procedimiento                                  *
  * Signal  : Numero de se¤al                                           *
  *                                                                     *
  * Esta es la implementacion de la llamada al sistema Signal() , que   *
  * coloca el puntero de tratamiento de una se¤al en el array Signals[] *
  *                                                                     *
  ***********************************************************************
}
function sys_signal(Handler:pointer;Signal:word):dword;cdecl;[public , alias :'SYS_SIGNAL'];
begin
Tarea_Actual^.signals[Signal] := Handler;
exit(0);
end;



{ * Sys_ReadErrno :                                                     *
  *                                                                     *
  * Retorno : Numero de error                                           *
  *                                                                     *
  * Funcion que devuelve el codigo de error generado por la ultima      *
  * llamada al sistema , luego el campo errno es limpiado               *
  *                                                                     *
  ***********************************************************************
}
function sys_readerrno : dword ; cdecl ; [public , alias : 'SYS_READERRNO'];
var errno : dword ;
begin
errno := set_errno ;
clear_errno ;
exit(errno);
end;


end.
