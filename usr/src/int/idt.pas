Unit Idt;

{  * Idt:                                                               *
   *                                                                    *
   * Esta libreria ademas de inicilizar la IDT  , crea las tareas que   *
   * manejan cada interrupcion  , ademas crea procedimientos para colo  *
   * car TASK Y INT GATE en la IDT  . Todas las int. HARD son cubiertas *
   * ,excepto la IRQ 0 que es tratada por el Planificador  ,            *                   *
   *                                                                    *
   * Copyright (c) 2003-2005 Matias Vara <matiasevara@gmail.com>         *
   * All Rights Reserved                                                *
   *                                                                    *
   * Versiones :                                                        *
   * 12 / 12 / 2003 : Primera Version                                   *                      *
   *                                                                    *
   **********************************************************************
}


interface

{$I ../include/toro/procesos.inc}
{$I ../include/head/asm.h}
{$I ../include/head/irq.h}
{$I ../include/head/gdt.h}
{$I ../include/head/mm.h}
{$I ../include/head/printk_.h}
{$I ../include/head/scheduler.h}


procedure Excep_Init;external name 'EXCEP_INIT';


var Idtr:struc_Gdtr;

implementation



{ * Set_Int_Gate :                                                       *
  *                                                                      *
  * Int : Numero de interrupcion                                         *
  * Handler : Puntero al codigo de tratamiento                           *
  *                                                                      *
  * Procedimiento que coloca un descriptor en la IDT de Anillo 0 , uti   *
  * lizado por los drivers                                               *
  *                                                                      *
  ************************************************************************
}
procedure set_int_gate(int:byte;handler:pointer);[public , alias :'SET_INT_GATE'];
var k:p_intr_gate;
    bajo:word;
    alto:dword;
begin

k := pointer(IDT_POS + int * 8);
asm
mov eax , handler
mov bajo, ax
mov alto , eax
end;

k^.entrada_0_15 := bajo;
k^.selector := Kernel_Code_Sel ;
k^.tipo := Int_Gate_Sist;
k^.entrada_16_31 := alto shr 16;
end;



{ * Set_Int_Gate_User :                                                  *
  *                                                                      *
  * Int : Numero de interrupcion                                         *
  * Handler : Puntero al tratamiento de la int.                          *
  *                                                                      *
  * Procedimiento que es igual a set_int_gate la diferencia radica en    *
  * que son accesibles para el usuario . Es utuilizado para las syscall  *
  *                                                                      *
  ************************************************************************
}
procedure set_int_gate_user(int:byte;handler:pointer);[public , alias :'SET_INT_GATE_USER'];
var alto,bajo:word;
    k:p_intr_gate ;
begin
k:=pointer(IDT_POS + int * 8 );
asm
mov eax , handler
mov bajo , ax
shr eax , 16
mov alto , ax
end;
k^.entrada_0_15 := bajo;
k^.selector := Kernel_Code_Sel;
k^.tipo := Int_Gate_User;
k^.entrada_16_31 := alto;

end;



{ * Int_Ignore :                                                *
  *                                                             *
  * Procedimiento llamado para int. no validas                  *
  *                                                             *
  ***************************************************************
}

Procedure int_ignore;interrupt;
begin
LoadKernelData;
printk('/Virq/n : Irq igonarada\n',[]);
end;


{ * Idt_Init :                                                          *
  *                                                                     *
  * Proceso que inicializa todos los manejadores de interrupciones ,    *
  * las irq y las execpciones . Se limita a 55 interrupciones la Idt    *
  *                                                                     *
  ***********************************************************************
}

procedure idt_init ; [public , alias : 'IDT_INIT'];
var m:word;
begin

{Es inicializa la nueva Idt}
idtr.base_lin := pointer(Idt_Pos);
idtr.limite := MAX_INT * 8 ;

asm
lidt [idtr]
end;


{Excepto a del controlador secundario}
Habilitar_irq(2);

{Todas las irq son ignoradas por ahora}
for m:= 17 to 54 Do
begin
Set_Int_Gate(m,@int_ignore);
end;

{Se inicializan las excepciones}
Excep_init;
Irq_Init;
printk('/nIniciando Irqs ... /VOk\n',[]);
end;

end.
