unit files;

{ * Files :                                                             *
  *                                                                     *
  * Unidad que se encarga de lectura y escritura de archivos sobre      *
  * discos con fat12                                                    *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 20 / 07 / 2005 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************
}



interface



{$I ../../Include/Toro/procesos.inc}
{$I ../../Include/Toro/buffer.inc}
{$I ../../Include/Toro/mount.inc}
{$I ../../Include/Head/buffer.h}
{$I ../../Include/Head/asm.h}
{$I ../../Include/Head/inodes.h}
{$I ../../Include/Head/dcache.h}
{$I ../../Include/Head/open.h}
{$I ../../Include/Head/procesos.h}
{$I ../../Include/Head/itimer.h}

{$I ../../Include/Head/scheduler.h}
{$I ../../Include/Head/read_write.h}
{$I ../../Include/Head/devices.h}
{$I ../../Include/Head/printk_.h}
{$I ../../Include/Head/malloc.h}
{$I ../../Include/Toro/fat12fs/fat12.inc}
{$I ../../Include/Head/fat12fs/inodes.h}
{$I ../../Include/Head/fat12fs/super.h}
{$I ../../Include/Head/fat12fs/misc.h}

implementation

{$I ../../Include/Head/string.h}
{$I ../../Include/Head/lock.h}




{ * Fat_Read_File :                                                     *
  *                                                                     *
  * Fichero : Puntero al descriptor de archivo                          *
  * cont : contador                                                     *
  * buff : puntero donde sera copiado                                   *
  *                                                                     *
  * Realiza la lectura de  archivo en una particion fat                 *
  *                                                                     *
  ***********************************************************************
}
function fat_read_file ( fichero : p_file_t ; cont : dword ; buff : pointer ) : dword ;[public , alias :'FAT_READ_FILE'];
var iniblk,inioff ,count,next_clus ,next_sector, ret ,cnt,blk: dword ;
    tmp : pfat_inode_cache ;
    bh : p_buffer_head ;
     k :dword ;
begin

{se busca la entrada en el cache de inodos -fat}
tmp := find_in_cache (fichero^.inodo^.ino , fichero^.inodo^.sb);

{comienzo de la lectura }
iniblk := fichero^.f_pos div fichero^.inodo^.blksize ;
inioff := fichero^.f_pos mod fichero^.inodo^.blksize;


{la lectura sobrepasara el limite}
if (fichero^.f_pos + cont ) > fichero^.inodo^.size then
 begin
  set_errno := -EEOF ;
  cont := fichero^.inodo^.size - fichero^.f_pos ;
 end;

{primer cluster}
next_clus := tmp^.dir_entry^.entradafat + 31 ;

if iniblk = 0 then next_sector := next_clus
else
 begin
  {me devo posicionar sobre el verdadero bloque}
  for ret := next_clus to (next_clus + iniblk - 1 ) do
   begin
   next_sector := get_sector_fat (fichero^.inodo^ .sb,ret);
   if (next_sector = last_sector) then
   {sector no presente}
    begin
     set_errno := -EEOF ;
     exit(0);
    end;
   end;
end;

 cnt := cont ;

 {comienza la transferencia}
 repeat
 bh := get_block (fichero^.inodo^.mayor,fichero^.inodo^.menor , next_sector , fichero^.inodo^.blksize);

 if bh =nil then break ;


 if (cnt > fichero^.inodo^.blksize) then
  begin
   memcopy (bh^.data+inioff,buff,fichero^.inodo^.blksize);
   fichero^.f_pos += fichero^.inodo^.blksize ;
   inioff := 0 ;
   cnt -= fichero^.inodo^.blksize ;
   buff += fichero^.inodo^.blksize ;
  end
   else
    begin
    memcopy (bh^.data+inioff,buff,cnt);
    inioff := 0 ;
    fichero^.f_pos += cnt;
    cnt := 0 ;
   end;

 put_block (bh);
 next_sector := get_sector_fat (fichero^.inodo^.sb,next_sector);

 {final del archivo}
 if next_sector = last_sector then
  begin
   set_errno := -EEOF ;
   break;
   end;

 until (cnt = 0 )  ;

 exit(cont - cnt);

 end;


{ * Fat_Readdir :                                                       *
  *                                                                     *
  * Fichero : puntero a un descriptor de file                           *
  * buffer : puntero a una estructura readdir                           *
  *                                                                     *
  * Esta funcion es la implementacion de readdir leyendo una estructura *
  * del tipo readdir  y se incrementa en 1 la posicion del file         *
  *                                                                     *
  ***********************************************************************
}
function fat_readdir (fichero : p_file_t ; buffer : pointer ) : dword ;[public , alias :'FAT_READDIR'];
var next_sector, cont ,dircount,rootsec: dword ;
    tmp :pfat_inode_cache ;
    preaddir  , dreaddir: preaddir_entry ;
    dir : pdirectory_entry ;
    dir_long : pvfatdirectory_entry ;
    lgcount : dword ;
    bh : p_buffer_head ;

label _eof  , _readdir_root , _exit ;
begin

