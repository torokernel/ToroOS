Unit open;

{ * Open :                                                           *
  *                                                                   *
  * En esta unidad se encarga de funciones excenciales para el FS     *
  * , desde aqui se realizan las llamadas al sistema para la creacion *
  * de archivos , directorios y archivos especiales y su apertura  .  *
  *                                                                   *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>        *
  * All Rights Reserved                                               *
  *                                                                   *
  * Versiones :                                                       *
  *                                                                   *
  * 06 / 07 / 2005 : Es rescrito integramente el codigo para dar      *
  *                  soporte al nuevo VFS                             *
  *                                                                   *
  * 03 / 04 / 2005: Se implementa la llamada chdir()                  *
  * 26 / 12 / 2004: Es modificada ls funcion Open_() y es creada la   *
  *                 llamada al sistema sys_MounRoot                   *
  *                                                                   *
  * 15 / 11 / 2004: Es eliminada la unidad Root y esta pasa a ser el  *
  *                 disket                                            *
  *                                                                   *
  * 19 / 10 / 2004: Son solucionados la mayoria de los problemas y es *
  * limpiado el codigo                                                *
  *                                                                   *
  * 05 / 05 / 2004: Se modifica el procedimiento namei()              *
  *                                                                   *
  * 12 / 03 / 2004: Primer Version                                    *
  *                                                                   *
  *********************************************************************
}


interface

{define debug}


{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/inodes.h}
{$I ../Include/Toro/buffer.inc}
{$I ../Include/Head/buffer.h}
{$I ../Include/Toro/utime.inc}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/read_write.h}
{$I ../Include/Head/devices.h}
{$I ../Include/Head/blk_dev.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/relog.h}
{$I ../Include/Head/namei.h}
{$I ../Include/Head/dcache.h}


function sys_open (path : pchar ; mode , flags : dword) : dword ; cdecl;

implementation

{$I ../Include/Head/string.h}
{$I ../Include/Head/lock.h}



function Is_Dir (ino : p_inode_t ) : boolean;inline;
begin
if ino^.mode and dt_dir = dt_dir then exit(true) else exit(false);
end;



function Is_Blk (ino : p_inode_t ) : boolean ; inline;
begin
if ino^.mode and dt_blk = dt_blk then exit(true) else exit(false);
end;



function Is_chr (ino : p_inode_t) : boolean ; inline;
begin
if ino^.mode and dt_chr = dt_chr then exit(true) else exit(false);
end;



function validate_path (path : pchar) : boolean ; inline;
begin
if (path - strend(path)) > Max_Path then exit(false) else exit(true);
end;



function get_free_filp : p_file_t ; inline;
var cont : dword ;
    tmp : p_file_t ;
begin

for cont := 1 to 32 do
 if Tarea_Actual^.Archivos[cont].f_op = nil then exit(@Tarea_Actual^.Archivos[cont]);
 exit(nil);
end;




function Nr_Filp (filp : p_file_t) : dword ;inline;
begin
exit((longint(filp) - longint (@Tarea_Actual^.Archivos[0])) div sizeof(file_t)) ;
end;


procedure free_filp (filp : p_file_t) ;inline;
begin
filp^.f_op := nil ;
end;




function file_create (ino : p_inode_t ; dt : p_dentry ) : boolean ;inline;
begin

{la llamada create del driver se limita a crear el archivo}
if ino^.op^.create (ino,dt,0) = -1 then  exit(false)
 else exit(true);

end;


function filp_open (filp : p_file_t)  : dword ;inline;
begin
if filp^.f_op =  nil then exit(-1)
 else
  begin
   {la estructura de esta funcion no esta definida}
   if filp^.f_op^.open = nil then exit(0)
    else exit(filp^.f_op^.open (filp^.inodo,filp))
   end;
end;

function validate_blkmayor (Mayor : dword ) : boolean ; inline;
begin
if (Mayor > Nr_blk ) or (blk_dev[mayor].fops = nil) then exit(false)
 else exit(true);
end;


function validate_chrmayor (mayor : dword ) : boolean ; inline;
begin
if ((mayor > Nr_Chr) or (mayor < Nr_Blk)) or (chr_dev[mayor].fops = nil) then exit(false)
 else exit(true);
end;


{ * Sys_Mkdir :                                                      *
  *                                                                  *
  * Path : Ruta donde sera creado el directorio                      *
  * Name : Nombre del directorio                                     *
  * Modo : Modo de acceso al directorio                              *
  *                                                                  *
  * Devuelve : si fue correcta 0 sino un valor <> 0                  *
  * Esta llamada al sistema se encarga de crear un nuevo directorio  *
  * en una ruta dada                                                 *
  ***4*****************************************************************
}

