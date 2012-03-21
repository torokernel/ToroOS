
{ * mkdir :                                                             *
  *                                                                     *
  * Simple aplicacion que crea un directorio .                          *
  *                                                                     *
  *                                                                     *
  * Copyright (c) 2003-2007 Matias Vara <matiasvara@yahoo.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  *                                                                     *
  ***********************************************************************
}



uses toro , crt ;
begin


If (Paramcount = 0) then
 begin
 writeln('Crea un directorio');
 writeln('Uso : mkdir [path]');
 writeln('by Matias Vara');
 exit;
end;

mkdir(paramstr(1));
end.