dircount := 0;
dir_long := nil ;
lgcount := 0 ;

{deve ser un dirrectorio!!!}
if fichero^.inodo^.mode <> dt_dir then exit(0);

{este deve ser tratado de forma especial}
if fichero^.inodo^.ino = 1 then
 begin
  if fichero^.f_pos = 208 then goto _eof ;
  next_sector := 19;
  goto _readdir_root;
 end;

 {la entrada se realizara sobre un directorio real}
 tmp := find_in_cache (fichero^.inodo^.ino,fichero^.inodo^.sb) ;

 next_sector := tmp^.dir_entry^.entradafat + 31 ;

 {buscare por todos los sectores}
 while (next_sector <> last_sector) do
  begin

  bh := get_block (fichero^.inodo^.mayor,fichero^.inodo^.menor,next_sector,fichero^.inodo^.blksize);

  if bh = nil then
   begin
    set_errno := -EIO ;
    exit(0);
   end;

  dir := bh^.data ;

  {se busca por todo el bloque}
   for cont := 1 to (512 div sizeof(directory_entry)) do
    begin

    case dir^.nombre[1] of
    #0 : begin
         put_block (bh);
         goto _eof ;
         end;
    #$E5 : lgcount := 0 ;
    else
      begin
        if dir^.atributos = $0F then lgcount += 1
         else
           begin
            if dircount = fichero^.f_pos then goto _exit;
            dircount += 1;
            lgcount := 0 ;
           end;
      end;
    end;

    dir += 1;
    end;

  lgcount := 0 ;
  put_block (bh);
  next_sector := get_sector_fat (fichero^.inodo^.sb,next_sector);
  end;

  {no hay nada???}
  goto _eof ;


  {la lectura se realiza sobre el inodo root}
 _readdir_root :

 {la lectura es sobre el dir root}
 for rootsec := 19 to 32 do
  begin

  bh := get_block (fichero^.inodo^.mayor , fichero^.inodo^.menor ,rootsec,fichero^.inodo^.blksize);

  {error del hard}
  if bh = nil then
   begin
    set_errno := -EIO ;
    exit(0);
   end;

   dir := bh^.data ;

   {se busca por todo el bloque}
   for cont := 1 to (512 div sizeof(directory_entry)) do
    begin

     { se evalua la entrada }
     case dir^.nombre[1] of
     #0 : begin
           put_block (bh);
           goto _eof ;
          end;
     #$E5 : lgcount := 0;
     else
      begin

        { es una entrada de nombre largo ?? }
        if dir^.atributos = $0F then lgcount += 1
         else
          begin
           { estoy sobre el dir ?? }
           if dircount = fichero^.f_pos then goto _exit;
           dircount += 1;
           lgcount := 0 ;
          end;
      end;
    end;

    dir += 1;
  end;

  lgcount := 0 ;
  put_block (bh);
  end;

  {final de archivo}
  goto _eof ;

 {chauchas}
 _exit :

 preaddir := buffer ;
 preaddir^.name := '' ;


 if lgcount > 0 then
  begin

  { se traen todas las entradas de nombre largo }
  dir_long := pointer(dir) ;

  for cont := 0 to (lgcount-1) do
   begin
    dir_long -= 1 ;
    unicode_to_unix (dir_long,preaddir^.name);
   end;

 end else  unix_name(@dir^.nombre[1],preaddir^.name);

 preaddir^.ino := dir^.entradafat ;

 fichero^.f_pos += 1;

 put_block (bh);
 exit(1);

 {salida por final}
 _eof :
 set_errno := -EEOF ;
 preaddir := buffer ;
 preaddir^.name[1] := #0 ;
 exit(0);
 end;



{ * Fat_file_seek :                                                     *
  *                                                                     *
  * fichero : Puntero a un descriptor de archivo                        *
  * whence : Algoritmo usado                                            *
  * offset : nueva posicion sobre el archivo                            *
  * Retorno : nueva posicion del archivo                                *
  *                                                                     *
  * Realiza la posicionamiento sobre un archivo regular sobre fat       *
  *                                                                     *
  ***********************************************************************
}
function fat_file_seek (fichero : p_file_t ; whence , offset : dword ) : dword ;[public , alias : 'FAT_FILE_SEEK'];
begin

case whence of
seek_set : if (offset > fichero^.inodo^.size) then exit(0) else fichero^.f_pos  := offset ;
seek_cur : if (offset + fichero^.f_pos) > (fichero^.inodo^.size) then exit(0) else fichero^.f_pos += offset ;
seek_eof : fichero^.f_pos := fichero^.inodo^.size ;
else exit(0);
end;

exit(fichero^.f_pos);
end;


{ * Fat_file_create :                                                   *
  *                                                                     *
  * ino : puntero a un inodo                                            *
  * dentry : posee el nombre del fichero a crear                        *
  * tm : no utilizado                                                   *
  *                                                                     *
  * Funcion que crea un fichero sobre el inodo-fat dado                 *
  * dentry solo continue el nombre del fichero y el driver deve limitar *
  * se a trabajar con el campo name y nada mas                          *
  *                                                                     *
  ***********************************************************************
}
function fat_file_create ( ino : p_inode_t ; dentry : p_dentry ; tm : dword ) : dword ; [public , alias :'FAT_FILE_CREATE'];
var dent : directory_entry ;
    cluster : word ;
    ret : dword ;