function sys_mkdir(path  : pchar ; mode : dword ) : dword ; cdecl ;[public , alias :'SYS_MKDIR'];
var tmp:p_inode_t;
    dt : dentry ;
    pdt : p_dentry ;


label _exit;
begin

clear_errno;
if validate_path (path) then else exit(-1);

if pathcopy (path,dt.name) then else exit(-1);

dt.len := dword(dt.name[0]);

{si existe el dir no puede ser creado}
tmp := name_i (path);
if tmp <> nil then goto _exit;

tmp := last_dir (path);

set_errno := -ENOTDIR;

{ruta inexistente}
if tmp = nil then goto _exit ;

set_errno := -EACCES ;

{no se puede escribir el inodo!!}
if (tmp^.flags and I_WO ) <> I_WO then goto _exit;

set_errno := -ENODEV;

{se crea la entrada dir pero el driver debe limitarse a trabajar con }
{esa dentry y no agregarla al cache puesto que eso lo hara el s.o. solo }
{devera llenar los campos}
{es una dentry temporal y no se deve enlazar con el inodo }

{me protejo por si alguien lo estubiese usando}
Inode_Lock (@tmp^.wait_on_inode);

if tmp^.op^.mkdir (tmp,@dt,mode) = -1 then
 begin
  Inode_Unlock (@tmp^.wait_on_inode);
  goto _exit;
 end;

Inode_Unlock (@tmp^.wait_on_inode);

{la nueva entrada no es agregada al cache!!!}

Put_dentry (tmp^.i_dentry);

clear_errno ;

exit(0);

_exit :
    Put_dentry (tmp^.i_dentry);
    exit(-1);

end;



{ * Sys_Create :                                                        *
  *                                                                     *
  * path : Puntero a la ruta                                            *
  * mode : Modo de apertura                                             *
  *                                                                     *
  * Implementacion de la llamada creat                                  *
  *                                                                     *
  ***********************************************************************
}
function sys_create (path : pchar ; mode : dword) : dword ;cdecl;[public , alias :'SYS_CREATE'];
begin
exit(sys_open (path,mode ,O_CREAT or O_TRUNC));
end;




{ * Sys_Mknod :                                                           *
  *                                                                       *
  * path : Ruta donde sera creado el archivo especial                     *
  * flags : bits rwe                                                      *
  * Mayor : Numero Mayor del Dispositivo                                  *
  * Menor : Numero menor del Dev.                                         *
  * Devuelve : 0 si fue correcto sino -1                                  *
  *                                                                       *
  * Esta funcion se encarga de crear un archivo especial , son utilizados *
  * para accesar a los dispositivos tanto de bloques como de caracteres   *
  * a mas bajo nivel , no devuelve un descriptor , sino el resulatado de  *
  * la operacion                                                          *
  *                                                                       *
  *************************************************************************
  }
function sys_mknod(path : pchar ; flags , mayor , menor : dword ) :dword;cdecl;[public , alias :'SYS_MKNOD'];
var tmp :p_inode_t ;
    dt : dentry ;

label _exit;
begin

clear_errno;

tmp := name_i (path);

set_errno := -ENOTDIR;

{ruta inexistente}
if tmp = nil then  exit(-1);

{deve ser un dir!!! }
if not (Is_dir (tmp)) then exit(-1);

set_errno := -EACCES ;

{no se puede escribir el inodo!!}
if (tmp^.flags and I_WO ) <> I_WO then goto _exit;

set_errno := -ENODEV;

{hay que validar los numeros del dev}
if (Mayor < Nr_blk ) then
 begin
   if Blk_Dev [Mayor].fops = nil then goto _exit ;
   dt.name := Blk_Dev[mayor].name ;
 end
  else if (Mayor > Nr_blk) and (Mayor < Nr_Chr) then
   begin
    if chr_Dev [mayor].fops = nil then goto _exit;
    dt.name := chr_dev[mayor].name;
   end
    else goto _exit ;

   dt.name[byte(dt.name[0])+1] := nr_menor[menor];
   dt.name[0] := chr (byte(dt.name[0]) + 1);

   {se llama al proc. del driver , como en mkdir dt es un dentry  }
   {temporal pero el driver no lo sabe es por eso que llena el    }
   { campo ino ,  por eso lo devuelvo al cache                    }

   Inode_Lock (@tmp^.wait_on_inode);

   if tmp^.op^.mknod (tmp,@dt,flags,mayor,menor) = -1 then
    begin
     Inode_unlock (@tmp^.wait_on_inode);
     goto _exit
    end
    else
     begin
      clear_errno;
      put_dentry (tmp^.i_dentry);
      Inode_unlock (@tmp^.wait_on_inode);
      exit(0);
     end;


