Unit read_write;

{ * Read_Write :                                                      *
  *                                                                   *
  * Esta unidad contiene las llamadas al sistema DO_READ , DO_WRITE Y *
  * DO_SEEK , importantisimas para el sistema de archivos , ya que ma *
  * nipulan los ficheros                                              *
  *                                                                   *
  * Copyright (c) 2003-2005 Matias Vara <matiasvara@yahoo.com>        *
  * All Rights Reserved                                               *
  *                                                                   *
  * Versiones :                                                       *
  * 07 / 07 / 2005 : Reescritura integra de las syscalls para         *
  *                  la implementacion del VFS                        *
  *                                                                   *
  * 26 / 12 / 2004 : Los threads de kernel no pueden realizar         *
  *                  llamadas al FS                                   *
  *                                                                   *
  * 06 / 08 / 2004 : Se aplica el modelo paginado , los threads tam   *
  *                  bien pueden realizar llamadas al FS              *
  * 30 / 03 / 2004 : Las copias son realizadas sobre el segmento FS   *
  *                                                                   *
  * 12 / 03 / 2004 : Primera Version                                  *
  *                                                                   *
  *********************************************************************
}


interface
{DEFINE DEBUG}


{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/inodes.h}
{$I ../Include/Toro/buffer.inc}
{$I ../Include/Head/buffer.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/blk_dev.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/procesos.h}

implementation

{$I ../Include/Head/lock.h}

{ * Sys_Seek :                                                             *
  *                                                                        *
  * File_Desc : Descriptor del archivo                                     *
  * offset : Posicion donde se quiere posicionar el archivo                *
  * whence : Algoritmo que se utilizara                                    *
  * Devuelve : La nueva posicion del archivo o 0 si falla                  *
  *                                                                        *
  * Se encarga de posicionar un archivo en un byte dado , segun el         *
  * algoritmo en whence  , si la llamada fue correcta devuelve la          *
  * nueva posicion sino devuelve 0                                         *
  *                                                                        *
  **************************************************************************
}
function sys_seek ( File_desc : dword ; offset , whence : dword ) : dword ; cdecl;[public , alias :'SYS_SEEK'];
var ret : dword ;
    p_file : p_file_t ;
begin

{Se chequea el descriptor}
If File_desc > 32 then exit(0);

{Puntero al descriptor}
p_file := @Tarea_Actual^.Archivos[File_desc];

If p_file^.f_op = nil then exit(0);

if p_file^.f_op^.seek = nil then exit(0);

{no se puede hacer un seek sobre un inodo dir}
if p_file^.inodo^.mode = dt_dir then exit(0);

Inode_lock (@p_file^.inodo^.wait_on_inode);

{se llama al driver para que haga el trabajo}
if p_file^.f_op^.seek (p_file,whence,offset) = -1 then ret := 0 else ret := (p_file^.f_pos);
Inode_unlock (@p_file^.inodo^.wait_on_inode);

exit(ret);
end;



{ * Sys_Read:                                                           *
  *                                                                     *
  * File_Desc : Descriptor del archivo                                  *
  * buffer : Puntero donde sera almacemado el contenido                 *
  * nbytes : Numero de bytes leidos                                     *
  * Devuelve : El numero de bytes leidos                                *
  *                                                                     *
  * Se encarga de la lectura de un fichero cualquiera sea este          *
  *                                                                     *
  ***********************************************************************
  }
function sys_read( File_Desc : dword ; buffer : pointer ; nbytes : dword ) : dword;cdecl;[public, alias :'SYS_READ'];
var pfile:p_file_t;
    ret : dword ;
label _exit ;
begin


{Aqui es protegida el area del kernel}
If Buffer < pointer(High_Memory) then
 begin
  set_errno := -EFAULT ;
  goto _exit ;
 end;

set_errno := -EBADF ;

If File_desc > 31 then goto _exit ;

{Se puntea al descriptor del archivo}
pfile:=@Tarea_Actual^.Archivos[File_Desc];

{estan definidos los handlers??}
if (pfile^.f_op = nil) then goto _exit ;

{no se abrio para lectura!!}
if (pfile^.f_mode and O_RDONLY = O_RDONLY) then
 else
  begin
   set_errno := -EACCES ;
   goto _exit ;
  end;

set_errno := -ENODEV;

if (pfile^.inodo^.mode = dt_dir ) and (pfile^.f_op^.readdir = nil) then exit(0)
 else if pfile^.f_op^.read = nil then exit(0);

clear_errno;

{esto me asegura la consistencia del archivo}
Inode_lock (@pfile^.inodo^.wait_on_inode);

case pfile^.inodo^.mode of
dt_reg : ret := pfile^.f_op^.read (pfile,nbytes,buffer);
dt_dir : ret := pfile^.f_op^.readdir (pfile,buffer);
dt_blk : ret := Blk_Read (pfile, nbytes ,buffer );
dt_chr : ret := pfile^.f_op^.read(pfile,nbytes,buffer);
end;

Inode_unlock (@pfile^.inodo^.wait_on_inode);

exit(ret);

_exit :

exit(0);
end;



{ * Sys_Write :                                                         *
  *                                                                    *
  * File_desc : Descriptor del archivo                                 *
  * Buffer : Lugar de donde se extraeran los datos                     *
  * nbytes : Numero de bytes                                           *
  * Devuelve : Numero de bytes escritos                                *
  *                                                                    *
  * Se encarga de escribir cualquier tipo de fichero                   *
  *                                                                    *
  **********************************************************************
}
function sys_write ( file_desc : dword ; buffer : pointer ; nbytes : dword) : dword;cdecl;[PUBLIC , ALIAS :'SYS_WRITE'];
var pfile : p_file_t;
    ret : dword ;
begin

{El buffer devera estar en el area del usuario}
If buffer < pointer(High_Memory) then
 begin
  set_errno := -EFAULT ;
  exit(0);
 end;

set_errno := -EBADF;

If File_Desc > 31 then exit(0);

{Se puntea al descriptor del archivo}
pfile:=@Tarea_Actual^.Archivos[File_Desc];

{estan definidos los handlers??}
if (pfile^.f_op = nil) then exit(0);

{no se abrio para escritura!!}
if (pfile^.f_mode and O_WRONLY = O_WRONLY) then
 else
  begin
   set_errno := -EACCES ;
   exit(0);
  end;

set_errno := -ENODEV;

if (pfile^.inodo^.mode = dt_dir ) then exit(0)
 else if pfile^.f_op^.write = nil then exit(0);

clear_errno;

{esta proteccion me asegura que dos procesos no escriban a la ves un mismo}
{archivo}
Inode_lock (@pfile^.inodo^.wait_on_inode);

{segun el tipo de archivo!!!}
case pfile^.inodo^.mode of
dt_reg : ret := (pfile^.f_op^.write (pfile,nbytes,buffer));
dt_blk : ret := (Blk_write (pfile, nbytes ,buffer ));
dt_chr : ret := (pfile^.f_op^.write(pfile,nbytes,buffer));
end;

Inode_unlock (@pfile^.inodo^.wait_on_inode);

exit(ret);
end;


end.
