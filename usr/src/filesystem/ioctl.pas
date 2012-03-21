Unit ioctl;


{ * Ioctl :                                                     *
  *                                                             *
  * Implementacion de las llamadas de control                   *
  *                                                             *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>  *
  * All Rights Reserved                                         *
  *                                                             *
  * Versiones :                                                 *
  * 2 / 2 / 2005 : Primera Version                              *
  *                                                             *
  ***************************************************************
}


interface


{$I ../include/toro/procesos.inc}
{$I ../include/head/scheduler.h}
{$I ../include/head/printk_.h}
{$I ../include/head/asm.h}


implementation

{ * Sys_Ioctl :                                                         *
  *                                                                     *
  * Fichero : Descriptor de Archivo                                     *
  * req : Numero de procedimiento                                       *
  * argp : Puntero a los argumentos                                     *
  * Retorno : -1 si fallo                                               *
  *                                                                     *
  *                                                                     *
  * Implementacion de la llamada al sistema IOCTL donde se llama a un   *
  * procedimiento de control de un  driver dado                         *
  *                                                                     *
  ***********************************************************************
}


function sys_ioctl (Fichero , req : dword ; argp : pointer) : dword ;cdecl;[public , alias :'SYS_IOCTL'];
var fd : p_file_t ;
begin

If (Fichero > 32) then
 begin
  set_errno := -EBADF ;
  exit(-1);
 end;

fd := @Tarea_Actual^.Archivos[Fichero];

If fd^.f_op = nil then
 begin
  set_Errno := -EBADF ;
  exit(-1);
 end;

If fd^.f_op^.ioctl = nil then
 begin
  set_errno := -EPERM ;
  exit(-1);
 end;

exit(fd^.f_op^.ioctl(fd,req,argp));

end;



end.
