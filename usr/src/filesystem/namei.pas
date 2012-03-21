Unit namei ;


{ * Namei :                                                     *
  *                                                             *
  * Unidad encargada de la conversion de ruta a inodos a traves *
  * del cache del sistema                                       *
  *                                                             *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>  *
  * All Rights Reserved                                         *
  *                                                             *
  * Versiones :                                                 *
  *                                                             *
  * 02 / 02 / 2005 : Es modificado la func. last_dir()          *
  * 30 / 06 / 2005 : Primera version                            *
  *                                                             *
  ***************************************************************
}


interface


{$I ../include/toro/procesos.inc}
{$I ../include/toro/buffer.inc}
{$I ../include/head/buffer.h}
{$I ../include/head/asm.h}
{$I ../include/head/inodes.h}
{$I ../include/head/open.h}
{$I ../include/head/procesos.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/read_write.h}
{$I ../include/head/devices.h}
{$I ../include/head/printk_.h}
{$I ../include/head/malloc.h}
{$I ../include/head/dcache.h}


implementation

{$I ../include/head/string.h}
{$I ../include/head/lock.h}

{ * name_i :                                                    *
  *                                                             *
  * path : puntero a una ruta                                   *
  * retorno : puntero a el ultimo inodo de ruta                 *
  *                                                             *
  * Funcion que realiza la busqueda de una ruta a traves del    *
  * cache del sistema                                           *
  *                                                             *
  ***************************************************************
}
function name_i (path : pchar ) : p_inode_t ;[public , alias : 'NAME_I'];
var ini,act : p_dentry ;
    tmp : string ;
    cont : dword ;
begin

act := nil ;
cont := 1 ;

{posicion relativa de comienzo}
if path^ = '/' then
 begin
  ini := dentry_root;
  path += 1;
  end
  else ini := tarea_Actual^.cwd^.i_dentry ;

  ini^.count += 1;

while (path^ <> #0) do
 begin

   if path^ = '/' then
    begin

     {marco el final de cadena}
     tmp[0] := char(cont - 1 );

     if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

     {la busqueda solo se realiza sobre inodos dir!!}
     if (ini^.ino^.mode  <> dt_dir) then
      begin
       put_dentry (ini);
       exit (nil);
      end;

     {se pide la entrada al cache}
     act := Alloc_Entry (ini^.ino,tmp);

     put_dentry (ini);

     if act = nil then exit(nil);

     {los permisos me permiten leer??}
     if (act^.flags and I_RO <> I_RO ) then
      begin
       put_dentry(act);
       exit(nil);
      end;

     ini := act;
     path += 1;
     cont := 1 ;
     continue;
    end;

 tmp[cont] := path^;
 path += 1;
 cont += 1;

 end;


 if (path-1)^ = '/' then exit (ini^.ino)
  else
   begin

    tmp[0] := char(cont - 1);

    {es un dentry de montage??}
    if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

    if (ini^.ino^.mode <> dt_dir) then
     begin
      put_dentry (ini);
      exit(nil);
     end;


    act := Alloc_Entry (ini^.ino,tmp);

    put_dentry (ini);

    if act = nil then exit(nil);

    {se poseen permisos de lectura???}
    if (act^.flags and I_RO <> I_RO ) then
     begin
      Put_dentry (act);
      exit(nil);
    end;

    exit(act^.ino);
    end;

end;





{ * Last_dir                                                            *
  *                                                                     *
  * path : Puntero a una ruta                                           *
  * retorno : ultimo inodo accedido                                     *
  *                                                                     *
  * rastrea una ruta hasta el ultimo archivo y si este no existe devue  *
  * lve el directorio ultimo                                            *
  *                                                                     *
  ***********************************************************************
}



function last_dir (path : pchar ) : p_inode_t ;[public , alias : 'LAST_DIR'];
var ini,act : p_dentry ;
    tmp : string ;
    cont : dword ;
begin

act := nil ;
cont := 1 ;

{posicion relativa de comienzo}
if path^ = '/' then
 begin
  ini := dentry_root;
  path += 1;
  end
  else ini := tarea_Actual^.cwd^.i_dentry ;

  ini^.count += 1;

while (path^ <> #0) do
 begin

   if path^ = '/' then
    begin

     {marco el final de cadena}
     tmp[0] := char(cont - 1 );

     if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

     {la busqueda solo se realiza sobre inodos dir!!}
     if (ini^.ino^.mode  <> dt_dir) then
      begin
       ini^.parent^.count += 1;
       last_dir := ini^.parent^.ino ;
       put_dentry (ini);
       exit;
      end;

     {se pide el dentry al cache}
     act := Alloc_Entry (ini^.ino,tmp);

     if act = nil then exit(ini^.ino);

     {los permisos me permiten leer??}
     if (act^.flags and I_RO <> I_RO ) then
      begin
       put_dentry(act);
       last_dir := ini^.ino ;
      end;

     put_dentry (ini );

     ini := act;
     path += 1;
     cont := 1 ;
     continue;
    end;

 tmp[cont] := path^;
 path += 1;
 cont += 1;

 end;


 if (path-1)^ = '/' then
  begin

   {siempre sale con un dir!!}
   if (ini^.ino^.mode = dt_dir) then exit(ini^.ino)
    else
     begin
      ini^.parent^.count += 1;
      last_dir := ini^.parent^.ino ;
      put_dentry (ini);
      exit;
     end;

  end
  else
   begin

    tmp[0] := char(cont - 1);

    {es un dentry de montage??}
    if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

    if (ini^.ino^.mode <> dt_dir) then
     begin
      ini^.parent^.count += 1;
      last_dir := ini^.parent^.ino;
      put_dentry (ini);
      exit;
     end;

    {aqui se realiza todo el lookup y devuelve una entrada en el cache de nombres}
    act := Alloc_Entry (ini^.ino,tmp);

    if act = nil then exit(ini^.ino);

    {se poseen permisos de lectura???}
    if (act^.flags and I_RO <> I_RO ) then
     begin
      last_dir := ini^.ino;
      Put_dentry (act);
    end;

    put_dentry (ini);

    exit(act^.ino);
    end;

end;



end.
