{ * Strings :                                                           *
  *                                                                     *
  * Aqui se encuentran procedimientos y funciones necesarios para el    *
  * tratamiento  de cadenas  y rutas . Estan declados como inline para  *
  * que sean mas rapidos                                                *
  *                                                                     *
  ***********************************************************************
}



uses strings;

procedure pcharcopy (path  : pchar ; var name : string ) ;inline;
var len : dword ;
begin

len := path - strend(path) - 1 ;

if len > 255 then len := 255 ;

strlcopy (@name[1] ,path,len);

name[0] := chr(len) ;
end;




function pathcopy (path :pchar ; var  name : string ) : boolean ;
var len , tm:dword;
    tmp : pointer ;
begin

len :=  longint(strend(path)) - longint(path) ;

tmp := strrscan (path,'/');

if (tmp <> nil) then
 begin
 tm := longint(tmp) - longint(path)  ;
 len -= tm ;
 end;

if (tmp = nil)  then   else path := ((strrscan (path,'/') +1) );

memcopy (path,@name[1],len);

name[0] := char(len);

exit(true);
end;


function chararraycmp (ar1 , ar2 : pchar ; len :dword ): boolean ;inline;
var ret :dword ;
begin
for ret := 1 to len do
 begin
  if (ar1^ <> ar2^) then exit(false);
  ar1 += 1;
  ar2 += 1;
 end;

exit(true);
end;


procedure fillbyte(buffer:pointer;count:dword;value:byte);inline;
begin
asm
mov al ,value
mov edi , buffer
mov ecx , count
rep stosb
end;
end;


{ * Pchar_Copy :                                                        *
  *                                                                     *
  * Origen  : Pchar de origen                                           *
  * Destino : Pchar donde sera copiado                                  *
  * count : Tama¤o del pchar                                            *
  *                                                                     *
  * Procedimiento similar a memcopy , solo que copia hasta  count o     *
  * hasta encontrar un caracter nulo                                    *
  *                                                                     *
  ***********************************************************************
}
procedure pchar_copy (Origen,Destino : pchar ;count : dword) ;inline;
var cont :dword ;
begin
cont := 0 ;
while (origen^ <> #0) and (cont <= count) do
 begin
 destino^ := origen^ ;
 destino += 1;
 origen += 1;
 cont += 1;
end;

{Marco el final de cadena}
if (cont < count ) then destino^ := #0;
end;


{ * pcharlen : funcion simple que devuelve la longitud de un pchar * }

function pcharlen ( pc : pchar ) : dword ; inline;
var cont : dword ;
begin

cont := 0 ;

while (pc^ <> #0) do
 begin
  cont += 1 ;
  pc += 1;
end;

exit(cont);
end;