_exit :

put_dentry (tmp^.i_Dentry);
exit(-1);

end;





{ * Sys_Open :                                                          *
  *                                                                     *
  * path : Ruta del archivo                                             *
  * Modo : Modo de acceso                                               *
  * flags : Modo de la llamada                                          *
  * Devuelve :El descriptor del archivo                                 *
  *                                                                     *
  * Realiza la apertura de un archivo a traves del VFS no importa       *
  * el tipo de archivo  , devuelve el descriptor de archivo o -1 si     *
  * falla y el error queda en errno                                     *
  *                                                                     *
  ***********************************************************************
}
function sys_open (path : pchar ; mode , flags : dword) : dword ; cdecl;[public , alias :'SYS_OPEN'];
var tmp : p_inode_t ;
    filp : p_file_t ;
    dt : dentry ;
    p_dt : p_dentry ;

label _exit,_filp;
begin

clear_errno;

if validate_path (path) then else exit(0);

if pathcopy (path,dt.name) then  else exit(0);

dt.len := dword(dt.name[0]);

{se trae el inodo}
tmp := name_i (path);

set_errno := -ENOTDIR;

{ruta invalida!!!!}
if (tmp = nil) then
 begin

  {bandera de crear archivo !!!!}
  if (flags and O_CREAT) = O_CREAT  then
   begin

    {lugar donde creare el archivo}
     tmp := last_dir (path) ;

     if tmp = nil then exit(0) ;

     {se tratara de crear el archivo regular }
     if file_create (tmp,@dt) then
      begin

       {aloja la entrada en el cache}
       p_dt := alloc_entry (tmp,dt.name) ;

       {que kilombo!!! paso algo en el cache!!!!}
       if p_dt = nil then goto _exit;

       {se devuelve el ultimo directorio}
       put_dentry (tmp^.i_dentry);

       tmp := p_dt^.ino ;

       {ya esta metido en el cache toda la direccion!! se creara el descr.}
       goto _filp

        end
       else exit(0);

    end else exit(0);

 end;

{si existe bandera de truncar tu tama¤o a 0 !!!}
if (flags and O_TRUNC) = O_TRUNC then tmp^.op^.truncate (tmp);

set_errno := -EACCES ;

{no se puede escribir el inodo!!}
if ((tmp^.flags and I_WO ) <> I_WO) and (mode and O_WRONLY = O_WRONLY) then goto _exit;

{no se puede leer!!!}
if ((tmp^.flags and I_RO ) <> I_RO) and (mode and O_RDONLY = O_RDONLY) then goto _exit;


_filp :

{hay lugar en la tabla de archivos??}
filp := get_free_filp;

set_errno := -EMFILE;

if filp = nil then goto _exit;

case tmp^.mode of
dt_chr : if validate_chrmayor(tmp^.rmayor) then filp^.f_op := chr_dev[tmp^.rmayor].fops
         else
           begin
            free_filp (filp);
            goto _Exit;
           end;
dt_blk : if validate_blkmayor (tmp^.rmayor) then filp^.f_op := blk_dev[tmp^.rmayor].fops
          else
           begin
            free_filp (filp);
            goto _exit;
           end;
else  filp^.f_op := tmp^.op^.default_file_ops ;
end;

filp^.f_flags := flags ;
filp^.f_mode := mode ;
filp^.f_pos := 0 ;
filp^.inodo := tmp ;

{se llamara al procedimiento del driver que lo abrira!!}
if filp_open (filp) = -1 then
 begin
  free_filp (filp);
  goto _exit;
  end else
      begin
       clear_errno ;
       exit(nr_filp (filp));
      end;

_exit :
put_dentry (tmp^.i_dentry);
exit(0);

end;


{ * Sys_Rename :                                                        *
  *                                                                     *
  * path : Puntero a la ruta de archivo                                 *
  * name : nuevo nombre                                                 *
  *                                                                     *
  * Implementacion de la llamada rename                                 *
  *                                                                     *
  ***********************************************************************
}
function sys_rename (path , name : pchar ) : dword ;cdecl;[public , alias :'SYS_RENAME'];
var tmp : p_inode_t ;
    dt : dentry ;
begin

clear_errno;

{se valida el tama¤o de la ruta}
if validate_path (path) then else exit(-1);

{es traido el nombre}
pcharcopy (name,dt.name);

dt.len := dword(dt.name[0]);

