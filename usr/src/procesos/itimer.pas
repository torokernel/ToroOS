Unit Itimer ;

{ * Itimer :                                                           *
  *                                                                    *
  * Esta unidad se encarga de los timers  y el despertador de usuario  *
  *                                                                    *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  * Versiones   :                                                      *
  *                                                                    *
  * 03 / 04 / 05 : Son redefinidas las syscalls                        *
  *                                                                    *
  * 22 / 04 / 04 : Creacion de las llamadas al sistema                 *
  *                                                                    *
  * 21 / 12 / 03 : Creo Alarmas que no duermen al proc                 *
  *                                                                    *
  * 05 / 12 /  03 : Primera version                                    *
  *                                                                    *
  **********************************************************************
}

{DEFINE DEBUG}

interface


{$I ../include/toro/procesos.inc}
{$I ../include/toro/signal.inc}
{$I ../include/head/gdt.h}
{$I ../include/head/mm.h}
{$I ../include/head/asm.h}
{$I ../include/head/procesos.h  }
{$I ../include/head/relog.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/signal.h}
{$I ../include/head/printk_.h}


{ Simbolos utilizados para la cola ligada de timers }

{$DEFINE Use_Tail }
{$DEFINE nodo_struct := p_timer_user }
{$DEFINE next_nodo := next_timer }
{$DEFINE prev_nodo := prev_timer }
{$DEFINE nodo_tail := Tq_Alarmas }

{ Macros creados solo para comodidad }
{$DEFINE Push_Timer := Push_Node }
{$DEFINE Pop_Timer := Pop_Node }

const tq_Alarmas: p_timer_user = nil;
      tq_Dormidas : p_tarea_Struc = nil;

var Contador : dword ;


implementation


{$I ../include/head/list.h}


{ * Sys_Setitimer :                                                 *
  *                                                                 *
  * entry : Puntero donde se devera ir luego  de la alarm           *
  * miliseg : Numero de mileseg de la alarma                        *
  *                                                                 *
  * implementacion de la llamada al sistema para colocar una alarma *
  * en el proceso actual , si hubiese otra alarma esta es quitada   *
  *                                                                 *
  *******************************************************************

}
procedure sys_setitimer(miliseg:dword);cdecl;[public , alias :'SYS_SETITIMER'];
begin


 if (tarea_actual^.timer.estado) then
  begin
   tarea_actual^.timer.timer.interval := miliseg;
   tarea_actual^.timer.timer.time_action := contador + miliseg;
  end
   else
    begin
    tarea_actual^.timer.estado := true ;
    tarea_actual^.timer.timer.interval := miliseg;
    tarea_actual^.timer.timer.time_action := contador + miliseg;
    Push_Timer (@tarea_actual^.timer);
    end;

  {$IFDEF DEBUG}
  printk('/nAlarma --> Pid : %d en : %d miliseg\n',[tarea_actual^.pid , miliseg],[]);
  {$ENDIF}

end;



{ * Sys_getitimer :                                                       *
  *                                                                       *
  * Esta funcion devuelve de cuanto se ha colocado el intervalo del timer *
  *                                                                       *
  *************************************************************************
}

function sys_getitimer:dword;cdecl;[public , alias : 'SYS_GETITIMER'];
begin
exit(Tarea_Actual^.timer.timer.interval);
end;



{ * Sys_Sleep :
  *                                                              *
  * miliseg : Numero de milisegundos que el proceso permanecera  *
  * dormido                                                      *
  *                                                              *
  * Llamada el sistema que duerme un proceso , dado en miliseg   *
  * si tuviera alguna alarma esta es eliminada                   *
  *                                                              *
 *****************************************************************
}
function sys_sleep(miliseg:dword):dword;cdecl;[public , alias :'SYS_SLEEP'];
var ret:word;
    tarea:p_tarea_struc;
begin


{ Los timers puestos son eliminados }
If (Tarea_Actual^.timer.estado) then
 begin
 Pop_Timer(@Tarea_Actual^.timer);
 Tarea_Actual^.timer.estado := false;
end;

{ Calculo segun el relog del sistema }
tarea_Actual^.Despertador.interval := miliseg;
tarea_Actual^.Despertador.time_action := contador + miliseg;

{ la tarea se duerme }
Proceso_Interrumpir (Tarea_Actual , tq_dormidas);
end;




{ * Timer_Inc :                                                         *
  *                                                                     *
  * Este procedimiento es llamado en cada irq de relog y mantiene el    *
  * contador del sistema y los timers                                   *
  *                                                                     *
  ***********************************************************************
}
procedure timer_Inc;[public , alias :'TIMER_INC'];
var tarea_d,Tarea_p : p_tarea_struc;
    timer_tmp  , timer_t : p_timer_user;

begin

{ Incremento el contador del Sistema }
contador += 1;

tarea_d := tq_dormidas;

 If (tq_dormidas <> nil) then
  begin

    repeat

     { Esta Tarea cumplio su tiempo ?  , entonces la despierto }
      if (tarea_d^.Despertador.time_action <= contador) then
       begin
        Tarea_p := Tarea_d^.prev_tarea;
        Proceso_Reanudar (tarea_d , tq_dormidas);
        Tarea_d := Tarea_p;
       end;

    { Se continua la busqueda }
    Tarea_d := Tarea_d^.next_tarea;
    until (Tarea_D=tq_dormidas) or (tq_dormidas=nil) ;

  end;

{ Ahora busco tareas con alarmas }
if (tq_alarmas = nil) then exit;

timer_tmp := tq_alarmas;

  repeat

  { el timer vencio!!! }
  if (Timer_tmp^.timer.time_action <= contador) then
   begin
    timer_tmp^.estado := false;
    timer_t := timer_tmp^.prev_timer ;

    { se quita el timer y se envia la se¤al }
    Pop_Timer(timer_tmp);
    Signal_Send(Timer_tmp^.tarea,SIG_ALARM);

    timer_tmp := timer_t ;
    end;

  { Continuo con la ejecucion }
  timer_tmp := timer_tmp^.next_timer;

  until (Timer_tmp = tq_alarmas);

end;


end.
