Unit printk_;

{ * Printk :                                                            *
  *                                                                     *
  * Unidad encarga de la llamada printk() , que es utilizada por el     *
  * kernel para desplegar caracteres en pantalla  .                     *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 09 / 02 / 2005 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************

}

interface

{$I ../Include/Toro/printk.inc}
{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/asm.h}

{$DEFINE Use_Hash}

procedure print_dec_dword (nb : dword);
procedure print_pchar(c:pchar);
procedure print_dword(nb : dword);
procedure DumpTask(Pid:dword);
procedure Limpiar_P;

var x,y:byte;
    consola:^struc_consola;

implementation


{$I ../Include/Head/list.h}



{ * Set_Cursor :                                                        *
  *                                                                     *
  * pos : Posicion                                                      *
  *                                                                     *
  * Procedimiento que coloca el cursor en pos                           *
  *                                                                     *
  ***********************************************************************
}
procedure set_cursor(pos:word);assembler;[PUBLIC , ALIAS :'SET_CURSOR'];
asm
mov bx , pos
mov dx , $3D4
mov al , $0E
out dx , al
inc dx
mov al , bh
out dx , al
dec dx
mov al , $0f
out dx , al
inc dx
mov al , bl
out dx , al
end;


{ * Putc :                                                              *
  *                                                                     *
  * Car : Caracter                                                      *
  *                                                                     *
  * Procedimiento que coloca un caracter                                *
  *                                                                     *
  ***********************************************************************
}
procedure putc(Car:char);
begin
y := 24;
if x > 79 then x:=0;

consola := pointer(pointer(VIDEO_OFF)  + (80*2) * y + (x *2) );
consola^.form:= color;
consola^.car := Car;

x += 1;
Set_Cursor(y * 80 + x);
end;



{ * Flush :                                                             *
  *                                                                     *
  * Procedimiento que mueve la pantalla hacia arriba                    *
  *                                                                     *
  ***********************************************************************
}
procedure Flush;
var ult_linea : dword ;
begin
x := 0 ;
asm
mov esi , VIDEO_OFF + 160
mov edi , VIDEO_OFF
mov ecx , 24*80
rep movsw
end;
ult_linea := VIDEO_OFF + 160 * 24;
    asm
      mov eax , ult_linea
      mov edi , eax
      mov ax , 0720h
      mov cx , 80
      rep stosw
    end;
end;


procedure print_string (str : string ) ;inline;
var ret : dword ;
begin
for ret := 1 to byte(str[0]) do putc (str[ret]);
end;



{ * Printk :                                                            *
  *                                                                     *
  * Cadena : Puntero a cadena terminada en #0                           *
  * Args : Argumentos                                                   *
  * Argsk : Argumentos para el kernel                                   *
  *                                                                     *
  * Procedimiento utilizado por el kernel para desplegar caracteres en  *
  * la pantalla . Soporta argumentos para kernel                        *
  *                                                                     *
  ***********************************************************************
}
procedure printk(Cadena:pchar ; Args , Kargs: array of const);[public , alias : 'PRINTK'];
var arg,argk,cont,val : dword;
label volver;
begin

arg :=0;
argk := 0;

