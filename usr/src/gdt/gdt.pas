Unit Gdt;

{
 * Gdt:                        						  *
 *                                                                        *
 * Esta libreria se encarga de suministrar Descriptores libre en la Gdt   *
 * el sistema soporta hasta 8192 descriptores . La gdt se encuentra sobre *
 * la posicion $2000 de la memoria que no es utilizada                    *
 *                                                                        *
 * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>             *
 * All Rights Reserved                                                    *
 *                                                                        *
 * Versiones :                                                            *
 * 04 / 01 / 2004 : Es suplantada la cola ligada por un mapa de bits      *
 * ?? / ?? / ???? : Version Inicial                                       *
 *                                                                        *
 **************************************************************************

}

interface


{$I ../include/head/asm.h}
{$I ../include/head/mm.h}
{$I ../include/toro/procesos.inc}
{$I ../include/head/procesos.h}
{$I ../include/head/scheduler.h}


var gdtreg:struc_gdtr;
    gdt_ar:p_struc_gdt;
    gdt_huecos_libres:dword;
    gdt_bitmap:array [0 .. 1023] of byte;
    gdt_wait : wait_queue ;

implementation


{
 * Gdt_Dame :                                                               *
 *                                                                          *
 * Retorno : Numero de Descriptor en la GDT                                 *
 *                                                                          *
 * Devuelve un valor word que contiene un selector libre si devuelve        *
 * 0  significa que no hay un hueco libre en la GDT . El valor devuelto     *
 * devera ser restado a 1 y multiplicado por 8  + GDT_NUEVA para saber su   *
 * ubicacion dentro de la GDT.                                              *
 *                                                                          *
 ****************************************************************************

}
function gdt_dame:word;[Public , Alias :'GDT_DAME'];
var n:word;
begin

n:=Mapa_Get(@gdt_bitmap,Max_Sel);

If n = Max_Sel then exit(0)
 else
  begin
   Bit_Reset(@gdt_bitmap,n);
   Gdt_Huecos_Libres-=1;
   exit(n+1);
  end;
end;




{ * Gdt_Quitar :                                                        *
  *                                                                     *
  * Selector : Numero de descriptor                                     *
  *                                                                     *
  * Este proc. libera un descriptor desmarcando su bit en el bitmap     *
  *                                                                     *
  ***********************************************************************
}
procedure gdt_quitar(Selector:word);[Public , Alias :'GDT_QUITAR'];
begin
bit_Set(@gdt_bitmap,Selector-1);
Gdt_huecos_Libres +=1;
end;



{ * Init_Tss:                                                           *
  *                                                                     *
  * Tss : Puntero a una estructura TSS                                  *
  *                                                                     *
  * Esta funcion limpia el registro tss para que no se provoquen        *
  * errores cuando se carga a la GDT                                    *
  *								        *	 *
  ***********************************************************************
}
procedure init_tss(tss:p_tss_struc);[public , alias :'INIT_TSS'];
var tmp:dword;
begin
tmp:=sizeof(tss_struc);
asm
mov ecx , tmp
mov edi , tss
xor eax , eax
rep stosb
end;
end;


{ * Gdt_Set_Tss :                                                           *
  *                                                                         *
  * Tss : Puntero a una estructura TASK STATE SEGMENT                       *
  * Devuelve: Numero dentro de la Gdt                                       *
  *                                                                         *
  * Esta funcion busca un lugar libre en la GDT y crea un Descriptor de TSS *
  * , devuelve la posicion dentro de la GDT o 0  si no hay espacio          *
  *                                                                         *d
 ***************************************************************************
}
function gdt_set_tss(tss:pointer):word;[PUBLIC , ALIAS :'GDT_SET_TSS'];
var s,bajo:word;
         j:dword;
var altoA,altoB:byte;
begin

{ Se pide el descriptor }
s := Gdt_Dame;

{ No hay espacio }
If s = 0 then exit(0);

{ Devuelvo el numero de descriptor }
Gdt_Set_Tss := s;
Init_Tss(Tss);

asm
mov eax , tss
mov bajo , ax
shr eax  , 16
mov ALTOB , al
mov ALTOA , ah
end;

{ Son establecidos los valores del tss }
GDT_AR^[s-1].limite_0_15:=104;
GDT_AR^[s-1].base_0_15:=bajo;
GDT_AR^[s-1].base_16_23:=ALTOB;
GDT_AR^[s-1].base_24_31:=ALTOA;
GDT_AR^[s-1].tipo:=TSS_SIST_LIBRE;
GDT_AR^[s-1].limite_16_23:=$40;

end;



{ * Gdt_Init :                                                          *
  *                                                                     *
  * Aqui es inicializada la Gdt cuando se inicia el kernel              *
  *                                                                     *
  ***********************************************************************
}
procedure gdt_init;[public , alias :'GDT_INIT'];
var tmp:pointer;
    ret:dword;
begin

tmp:=@gdt_bitmap;

{todos los bitmaps estan libres}
asm
mov  ecx , 256
mov  eax , $FFFFFFFF
mov  edi , tmp
rep  stosd
end;

gdtreg.limite:= 8192 * 8 - 1;         {Cargo el reg GDTR con el tama¤o}
gdtreg.base_lin:= pointer(GDT_NUEVA);              {Cargo el reg GDTR con la nueva base}

{descriptores del sistema}
Bit_Reset(@gdt_bitmap,0);
Bit_Reset(@gdt_bitmap,1);
Bit_Reset(@gdt_bitmap,2);
Bit_Reset(@gdt_bitmap,3);
Bit_Reset(@gdt_bitmap,4);

Gdt_Ar := pointer(gdt_nueva);

{codigo y datos del kernel}
gdt_ar^[1].limite_0_15 := $ffff;
gdt_ar^[1].base_0_15 := 0 ;
gdt_ar^[1].base_16_23 := 0 ;
gdt_ar^[1].tipo := sistema_codigo ;
gdt_ar^[1].limite_16_23 := $cf ;
gdt_ar^[1].base_24_31 := 0 ;

gdt_ar^[2].limite_0_15 := $ffff;
gdt_ar^[2].base_0_15 := 0 ;
gdt_ar^[2].base_16_23 := 0 ;
gdt_ar^[2].tipo := sistema_datos ;
gdt_ar^[2].limite_16_23 := $cf ;
gdt_ar^[2].base_24_31 := 0 ;

{datos y codigo del usuario}
gdt_ar^[3].limite_0_15 := $ffff;
gdt_ar^[3].base_0_15 := 0 ;
gdt_ar^[3].base_16_23 := 0 ;
gdt_ar^[3].tipo := usuario_datos ;
gdt_ar^[3].limite_16_23 := $cf ;
gdt_ar^[3].base_24_31 := 0 ;

gdt_ar^[4].limite_0_15 := $ffff;
gdt_ar^[4].base_0_15 := 0 ;
gdt_ar^[4].base_16_23 := 0 ;
gdt_ar^[4].tipo := usuario_codigo ;
gdt_ar^[4].limite_16_23 := $cf ;
gdt_ar^[4].base_24_31 := 0 ;

asm
lgdt [gdtreg]
end;

Gdt_Huecos_Libres:=MAX_SEL - 5;

gdt_wait.lock_wait := nil ;
end;




end.
