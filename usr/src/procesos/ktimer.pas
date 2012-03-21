Unit Ktimer ;

{ * Ktimer :                                                           *
  *                                                                    *
  * Aqui se encuentran implementados los timers del nucleo que ordenan *
  * la ejecuion de funcionesn en un cierto lapso de tiempo             *
  *                                                                    *                                                               *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  *                                                                    *
  * Versiones :                                                        *
  *                                                                    *
  * 04 / 01 / 2006 : Primera version                                   *
  *                                                                    *
  **********************************************************************
}




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
{$I ../include/head/itimer.h}


{ Simbolos utilizados para la cola ligada de timers }

{$DEFINE Use_Tail }
{$DEFINE nodo_struct := p_timer_kernel }
{$DEFINE next_nodo := next_timer }
{$DEFINE prev_nodo := prev_timer }
{$DEFINE nodo_tail := tq_ktimers }

{ Macros creados solo para comodidad }
{$DEFINE Push_Timer := Push_Node }
{$DEFINE Pop_Timer := Pop_Node }

const tq_ktimers: p_timer_kernel = nil;



implementation

{$I ../include/head/list.h}

{ * Add_timer :                                                         *
  *                                                                     *
  * timer : puntero a un timer de kernel                                *
  *                                                                     *
  * Coloca un timer de kernel en la cola de timers                      *
  *                                                                     *
  ***********************************************************************
}
procedure add_timer ( timer : p_timer_kernel ) ; [public , alias : 'ADD_TIMER'];
begin
cerrar;
timer^.timer.time_action := contador + timer^.timer.interval ;
push_timer(timer);
abrir;
end;



{ * Del_timer :                                                         *
  *                                                                     *
  * timer : puntero a un timer de kernel                                *
  *                                                                     *
  * Quita un timer de la cola de timers                                 *
  *                                                                     *
  ***********************************************************************
}
procedure del_timer ( timer : p_timer_kernel ) ; [public , alias : 'DEL_TIMER'];
begin
cerrar;
pop_timer (timer);
abrir;
end;


{ * Do_ktimer :                                                         *
  *                                                                     *
  * Chequea lo timers que han vencido y los ejecuta y luego los elimina *
  * de la cola                                                          *
  * Es llamada en cada irq de relog                                     *
  *                                                                     *
  ***********************************************************************
}
procedure do_ktimer ; [public , alias : 'DO_KTIMER'];
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

end.