{se trae el inodo}
tmp := name_i (path);

set_errno := -ENOENT;

if tmp = nil then exit(-1);


Inode_Lock (@tmp^.wait_on_inode);

{se llama al handler del driver}
if tmp^.op^.rename (tmp^.i_dentry , @dt) = -1 then
 begin
  Inode_unlock (@tmp^.wait_on_inode);
  put_dentry (tmp^.i_dentry);
  exit(-1)
  end
  else
   begin
    {se actualiza el nombre en el cache!!}
    tmp^.i_dentry^.name := dt.name ;

    put_dentry (tmp^.i_dentry);
    exit(0);
   end;

end;




{ * Sys_Close :                                                           *
  *                                                                       *
  * File_desc : Descriptor del archivo                                    *
  *                                                                       *
  * Este proc. se encarga de cerrar una archivo , liberando de la memoria *
  * su INODE y liberando la entrada en la tabla de archivos               *
  *                                                                       *
  *************************************************************************
  }
procedure sys_close (File_desc:dword) ; cdecl ; [public , alias : 'SYS_CLOSE'];
begin

If (file_desc > 32) or (file_desc = 0 ) then exit;

If Tarea_Actual^.Archivos[File_desc].f_op = nil then exit;

Tarea_Actual^.Archivos[file_desc].f_op := nil ;
Put_dentry (Tarea_Actual^.Archivos[file_desc].inodo^.i_dentry);
end;





{ * Sys_Chmod :                                                     *
  *                                                                 *
  * path : Ruta del archivo                                         *
  * Modo : Nuevo modo del archivo                                   *
  * Devuelve : 0 si fuer correcto o <> 0 sino                       *
  *                                                                 *
  * Llamada al sistema que cambia los bits EWR de un archivo dado   *
  *                                                                 *
  *******************************************************************
}
function sys_chmod ( path : pchar ; flags : dword ) : dword ; cdecl ; [public , alias :'SYS_CHMOD'];
var tmp : p_inode_t;
begin

tmp := name_i(path);

If tmp=nil then
 begin
  set_errno := -ENOENT ;
  exit(-1);
 end;

{el limpiado por posibles bit falsos}
flags := flags and %111;

Inode_Lock (@tmp^.wait_on_inode);

tmp^.flags := flags ;

{esta en la lista para enviar a disco}
mark_inode_dirty (tmp);

Inode_Unlock (@tmp^.wait_on_inode);

put_dentry (tmp^.i_dentry);

clear_errno ;

exit(0);

end;






{ * Sys_Stat :                                                         *
  *                                                                    *
  * path : Ruta al archivo                                             *
  * buffer : Lugar donde sera copiado el inodo                         *
  * Devuelve : 0 si fue correcto o <> 0 sino                           *
  *                                                                    *
  * Esta llamada al sistema devuelve la informacion guardada dentro de *
  * un inodo de un archivo dado                                        *
  *                                                                    *
  **********************************************************************
}

function sys_stat ( path : pchar ; buffer : pointer ) : dword ; cdecl;[public , alias :'SYS_STAT'];
var tmp : p_inode_t;
begin

tmp := name_i(path);

{Esto es importante puesto que puede ocacionar la escritura}
{de areas de codigo del sistema}


If buffer < pointer(High_Memory) then
 begin
  set_errno := -EFAULT ;
  exit(-1);
 end;

If (tmp = nil) then
 begin
  set_errno := -ENOENT ;
  exit(-1);
 end;

Inode_lock (@tmp^.wait_on_inode);
memcopy(tmp,buffer,sizeof(inode_t));
Inode_unlock (@tmp^.wait_on_inode);

put_dentry(tmp^.i_dentry);

clear_errno ;

exit(0);

end;






{ * Sys_Utime :                                                           *
  *                                                                       *
  * Path : Puntero a la cadena donde se encuentra la ruta al archivo      *
  * times : Puntero a los tiempos de ultimo acceso y modificacion del     *
  * inodo                                                                 *
  * Retorno : 0 si fue correcto o -1 si no                                *
  *                                                                       *
  * Llamada al sistema que modifica los tiempos de acceso y modificacion  *
  * de un archivo dado                                                    *
  *                                                                       *
  *************************************************************************
}
function sys_utime ( path : pchar ; times : p_utimbuf ) : dword ;cdecl ; [ public , alias : 'SYS_UTIME'];
var tmp : p_inode_t ;
begin

tmp := name_i(path);

If tmp = nil then
 begin
  set_errno := -ENOENT ;
  exit(-1);
 end;

