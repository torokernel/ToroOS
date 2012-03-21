Unit Irq;

{ * Irq :                                                               *
  *                                                                     *
  * Unidad que se encarga de manejar al 8259  , para habilitar o        *
  * inhibir las IRQ de Hard . Tambien se encarga de la captacion de las *
  * Irq por parte de los procesos  y de manejar la tabla de asignacion  *
  * de Irq                                                              *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 04 / 01 / 2006 : Es depurado y optimizado la recepcion de irqs      *
  *                                                                     *
  * 19 / 01 / 2005 : Se crean los procedimientos para la manipulacin de *
  * las irq  por parte del usuario , son creados dos procedimientos .   *
  *                                                                     *
  * ?? / ?? / ???? : Primera Version                                    *
  *                                                                     *
  ***********************************************************************

}



interface


{$I ../include/head/asm.h}
{$I ../include/toro/irq.inc}
{$I ../include/toro/procesos.inc}
{$I ../include/head/procesos.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/idt.h}
{$I ../include/head/printk_.h}
{$I ../include/head/itimer.h}

{Cola de tareas interrumpidas por e/s}
const Tq_WaitIrq : p_tarea_struc = nil ;

var Irq_Wait : array [ 0..15] of p_tarea_struc ;
    irq_flags : word ;

implementation

{$I ../include/head/ioport.h}

procedure habilitar_irq(Irq:byte);[public , alias :'HABILITAR_IRQ'];
var puerto:word;
    irqs,buf:byte;
    l:byte;
begin
puerto := $A1;

If (IRQ < 7) then puerto:=$21;

irqs:=leer_byte(puerto);
buf:=IRQS and (not PIC_MASK[irq]);
enviar_byte(buf,puerto);
end;



procedure dhabilitar_irq(Irq:byte);[public , alias :'DHABILITAR_IRQ'];
var puerto:word;
    irqs,buf:byte;
begin
puerto:=$A1;
if IRQ<7 then puerto :=$21;

irqs:=leer_byte(puerto);
buf:=irqs or PIC_MASK[IRQ];  {modifico los bit con OR}
enviar_byte(buf,puerto);
end;

procedure fdi;[public , alias :'FDI'];
begin
enviar_byte($20,status_port[0]); {Si es el 2ø controlador se deve enviar al primero}
enviar_byte($20,status_port[1]); {tambien}
end;



procedure habilitar_todasirq;[public , alias :'HABILITAR_TODASIRQ'];
begin
enviar_byte(0,mask_port[0]);
enviar_byte(0,mask_port[1]);
end;



procedure dhabilitar_todasIrq;[public , alias :'DHABILITAR_TODASIRQ'];
begin
enviar_byte($ff,mask_port[0]);
enviar_byte($ff,mask_port[1]);
end;


function bin_to_dec(bin:byte):byte;inline;
var cont:byte;
begin
cont := 0 ;
repeat
If Bit_test(@bin,cont) then exit(cont);
cont += 1;
until (cont = 8) ;
exit(-1);
end;


Procedure irq_master;interrupt;[public , alias :'IRQ_MASTER'];
var irq:byte;
begin
asm
mov dx , $20                            {Como la interrupcion es producida }
mov al , $b                             {por el 1ø 8259 , quiero saber cual}
out dx , al                             {es                                }
nop
nop
nop
xor ax , ax
in  al , dx                             {Al= va a tener el numero de IRQ   }
mov irq , al
xor ax , ax

mov ax , $20                            { aqui se envia el eoi }
out dx , al
end;


irq := bin_to_dec (irq) ;

If Irq = -1 then exit;

Bit_Reset (@irq_flags,irq);
Proceso_Reanudar(Irq_Wait[irq] , Tq_WaitIrq);
abrir;

end;



procedure irq_esclavo;interrupt;[public,alias:'Irq_Esclavo'];
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


{ * las irq son desviadas para q no generen problemas * }

procedure desviar_irqs ; assembler ; inline;
asm
    mov   al , 00010001b
    out   20h, al
    nop
    nop
    nop
    out  0A0h, al
    nop
    nop
    nop
    mov   al , 20h
    out   21h, al
    nop
    nop
    nop
    mov   al , 28h
    out  0A1h, al
    nop
    nop
    nop
    mov   al , 00000100b
    out   21h, al
    nop
    nop
    nop
    mov   al , 2
    out  0A1h, al
    nop
    nop
    nop
    mov   al , 1
    out   21h, al
    nop
    nop
    nop
    out  0A1h, al
    nop
    nop
    nop

    mov   al , 0FFh
    out   21h, al
    mov   al , 0FFh
    out  0A1h, al
end;



{ * Wait_Long_Irq :                                                     *
  *                                                                     *
  * Irq : Numero de Irq                                                 *
  *                                                                     *
  * Procedimiento utilizado para esperar una irq por lo general de      *
  * lenta o mejor dicho aquellas que se producen entre lasgos inter     *
  * valos de tiempo como la de la disketera el disco duro               *
  * Duerme al proceso solicitante!!                                     *
  *                                                                     *
  ***********************************************************************
}
procedure wait_long_irq(Irq:byte);[public , alias : 'WAIT_LONG_IRQ'];
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




{ * Wait_Short_Irq :                                                    *
  *                                                                     *
  * Irq : Numero de Irq                                                 *
  * Handler : Puntero al tratamiento                                    *
  *                                                                     *
  * Este procedimiento se utiliza para captar irqs que se generan       *
  * continuamente como son las del teclado  o los puertos seriales      *
  * que deven recibir tratamiento inmediatamente                        *
  * No duerme al proceso solicitante!!!                                 *
  *                                                                     *
  ***********************************************************************
}
procedure wait_short_irq(Irq:byte;Handler:pointer);[public , alias : 'WAIT_SHORT_IRQ'];
begin
If Bit_Test(@Irq_Flags,Irq) then exit
 else Bit_Set(@Irq_Flags,Irq);

set_int_gate(Irq + 32 , Handler);
Habilitar_Irq(irq);

end;


{ * Irq_Init :                                                          *
  *                                                                     *
  * Inicializacion de los handler de irq                                *
  *                                                                     *
  ***********************************************************************
}
procedure irq_init ;[public , alias : 'IRQ_INIT'];
var m: dword;
begin
{son desviadas las irq}
desviar_irqs;

irq_flags := 0 ;
for m := 0 to 15 do Irq_Wait[m] := nil ;

{Son capturadas todas las irq}
for m:= 33 to 39 do set_int_gate(m,@Irq_Master);
for m:= 40 to 47 do set_int_gate(m,@Irq_Esclavo);
end;




end.
