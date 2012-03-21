Unit Init;

{ * Init :                                                           *
  *                                                                  *
  * Esta unidad crea el proceso inicial y luego salta hacia el , se  *
  * llamara una vez ejecutado todos los modulos del kernel , se enca *
  * r gara de leer archivos de configuracion , abrir la shell del sis*
  * tema , etc . Es la primer tarea en el contexto de usuario.       *
  *                                                                  *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>       *
  * All Rights Reserved                                              *
  *                                                                  *
  * Versiones                                                        *
  *                                                                  *
  * 9 - 12 - 2003 : Version Inicial                                  *
  *                                                                  *
  ********************************************************************
}


interface

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Toro/utime.inc}

{ aqui es definida la ubicacion de la shell!!! }
{$define SHELL_PATH := '/bin/sh' }

implementation

{$I ../Lib/toro_sys/toro_sys.h}


procedure init_;[public , alias :'INIT_'];
Var ret,tmp:dword;
begin

MountRoot;

ret := exec_(SHELL_PATH,nil);

while (true) do ret:=WaitPid(tmp);
asm @bucle:jmp @bucle end;

end;




end.