{Se analiza la cadena nula}
while (cadena^ <> #0) do
 begin

 {Se ha pedido un argumento}
 If (cadena^ = '%') and (High(Args) <> -1) and (High(Args) >= arg) then
  begin
  cadena += 1;

 If cadena^ = #0 then exit ;

 {Tipos de argumentos}

 Case cadena^ of
 'h': begin
      val := args[arg].vinteger ;
      print_dword(val);
      goto volver;
      end;
 'd': begin
      val := args[arg].vinteger;
      print_dec_dword(val);
      goto volver;
      end;
 's': begin
      print_pchar (args[arg].vpchar);
      goto volver
     end;
  'e':begin
      putc(Args[arg].vchar);
      goto volver;
     end;
  'p':begin
      print_string (args[arg].vstring^);
      goto volver;
      end;
  '%':begin
      putc('%');
      goto volver;
     end;
  else
    begin
    cadena += 1;
    continue;
    end;
 end;

 volver:
 cadena += 1;
 arg+=1;
 continue;
end;


 {Caractes de control de la terminal}
  If cadena^ = '\' then
   begin
   cadena += 1;

   If cadena^ = #0 then exit ;

   case cadena^ of
   'c':begin
       Limpiar_P;
       cadena += 1;
       end;
   'n':begin
       flush;
       cadena += 1;
       end;
   '\':begin
       putc('\');
       cadena += 1;
       end;
   'v':begin
       for cont := 1 to 9 do putc(' ');
       cadena += 1;
       end;
   'd':begin
       cadena += 1;
     end;
    else
     begin
     putc('\');
     putc(cadena^);
     end;
    end;
  continue;
end;



{Caracteres de color}
 If cadena^ = '/' then
  begin

  cadena += 1;
  If cadena^ = #0 then exit;

  case cadena^ of
  'n': color := 7 ;
  'a': color := 1;
  'v': color := 2;
  'V': color := 10;
  'z': color := $f;
  'c': color := 3;
  'r': color := 4;
  'R': color := 12 ;
  'N': color := $af
  else
   begin
    putc('/');
    putc(cadena^);
   end;
  end;

  cadena += 1;
  continue;
end;


{Caracteres de Argumentos al kernel}
If (cadena^ = '$') and (High(kArgs) <> -1) and (High(kArgs) >= argk) then
  begin
  cadena += 1;

  If cadena^ = #0 then exit;

  case cadena^ of
  'd':begin
      DumpTask(kargs[argk].vinteger);
      arg += 1
      end;
  else
    begin
    putc('$');
    putc(cadena^);
    end;
  end;

  cadena += 1;
  continue;
end;


putc(cadena^);
cadena += 1;
end;
end;




procedure print_dec_dword (nb : dword);

var
   i, compt : byte;
   dec_str  : string[10];

begin

   compt := 0;
   i     := 10;

   if (nb and $80000000) = $80000000 then
      begin
         asm
	    mov   eax, nb
	    not   eax
	    inc   eax
	    mov   nb , eax
	 end;
	 putc('-');
      end;

   if (nb = 0) then
      begin
         putc('0');
      end
   else
      begin

         while (nb <> 0) do
            begin
               dec_str[i]:=chr((nb mod 10) + $30);
               nb    := nb div 10;
               i     := i-1;
               compt := compt + 1;
            end;

         if (compt <> 10) then
            begin
               dec_str[0] := chr(compt);
               for i:=1 to compt do
	          begin
               dec_str[i] := dec_str[11-compt];
	             compt := compt - 1;
	          end;
            end
         else
            begin
               dec_str[0] := chr(10);
            end;

         for i:=1 to ord(dec_str[0]) do
            begin
               putc(dec_str[i]);
            end;
      end;
end;



procedure print_pchar(c:pchar);
begin
while (c^ <> #0) do
 begin
 putc(c^);
 c += 1;
end;
end;


{******************************************************************************
 * print_dword
 *
 * Print a dword in hexa
 *****************************************************************************}
procedure print_dword (nb : dword); [public, alias : 'PRINT_DWORD'];

var
   car : char;
   i, decalage, tmp : byte;

begin

   putc('0');putc('x');

   for i:=7 downto 0 do

   begin

      decalage := i*4;

      asm
         mov   eax, nb
         mov   cl , decalage
	 shr   eax, cl
	 and   al , 0Fh
	 mov   tmp, al
      end;

      car := hex_char[tmp];

      putc(car);

   end;
end;



{ * DumpTask :                                                           *
  *                                                                      *
  * Pid : Numero de  Pid de la tarea                                     *
  *                                                                      *
  * Procedimiento que vuelca en la pantalla los registros mas importan   *
  * tes de una tarea                                                     *
  *                                                                      *
  ************************************************************************
}

procedure DumpTask(Pid:dword);
var tmp : p_tarea_struc;
    page_fault : dword ;
begin
cerrar;
tmp := Hash_Get(Pid) ;
page_fault := 0 ;

asm
mov eax , cr2
mov page_fault,eax
end;

If tmp = nil then exit ;

printk('\n/nVolcado de Registros de la Tarea : /V%d \n',[tmp^.pid],[]);

printk('/neax : /v%h /nebx : /v%h /necx : /v%h /nedx : /v%h \n',
[tmp^.reg.eax , tmp^.reg.ebx , tmp^.reg.ecx , tmp^.reg.edx],[]);

printk('/nesp : /v%h /nebp : /v%h /nesi : /v%h /nedi : /v%h \n',
[tmp^.reg.esp,tmp^.reg.ebp,tmp^.reg.esi,tmp^.reg.edx],[]);

printk('/nflg : /v%h /neip : /v%h /ncr3 : /v%h /ncr2 : /v%h \n',
[tmp^.reg.eflags,tmp^.reg.eip,tmp^.reg.cr3,page_fault],[]);

abrir;
end;



procedure Limpiar_P;
begin
asm
push edi
push esi
mov eax , VIDEO_OFF
mov edi , eax
mov ax , 0720h
mov cx , 2000
rep stosw
pop esi
pop edi
end;

x := 0;
y := 0;
end;

end.
