


{ * Enviar_Byte :                                                       *
  *                                                                     *
  * Simple procedimiento que envia unbyte a un puerto dado              *
  *                                                                     *
  ***********************************************************************
}
procedure enviar_byte(Data:byte;Puerto:word);assembler;inline;
asm
mov dx,Puerto
mov al,data
out dx,al
end;


function leer_byte(puerto:word):byte;
var tmp : byte ;
begin
asm
mov dx,Puerto
in  al,dx
mov tmp , al
end;
exit(tmp);
end;


procedure Enviar_Wd(Data:word;Puerto:dword);inline;
var tmp : pointer ;
begin
tmp := @data ;
asm
mov edx , Puerto
mov esi , tmp
outsw
end;
end;


function Leer_Wd(Puerto:word) : word ;inline;
var r:dword;
   tmp : pointer ;
begin

tmp := @r ;

asm
mov dx , Puerto
mov edi ,  tmp
insw
end;

exit(r);
end;


function Leer_DW(Puerto:word):word;inline;
var r : word;
    tmp : pointer ;
begin

tmp := @r;

asm
mov dx , puerto
mov edi , tmp
insd
end;

exit(r);
end;



procedure Enviar_DW(Data:dword;Puerto:word);inline;
var tmp : pointer ;
begin
tmp := @data ;

asm
mov esi , tmp
mov dx , puerto
outsd
end;

end;


procedure delay_io;
var tmp  : dword ;
begin
for tmp := 1 to 500 do ;
end;


function Verify_User_Buffer (buff : pointer) : boolean;inline;
begin
if buff < pointer ($40000000) then exit(false) else exit(true);
end;


function cmos_read(port : byte ) : byte ;inline;
begin
enviar_byte($80 or port , $70);
delay_io;
exit(leer_byte($71));
end;