begin

{es traido el nombre a un formato msdos}
fat_name (dentry^.name , @dent.nombre[1]);

for cluster := 1 to 10 do dent.reservado[cluster] := 0 ;

dent.atributos := attr_archivo ;

cluster := get_free_cluster(ino^.sb);

if cluster = 0 then exit(-1) else dent.entradafat := cluster - 31 ;

dent.size := 0 ;

{error aqui}
date_unix2dos (get_datetime,dent.mtime,dent.mdate);

if ino^.ino = 1 then ret := add_rootentry (ino,@dent) else ret := add_direntry (ino,@dent);

{hubo un error al crear la entrada , devo liberar el cluster}
if ret = -1 then
 begin
  free_cluster (ino^.sb,cluster);
  exit(-1);
 end;
exit(0);
end;


{ * Fat_file_write :                                                    *
  *                                                                     *
  * fichero : Puntero a un descriptor de fichero                        *
  * count : contador                                                    *
  * buff : no quiero explicarlo                                         *
  *                                                                     *
  * Realiza la escritura de un archivo                                  *
  *                                                                     *
  ***********************************************************************
}
function fat_file_write (fichero  :p_file_t ; count : dword ; buff : pointer ) : dword ;[public , alias :'FAT_FILE_WRITE'];
var tmp : pfat_inode_cache ;
    iniblk,inioff ,next_clus , next_sector,ret,cnt: dword ;
    bh : p_buffer_head;
begin

{es solicitado el bloque}
tmp := find_in_cache (fichero^.inodo^.ino , fichero^.inodo^.sb);

iniblk := fichero^.f_pos div fichero^.inodo^.blksize;
inioff := fichero^.f_pos mod fichero^.inodo^.blksize;

{primer cluster}
next_clus := tmp^.dir_entry^.entradafat + 31 ;


if iniblk = 0 then next_sector := next_clus
else
 begin

  {me devo posicionar sobre el verdadero bloque}
  for ret := next_clus to (next_clus + iniblk - 1 ) do
   begin
   next_sector := get_sector_fat (fichero^.inodo^.sb,ret);

   if next_sector = last_sector then
    begin
     next_sector := add_free_cluster (fichero^.inodo);
     if next_sector = 0 then exit(0) ;
    end;
   end;

 end;

 cnt := count ;

 {comienza la transferencia}
 repeat

 {final del archivo}
 if next_sector = last_sector then
  begin
    {se agrega un cluster}
    next_sector := add_free_cluster (fichero^.inodo);
    if next_sector = 0 then break;
   end;

 bh := get_block (fichero^.inodo^.mayor,fichero^.inodo^.menor , next_sector , fichero^.inodo^.blksize);

 if bh =nil then break ;


 if (cnt > fichero^.inodo^.blksize) then
  begin
   memcopy (buff,bh^.data+inioff,fichero^.inodo^.blksize-inioff);
   fichero^.f_pos += fichero^.inodo^.blksize-inioff ;
   inioff := 0 ;
   cnt -= fichero^.inodo^.blksize -inioff;
   buff += fichero^.inodo^.blksize - inioff ;
  end
   else
    begin
    memcopy (buff,bh^.data+inioff,cnt);
    inioff := 0 ;
    fichero^.f_pos += cnt;
    cnt := 0 ;
   end;

 mark_buffer_dirty (bh);
 put_block (bh);

 next_sector := get_sector_fat (fichero^.inodo^.sb,next_sector);

 until (cnt = 0 )  ;


 {si se supero el tama¤o de archivo se deve actualizar su tama¤o}
 if fichero^.f_pos > fichero^.inodo^.size then
  begin
   fichero^.inodo^.size := fichero^.f_pos ;
   tmp^.dir_entry^.size := fichero^.f_pos;
  end;
 date_unix2dos (get_datetime,tmp^.dir_entry^.mtime,tmp^.dir_entry^.mdate);

 {el size es modificado por lo tanto se marca como sucio}
 mark_inode_dirty (fichero^.inodo);

 exit(count - cnt);

end;


{ * Fat_File_Truncate :                                                      *
  *                                                                          *
  * ino : puntero a un inodo                                                 *
  *                                                                          *
  * trunca el tama¤o de un archivo a 0 , ciudado que los clusters no son     *
  * liberados sino que solo es cambiado el tama¤o de la entrada a 0          *
  *                                                                          *
  ****************************************************************************
}
procedure fat_file_truncate ( ino : p_inode_t ) ;[public , alias : 'FAT_FILE_TRUNCATE'];
var tmp : pfat_inode_cache ;
begin
tmp := find_in_cache (ino^.ino,ino^.sb);

{es truncado su tama¤o a 0}
tmp^.dir_entry^.size := 0 ;
ino^.size := 0 ;

{es marcado como sucio}
mark_inode_dirty (ino);
end;





end.
