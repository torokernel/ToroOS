Unit Cpu;

{ * Cpu:                                                                    *
  *                                                                         *
  * Esta Unidad chequea el tipo de procesador , solo detecta las marcas AMD *
  * e Intel  , y tambien detect ala velocidad del micro , y llena la        *
  * estructura struc_cpu , con la informacion del coprocesador,             *
  * registros MMX , SSE y SSE2                                              *
  *                                                                         *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>              *
  * All Rights Reserved                                                     *
  *                                                                         *
  * Versiones :                                                             *
  * 1 / 11 / 2003 : Primera Version .                                       *
  *                                                                         *
  ***************************************************************************
 }

INTERFACE


{$I ../Include/Head/asm.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Toro/cpu.inc}

var  p_cpu : struc_cpu ;


implementation


{ * Cpu_Id :                                                            *
  *                                                                     *
  * Este proc. se encarga de identificar el procesador , solo indenti   *
  * fica procesadores Intel  y Amd                                      *
  *                                                                     *
  ***********************************************************************
}
procedure cpu_id;
var cpui:boolean;
    mc,types,model,family,features:dword;

begin
asm
 pushfd
 pop eax
 mov ecx , eax
 or eax  , 200000h
 push eax
 popfd
 pushfd
 pop eax
 xor eax , ecx
 je @no_es
 mov cpui , 1
 jmp @salir_test
@no_es:
 mov cpui ,  0
@salir_test:
end;


if (cpui) then
 begin
  asm
           xor eax , eax
           cpuid
           mov mc , ebx
           xor eax , eax
           inc eax
           cpuid
           mov   features, edx
           push  eax
           and   eax, 7000h
           shr   eax, 12
           mov   types, eax
           pop   eax
           push  eax
           and   eax, 0F00h
           shr   eax, 8
           mov   family, eax
           pop   eax
           push  eax
           and   eax, 0F0h
           shr   eax, 4
           mov   model, eax
end;

if mc=Intel_Id then p_cpu.marca := Intel;
if mc=Amd_Id  then p_cpu.marca := Amd;

p_cpu.family := family;
p_cpu.Model := model;
p_cpu.types := types;
end;
end;



{ * Cpu_Init :                                                          *
  *                                                                     *
  * Inicializa el modulo de CPu identificandolo                         *
  *                                                                     *
  ***********************************************************************
  }
procedure cpu_init;[public,alias :'CPU_INIT'];
begin
Cpu_Id;
printk('/nProcesador ... ',[],[]);

if p_cpu.marca = amd then printk('/Vamd\n',[],[])
else  printk('/Vintel\n',[],[]);
end;




end.
