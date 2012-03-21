Unit Excepciones;

{ * Excepciones :                                                       *
  *                                                                     *
  * Esta unidad se encarga de captar las interrupciones generadas por   *
  * excepciones y de acuerdo a la excepcion destruye la tarea y muestra *
  * un volcado de la tarea en pantalla                                  *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 01 / 04 / 2005 : Las excepciones son encerradas en se¤ales procesa  *
  * bles por los procesos de usuario o el kernel mismo                  *
  *                                                                     *
  * 08 / 08 / 2004 : Version Inicial                                    *
  *                                                                     *
  ***********************************************************************
}


interface


{$I ../include/toro/procesos.inc}
{$I ../include/head/asm.h}
{$I ../include/head/gdt.h}
{$I ../include/head/mm.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/idt.h}
{$I ../include/head/procesos.h}
{$I ../include/head/printk_.h}
{$I ../include/toro/signal.inc}
{$I ../include/head/signal.h}

implementation


procedure excep_Ignore;interrupt;
begin
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
hlt {Bloque el bus }
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


{ * Excep_Init :                                                        *
  *                                                                     *
  * Proceso que inicializa los manejadores de excepciones               *
  *                                                                     *
  ***********************************************************************
}
procedure excep_init;[Public , alias : 'EXCEP_INIT'];
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




end.
