Unit Mm;

{ * MM:
  * Esta unidad se encarga de la administracion de memoria a traves de un *
  * modelo paginado , la asignacion de memoria al kernel se realiza a tra *
  * ves del kmalloc  , que limita el tama¤o a 4096 bytes , y la asignacio *
  * n para el usuario se realiza a traves de vmm_alloc                    *
  *                                                                       *
  *                                                                       *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>            *
  * All Rights Reserved                                                   *
  *                                                                       *
  * Versiones :                                                           *
  * 10 / 06 / 2004 : Se aplica el model paginado de memoria               *                                                              *
  *                                                                       *
  * 29 / 10 / 2003 : Primera Version                                      *
  *************************************************************************
 }



INTERFACE

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/paging.h}



var mm_totalmem , mm_memfree:dword;


IMPLEMENTATION



{ * Procedimiento que calcula la cantidad de memoria fisica * }

procedure mm_total_fisica ; [public , alias  : 'MM_TOTAL_FISICA'];
begin
asm
mov esi , MEM_INI
@mem:
 add esi , $100000
 mov dword [esi] , $1234567
 cmp dword [esi] , $1234567
 je @mem
 mov MM_TOTALMEM , esi
end;
end;

{ * Proceso que inicializa el modulo de memoria * }

procedure mm_init;[Public , alias : 'MM_INIT'];
begin
mm_total_fisica;
mm_memfree := mm_totalmem - mem_ini;
printk('/nMemoria fisica total ... /V%d\n',[MM_TotalMem],[]);
printk('/nMemoria fisica libre ... /V%d\n',[MM_MEMFREE],[]);
Paging_Init;
end;



END.
