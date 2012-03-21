{ * cat :                                                              *
  *                                                                    *
  * Simple programa que guarda una cadena de texto en un archivo dado  *
  *                                                                    *
  *                                                                    *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  **********************************************************************
}

uses crt , toro ;

var f : text ;

   { se limita el tama¤o del archivo }
   buf : array[0..2000] of char ;

begin

if paramcount = 0 then
 begin
  gotoxy(1,25);
  writeln('Crea o trunca a 0  un archivo de texto');
  writeln('cat [path]');
  writeln('by Matias Vara');
  exit;
 end;
writeln('Precione # para salir');
assign (f , paramstr(1));
rewrite(f);
gotoxy(1,25);

readln(buf);
write(f , buf);
close(f);
end.
