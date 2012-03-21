
{ * Reboot :                                                           *
  *                                                                    *
  * Simple ejecutable que realiza el booteo de la maquina              *
  *                                                                    *
  *                                                                    *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  **********************************************************************
  }


uses toro , crt ;

var r : char ;

begin
clrscr;
Highvideo;
TextBackground(red);
writeln('Vaciando el cache ...');
sync;
writeln('Precione una tecla para resetear ...');
read(r);
reboot;
end.
