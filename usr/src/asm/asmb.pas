Unit asmb;

{ * Asmb :                                                             *
  *                                                                    *
  * Esta unidad contiene rutinas utilizadas por casi todos los modulos *
  * del sistema , en su mayoria escritas en assembler  para que sean   *
  * mas rapidas                                                        *
  *                                                                    *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  * Versiones :                                                        *
  * 29 / 09 / 2003 : Version Inicial                                   *
  *                                                                    *
  *                                                                    *
  **********************************************************************
}

interface


{$I ../Include/Head/printk_.h}


const Kernel_Data_Sel =$10;
      User_Data_Sel   =$18 ;


implementation


{$I ../Include/Head/ioport.h}

{* Memcopy :                                                                 *
 *                                                                           *
 * Procedimiento para mover desde el puntero origen hasta el puntero destino *
 * ,la cantidad de bytes indicada en tamaño.                                 *
 *                                                                           *
 *****************************************************************************
 }

procedure Memcopy(origen , destino :pointer;tamano:dword);assembler;[public , alias : 'MEMCOPY' ];
asm
mov esi , origen
mov edi , destino
mov ecx , tamano
rep movsb
end;


procedure debug(Valor:dword);[PUBLIC , ALIAS :'DEBUG'];
begin
asm
xor edx , edx
mov edx , valor
@bucle:
 jmp @bucle
end;
end;



{ * Bit_Test :                                                          *
  *                                                                     *
  * Procedimiento que devuelve true si el bit dado en pos esta activo   *
  *                                                                     *
  ***********************************************************************
}
function Bit_Test(Val:Pointer;pos:dword):boolean;[public , alias :'BIT_TEST'];
var s:byte;
begin
asm
xor eax , eax
xor ebx , ebx
mov ebx , pos
mov esi , Val
bt  dword [esi] , ebx
jc  @si
@no:
 mov s , 0
 jmp @salir
@si:
  mov s , 1
@salir:
end;
exit(boolean(s));
end;


{ * Bit_Reset                                                           *
  *                                                                     *
  * Procedimiento que baja el bit dado en pos en el buffer cadena       *
  *                                                                     *
  ***********************************************************************
}
procedure Bit_Reset(Cadena:pointer;pos:dword);assembler;[Public , Alias :'BIT_RESET'];
asm
mov ebx , dword [pos]
mov esi , Cadena
btr dword [esi] , ebx
end;



{ * Bit_Set                                                             *
  *                                                                     *
  * Procedimiento que activa el bit dado en pos                         *
  *                                                                     *
  ***********************************************************************
}
procedure Bit_Set(ptr_dw:pointer;pos:dword);assembler;[Public , Alias :'BIT_SET'];
asm
mov esi , ptr_dw
xor edx , edx
mov edx , dword [pos]
bts dword [esi] , edx
end;


procedure Panic(error:string);[public, alias :'PANIC'];
begin
printk(@error,[],[]);
debug(-1);
end;



{ * Mapa_Get :                                                          *
  *                                                                     *
  * Mapa : Puntero a un mapa de bits                                    *
  * Limite : Tama¤o del mapa                                            *
  * Retorno : Numero de bit libre                                       *
  *                                                                     *
  * Funcion que busca destro de un mapa de bits , uno en estado 0 y     *
  * devuelve su posicion                                                *
  *                                                                     *
  ***********************************************************************
}
function Mapa_Get(Mapa:pointer;Limite:dword):word;[public , alias :'MAPA_GET'];
var ret:word;
begin
dec(Limite);
asm
mov esi , Mapa
mov ecx , limite
xor eax ,  eax
@bucle:
  bt dword[esi] , ax
  jc @si
  inc ax
  loop @bucle
@si:
   mov ret , ax
end;
exit (ret);
end;



{ * Limpiar_Array :                                                     *
  *                                                                     *
  * P_array : Puntero a un array                                        *
  * fin : tama¤o del array                                              *
  *                                                                     *
  * Procedimiento utilizado para llenar de caracteres nulos un array    *
  *                                                                     *
  ***********************************************************************
}
procedure Limpiar_Array(p_array:pointer;fin:word);[public , alias :'LIMPIAR_ARRAY'];
var tmp:word;
    cl:^char;
begin
cl:=p_array;
for tmp:= 0 to Fin do
 begin
 cl^:=#0;
 cl+=1;
end;
end;


{ * Reset_Computer :                                                    *
  *                                                                     *
  * Simple proc. que resetea la maquina                                 *
  *                                                                     *
  ***********************************************************************
}
procedure Reboot;assembler;[public , alias :'REBOOT'];
asm
   cli

   @wait:
      in    al , $64
      test  al , 2
   jnz @wait

   mov   edi, $472
   mov   word [edi], $1234
   mov   al , $FC
   out   $64, al

   @die:
      hlt
      jmp @die
end;


procedure Bcd_To_Bin(var val:dword) ;inline;
begin
val := (val and 15) + ((val shr 4) * 10 );
end;


{ * get_datetime :   devuelve la hora actual del sistema utlizando el form *
  *                  ato horario de unix                                   *
  *                                                                        *
  **************************************************************************
}
function get_datetime  : dword ;[public , alias :'GET_DATETIME'];
var sec , min , hour  , day , mon , year  : dword ;
begin

repeat
      sec  := Cmos_Read(0);
      min  := Cmos_Read(2);
      hour := Cmos_Read(4);
      day  := Cmos_Read(7);
      mon  := Cmos_Read(8);
      year := Cmos_Read(9);

until (sec = Cmos_Read(0));

Bcd_To_Bin(sec);
Bcd_To_Bin(min);
Bcd_To_Bin(hour);
Bcd_To_Bin(day);
Bcd_To_Bin(mon);
Bcd_To_Bin(year);

mon -= 2 ;

If (0 >= mon) then
 begin
 mon += 12 ;
 year -= 1;
end;


get_datetime :=   (( ((year div 4 - year div 100 + year div 400 + 367 * mon div 12 + day)  +(year * 365)  -(719499))
   *24 +hour )
   *60 +min  )
   *60 +sec;
end;



end.
