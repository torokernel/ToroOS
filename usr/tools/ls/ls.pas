
{ * ls :                                                               *
  *                                                                    *
  * Lista un directorio                                                *
  *                                                                    *
  * Copyright (c) 2003-2007 Matias Vara <matiasvara@yahoo.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  * Versiones :                                                        *
  *                                                                    *
  * 14 / 02 / 06 : Es reescrito                                        *
  *                                                                    *
  **********************************************************************
}

uses toro,strings,crt;

var dir : pdir ;
    buf : pdirent ;
    tmp  : ansistring ;
    tmp2 : pchar ;



procedure mostrar_file(f : pchar) ;
var i: stat ;
begin

gotoxy(1,25);

{ llamada que me devuelve un inodo }
if statf(f , i) = -1 then
 begin
  writeln('error al abrir' , f);
  exit;
 end;


If (i.flags and STAT_IXOTH) = STAT_IXOTH then write('e') else write('-');
if (i.flags and STAT_IWOTH) = STAT_IWOTH then write('w') else write('-');
if (i.flags and STAT_IROTH) = STAT_IROTH then write('r') else write('-');


if (i.mode and STAT_IFREG) = STAT_IFREG then write('r') else write('-');
if (i.mode and STAT_IFDIR) = STAT_IFDIR then write('d') else write('-');
if (i.mode and STAT_IFCHR) = STAT_IFCHR then write('c') else write('-');
if (i.mode and STAT_IFBLK) = STAT_IFBLK then write('b') else write('-');

write('--');

case i.mode of
STAT_IFDIR: textcolor(lightgreen) ;
STAT_IFCHR: textcolor(blue);
STAT_IFBLK : textcolor(white);
STAT_IFREG : if (i.flags and STAT_IXOTH)= STAT_IXOTH then textcolor(lightblue) else textcolor(7);
end;

gotoxy(15,25);
write(f);

gotoxy(60,25);
textcolor(7);

write(i.size);
writeln('');
end;

begin


if paramcount = 0 then dir := opendir ('.')
 else if paramcount = 1 then
  begin

   if paramstr(1) = '/?' then
     begin
      writeln('Lista un directorio mostrando los archivos y subdirectorios');
      writeln('ls [path]');
      writeln('by Matias Vara');
      exit;
     end;

   tmp := paramstr(1);
   dir := opendir(pchar(tmp));

   { el directorio actual es cambiado }
   chdir (pchar(tmp));

   end
 else
  begin
   writeln('comandos incorrectos');
   exit;
  end;

 tmp2 := stralloc (255);

 if dir = nil then
  begin
   writeln ('directorio invalido');
   exit;
  end;

 buf := readdir (dir);

 gotoxy(1,25);

 while (buf <> nil) do
  begin
   strpcopy (tmp2,buf^.name);
   mostrar_file(tmp2);
   buf := readdir (dir);
  end;



end.
