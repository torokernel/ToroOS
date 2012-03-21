Unit mount;

{ * Mount :                                                             *
  *                                                                     *
  * Esta unidad se encarga de las llamadas al sistema MOUNT Y UNMOUNT   *
  * que crean la abtracion de terner un solo sistema de archivo , cuan  *
  * do en realidad son FS unidos , al ROOT , todos los FS se pegan al   *
  * ROOT , y los puntos de montage son eliminados una ves reseteada la  *
  * maquina puesto que solo existen en memoria                          *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  * 07 / 07 / 2005 : Reescritura integra para dar soporte al VFS        *
  * 13 - 03 - 2004 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************

  }
interface

{$define debug}

{$I ../include/toro/procesos.inc}
{$I ../include/head/asm.h}
{$I ../include/head/inodes.h}
{$I ../include/toro/buffer.inc}
{$I ../include/head/buffer.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/open.h}
{$I ../include/head/printk_.h}
{$I ../include/head/dcache.h}
{$I ../include/head/super.h}
{$I ../include/head/namei.h}
{$I ../include/head/version.h}

implementation

{$I ../include/head/string.h}

{ * Sys_Mount :                                                      *
  *                                                                  *
  * path : Ruta al archivo especial de bloque                        *
  * path_mount : Ruta donde sera montado el sistema                  *
  * fs_name : Tipo de fs a montar                                    *
  *                                                                  *
  * Se encarga de montar al directorio raiz un  sistema de archivos  *
  * ,dado en un archivo especial de bloque , se hacen muchas         *
  * controles ya que  si no hay un control el sistema se volvia alta *
  * mente inistable , solo se pueden montar unidades sobre root y no *
  * sobre otros fs que no se root puesto que podria ocacionar que un *
  * mismo numero de inodo en se utlice para montar un sistema y que  *
  * el sistema devuelva que el FS ya fue montado .                   *
  *                                                                  *
  * 31 / 07 / 2005 : Primera version con VFS (No probada)            *
  *                                                                  *
  ********************************************************************
}
function sys_mount(path,path_mount,name:pchar):dword;cdecl;[public , alias :'SYS_MOUNT'];
var tmp:p_inode_t;
    mayor,menor : dword ;
    sname : string[20] ;
    fs_type : p_file_system_type ;
    spbmount : p_super_block_t ;

label _exit ;
begin

{Inodo del archivo especial}
tmp := name_i(path);

set_errno := -ENOENT ;

If tmp=nil then exit(-1);

set_errno :=  -ENOTBLK;

if tmp^.mode <> dt_blk then goto _exit ;

mayor := tmp^.rmayor ;
menor := tmp^.rmenor ;

put_dentry (tmp^.i_dentry);

clear_errno ;

{Si ya estuviese montado salgo}
If (Get_Super(mayor,menor) <> nil ) then exit(-1);

{Obtengo el inodo del dir donde se creara el montage}
tmp := name_i(path_mount);

set_errno := -ENOENT ;

if tmp=nil then  exit(-1);

set_errno := -EISDIR ;

{Devera ser un dir}
If (tmp^.mode <> dt_dir) then goto _exit ;

{El dir deve residir en Root}
If  (tmp^.mayor <> i_root^.mayor) and (tmp^.menor <> I_root^.menor) then goto _exit;

{ es traido el nombre del sistema que sera montado }
sname[0] := char (pcharlen(name)) ;
if byte(sname[0]) > 20 then goto _exit ;
pcharcopy (name,sname);
sname[0] := char (pcharlen(name));

fs_type := get_fstype (sname) ;

if fs_type = nil then goto _exit ;

{se trae y se agrega a la cola de spb instalados}
spbmount := read_super (mayor,menor,sb_rdonly or sb_rw,fs_type) ;

if spbmount = nil then goto _exit;

tmp^.i_dentry^.l_count += 1;
tmp^.i_dentry^.down_mount_tree := spbmount^.pino_root^.i_dentry ;

{$ifdef debug}
 printk('/VVFS/n : Sistema %p montado con exito\n',[sname],[]);
{$endif}

exit(0);

_exit :

 {$ifdef debug}
  printk('/VVFS/n : Sistema %p no pudo ser montado\n',[sname],[]);
 {$endif}

 put_dentry (tmp^.i_dentry);
 exit(-1);

end;


{ * Sys_UnMount :                                                        *
  *                                                                     *
  * path : Ruta del directorio montado                                  *
  * Retorno :  0 si fue correcto o <> 0 sino                            *
  *                                                                     *
  * Esta funcion se encarga de desmontar del inodo root un sistema      *
  * de archivo montado en path                                          *
  *                                                                     *
  ***********************************************************************
}


function sys_unmount(path:pchar):dword;cdecl;[public , alias :'SYS_UNMOUNT'];
begin
printk('/Vvfs/n : Unmount funcion no implementada \n',[],[]);
exit(-1);
end;



{ * Sys_Mountroot :                                                     *
  *                                                                     *
  * Se encarga de montar la unidad que sera utilizada como root es      *
  * llamada por el proceso init                                         *
  *                                                                     *
  ***********************************************************************
}
procedure sys_mountroot ; cdecl ; [public , alias : 'SYS_MOUNTROOT'];
var fs_type : p_file_system_type ;
    spbmount : p_super_block_t ;

label _exit;
begin

{este campo sera modificado de acuerdo al fs del root}
fs_type := get_fstype ('fatfs');

if fs_type = nil then goto _exit ;

{aca es donde se especifica el dispositivo de montage}
spbmount := read_super (2 , 0 , sb_rdonly or sb_rw , fs_type);

if spbmount = nil then goto _exit ;

i_root := spbmount^.pino_root ;
dentry_root := i_root^.i_dentry ;

{importante!!}
dentry_root^.name := '/' ;
dentry_root^.len := 1 ;
dentry_root^.down_tree := nil ;
dentry_root^.flags := i_root^.flags ;
dentry_root^.state := st_incache ;


i_root^.count += 1;
i_root^.i_dentry^.count += 1;
Tarea_Actual^.cwd := i_root ;


printk('/Vvfs/n ... root montada\n',[],[]);

{ bienvenida al usuario }
toro_msg;

exit;

_exit :

printk('/Vvfs/n : No se ha podido montar la unidad root\n',[],[]);
debug($1987);

end;

end.