{el puntero deve estar en la zona de usuario}
If (times < pointer(High_Memory)) then
 begin
  set_errno := -EFAULT ;
  exit(-1);
 end;

Inode_lock (@tmp^.wait_on_inode);
tmp^.atime := times^.actime ;
tmp^.mtime := times^.modtime ;
Inode_unlock (@tmp^.wait_on_inode);

put_dentry(tmp^.i_dentry);

clear_errno ;

exit(0);
end;



{ * Sys_chdir :                                                         *
  *                                                                     *
  * path : Puntero a ruta del nuevo dir                                 *
  * retorno : 0 si ok o -1 si falla                                     *
  *                                                                     *
  * Implementacion de la llamada al sistema que cambia el directorio    *
  * actual de  trabajo                                                  *
  *                                                                     *
  ***********************************************************************
}
function sys_chdir(path : pchar) : dword ; cdecl ; [public , alias :'SYS_CHDIR'];
var tmp : p_inode_t ;
begin
tmp := name_i (path);

if (tmp = nil) then
 begin
  set_Errno := -ENOENT ;
  exit(-1);
 end;

{si o si deve ser un dir}
if not(Is_Dir (tmp)) then
 begin
  put_dentry (tmp^.i_dentry);
  set_errno := -ENOTDIR ;
  exit(-1);
 end;

{se devuelve el q estaba antes}
put_dentry (Tarea_Actual^.cwd^.i_dentry);

Tarea_Actual^.cwd := tmp ;

clear_errno;

exit(0);
end;


{ * Sys_rmdir :                                                         *
  *                                                                     *
  * path : ruta al archivo o directorio                                 *
  * devuelve : 0 si ok o -1 si falla                                    *
  *                                                                     *
  * Funcion que elimina un archivo o directorio pero este debera estar  *
  * vacio                                                               *
  *                                                                     *
  ***********************************************************************
}
function sys_rmdir (path : pchar ) : dword ; cdecl ; [public , alias :'SYS_RMDIR'];
var tmps , tmpd : p_inode_t ;
begin

set_errno := -ENOENT ;

if validate_path (path) then else exit(-1);

{ aqui se encuentra el error!!! }
{ inodo donde se encuentra el archivo }
tmps := last_dir (path);

if (tmps = nil) then exit(-1) ;

{ dentry del archivo }
tmpd := name_i (path) ;

if tmpd = nil then
 begin
  put_dentry (tmps^.i_dentry);
  exit(-1);
 end;

 { el dentry puede estar siendo utilizado o puede contener enlaces dentro}
 { del arbol de nombres }

 { nadie mas trabajara con estos inodos }
 Inode_Lock (@tmpd^.wait_on_inode);
 Inode_Lock (@tmps^.wait_on_inode);


 if (tmpd^.i_dentry^.count > 1 ) or (tmpd^.i_dentry^.l_count <> 0) then
  begin
   set_errno := -EBUSY ;

   inode_unlock (@tmpd^.wait_on_inode);
   inode_unlock (@tmps^.wait_on_inode);
   put_dentry (tmpd^.i_dentry);
   put_dentry (tmps^.i_dentry);

   exit(-1);
  end;

  { es llamada al controlador del driver par que q quite }
  { sus estructuras internas referidas al inodo }

  if (tmps^.op^.rmdir (tmps,tmpd^.i_dentry) = -1) then
   begin
    set_errno := -EAGAIN ;

    inode_unlock (@tmps^.wait_on_inode);
    inode_unlock (@tmpd^.wait_on_inode);

    put_dentry (tmps^.i_dentry);
    put_dentry (tmpd^.i_dentry);
    exit(-1);
   end
    else
     begin

     { se libera la estructura dentro del cache de nombres }
     free_dentry (tmpd^.i_dentry) ;

     inode_unlock (@tmps^.wait_on_inode);

     { se quita del buffer de inodos }
     Invalidate_Inode (tmpd) ;

     put_dentry (tmps^.i_dentry);

     exit(0);
     end;


end;




{ * Clone_Filedesc :                                            *
  *                                                             *
  * pfile_p  : descriptor de origen                             *
  * pfile_c  : descriptor de destino                            *
  *                                                             *
  * procedimiento que duplica un descriptor de archivo          *
  *                                                             *
  ***************************************************************
}
procedure clone_filedesc (pfile_p , pfile_c : p_file_t ) ; [public , alias :'CLONE_FILEDESC'];
begin
pfile_c^ := pfile_p^;

if (nr_filp(pfile_c) = 2 )  or (nr_filp(pfile_c)= 1) then else
pfile_p^.inodo^.i_dentry^.count += 1;

end;


end.
