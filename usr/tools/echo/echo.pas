{ * echo :                                                              *
  *                                                                     *
  * Simple programa que desplega un texto en pantalla                   *
  *                                                                     *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  ***********************************************************************
}



uses crt ;

var f: text ;
    buf :  string ;
    r : char ;
    line : longint ;
begin

if paramcount = 0 then
 begin
  gotoxy(1,25);
  writeln('Abre un archivo para lectura y lo desplega en pantalla');
  writeln('echo [path]');
  writeln('by Matias Vara');
  exit;
 end;

assign (f , paramstr(1));
reset (f);

clrscr;
set_echo(false);
line := 1 ;
gotoxy(1,1);

while not(eof(f)) do
begin
 readln(f,buf);
 writeln(buf);
 line += 1;

 if line = 25 then
  begin
   r := readkey ;
   line := 1 ;
  end;

end;

set_echo(true);
close (f);
end.
