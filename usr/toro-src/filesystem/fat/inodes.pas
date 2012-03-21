Unit fat_inodes;


{ * Fat_Inodes :                                                        *
  *                                                                     *
  * Unidad que realiza las funciones de manejo sobre los inodos-fat     *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 27 / 07 / 2005 : Primera Version                                    *
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
{$I ../../Include/Head/scheduler.h}
{$I ../../Include/Head/read_write.h}
{$I ../../Include/Head/devices.h}
{$I ../../Include/Head/printk_.h}
{$I ../../Include/Head/malloc.h}
{$I ../../Include/Toro/fat12fs/fat12.inc}
{$I ../../Include/Head/fat12fs/misc.h}
{$I ../../Include/Head/super.h}

{$define Use_Tail }
{$define nodo_struct := pfat_inode_cache}
{$define next_nodo := next_ino_cache}
{$define prev_nodo := prev_ino_cache}

{$define Push_Inode := Push_Node }
{$define Pop_Inode  := Pop_Node }

{define debug}

var    fat_inode_op : inode_operations;

implementation

{$I ../../Include/Head/string.h}
{$I ../../Include/Head/list.h}
{$I ../../Include/Head/lock.h}

{ * procedimientos para quitar y poner los inodos en la tabla hash * }

procedure Inode_Hash_Push ( ino : pfat_inode_cache ) ;inline;
var tmp : dword ;
begin
tmp := ino^.ino mod Max_Inode_Hash ;
push_inode (ino,ino^.sb^.hash_ino^[tmp]);
end;



procedure Inode_Hash_Pop ( ino : pfat_inode_cache) ; inline ;
var tmp : dword ;
begin
tmp := ino^.ino mod Max_Inode_hash ;
pop_inode (ino,ino^.sb^.hash_ino^[tmp]);
end;





{ * Alloc_Inode_Fat :                                                   *
  *                                                                     *
  * entry : Puntero a una estructura directorio fat                     *
  * bh : puntero al buffer head del dir                                 *
  *                                                                     *
  * Esta funcion crea la abstraccion entre el vfs y la fat , cada       *
  * inodo de fatfs posee una entrada aqui  , el campo nr_inodo es solo  *
  * un numero id. la cola ligada del cache de fat-inode                 *
  *                                                                     *
  ***********************************************************************
}
function alloc_inode_fat ( sb : psb_fat ; entry : pdirectory_entry ; bh : p_buffer_head ) :pfat_inode_cache;
var tmp : pfat_inode_cache ;
begin

tmp := kmalloc (sizeof(fat_inode_cache));

{no memoria}
if tmp = nil then exit(nil);

{se crea la estructura para el cache}
tmp^.dir_entry := entry ;
tmp^.bh := bh ;
tmp^.ino := entry^.entradafat ;    {identificador de inodo}
tmp^.sb := sb ;

inode_hash_push (tmp);

exit(tmp);
end;


{ * quita de la cola ligada un buffer cache de inodo fat * }

procedure remove_inode_fat ( ino : pfat_inode_cache) ;
begin
inode_hash_pop (ino);
put_block (ino^.bh);
kfree_s (ino,sizeof(fat_inode_cache));
end;


{ * Realiza la busqueda de un inodo en el cache de inodos-fat * }

function find_in_cache ( ino : dword ; sb : p_super_block_t ) : pfat_inode_cache ;[public , alias :'FIND_IN_CACHE'];
var ino_cache : pfat_inode_cache ;
    tmp : dword ;
    sbfat : psb_fat ;
begin

{ubicacion en la tabla hash}
tmp := ino mod Max_Inode_hash ;

sbfat := sb^.driver_space ;

if sbfat^.hash_ino^[tmp]^.ino = ino then exit(sbfat^.hash_ino^[tmp]);

ino_cache := sbfat^.hash_ino^[tmp];

if ino_cache = nil then exit(nil);

{se buscara por toda la cola un inodo con ese id }
repeat

if ino_cache^.ino = ino then exit(ino_cache);
ino_cache := ino_cache^.next_ino_cache ;
until (ino_cache = sbfat^.hash_ino^[tmp]);

exit(nil);
end;




{ * Fat_inode_Lookup :                                                  *
  *                                                                     *
  * ino : puntero a un inodo                                            *
  * dt : entrada buscada                                                *
  *                                                                     *
  * Realiza la busqueda de una entrada dentro de un inodo-fat dir       *
  *                                                                     *
  ***********************************************************************
}
function fat_inode_lookup (ino : p_inode_t ; dt : p_dentry ) : p_dentry ;[public , alias :'FAT_INODE_LOOKUP'];
var blk , next_sector: dword ;
    bh : p_buffer_head ;
    pdir : pdirectory_entry ;
    fat_entry : array[1..255] of char;
    ino_fat , tmp: pfat_inode_cache;

label _load_ino , find_in_dir ;
begin

fillbyte(@fat_entry,sizeof(fat_entry),32);
memcopy (@dt^.name[1],@fat_entry,byte(dt^.name[0]));

{ esto puede traer problemas }
strupper (@fat_entry[1]);

{se busca en root???}
if ino^.ino = 1 then else goto  find_in_dir ;

{se buscara por todo el root}
for blk := 19 to 32  do
 begin

   {este acceso es rapido puesto que estan en cache}
   bh := get_block (ino^.mayor,ino^.menor,blk,512);

   if bh = nil then exit(nil);

   {se busca dentro del dir}
   find_rootdir (bh,@fat_entry,pdir);

   {se encontro la entrada??}
   if pdir <> nil then goto _load_ino;

   put_block (bh);
  end;

exit (nil);

{la entrada se encuentra dentro de un dir}
find_in_dir :

tmp := find_in_cache (ino^.ino,ino^.sb) ;

{primer sector en el area de data}
next_sector := tmp^.dir_entry^.entradafat + 31 ;

while (next_sector <> last_sector) do
 begin
  bh := get_block (ino^.mayor,ino^.menor,next_sector,ino^.blksize);

  if bh = nil then exit(nil);


  {se realiza la busqueda dentro del dir}
  if  find_dir (bh,@fat_entry,pdir) = -1 then
   begin
   {el -1 indica fin de dir y 0 que no se encontro pero no se llego al fin}
   {del dir}
   put_block (bh);
   exit(nil)
   end else if pdir <> nil then goto _load_ino;

  put_block (bh);

  next_sector := get_sector_fat (ino^.sb,next_sector);
 end;

exit(nil);

_load_ino :

 {se crea la entrada en el cache de inodos-fat}
 ino_fat := alloc_inode_fat (ino^.sb^.driver_space,pdir,bh);

 {seguro no hay memoria!!!}
 if ino_fat = nil then
  begin
   put_block (bh);
   exit(nil);
  end;

 {se llama al kernel y se devuelve una estructura de inodos que ya}
 {habia creado previamente}
 dt^.ino := get_inode (ino^.sb,ino_fat^.ino) ;

 exit(dt);
end;




{ * Fat_Read_Inode :                                                     *
  *                                                                      *
  * ino : Puntero a un inodo                                             *
  *                                                                      *
  * Realiza la lectura de un inodo del cache de inodos-fat               *
  *                                                                      *
  ************************************************************************
}
procedure fat_read_inode (ino : p_inode_t) ;[public , alias :'FAT_READ_INODE'];
var ino_cache : pfat_inode_cache ;
begin

{el inodo root es tratado de forma especial}
if ino^.ino = 1 then
 begin
 ino^.blocks := 14 ;
 ino^.size := 14 * 512 ;
 ino^.flags := I_RO or I_WO or I_XO;
 ino^.mode := dt_dir ;
 ino^.state := 0 ;
 ino^.op := @fat_inode_op;
 exit;
end;

{supuestamente un lookup ya cargo una entrada dir para ese inodo}
ino_cache := find_in_cache (ino^.ino , ino^.sb);

if ino_cache = nil then
 begin
  ino^.state := i_dirty ;
  exit;
 end;

{los archivos de sistema son especiales}
if (ino_cache^.dir_entry^.atributos and attr_system = attr_system ) then
   begin

    { implementacion de los inodos de dispositivos }

     { dev de caracteres }
    if (ino_cache^.dir_entry^.atributos and attr_chr = attr_chr) then
     ino^.mode := dt_chr
      { dev de bloque }
      else if (ino_cache^.dir_entry^.atributos and attr_blk = attr_blk) then
       ino^.mode := dt_blk
       else
        begin
         printk('/VVFS/n : inode desconocido \n',[],[]);
         ino^.state := i_dirty ;
         exit;
        end;

     ino^.rmenor := ino_cache^.dir_entry^.size and $ff ;
     ino^.rmayor := (ino_cache^.dir_entry^.size shr 16 ) ;
     ino^.size := 0 ;
     ino^.blocks := 0 ;
     ino^.op := nil;
     ino^.state := 0 ;
     ino^.atime := 0 ;
     ino^.ctime := 0  ;
     ino^.mtime := date_dos2unix (ino_cache^.dir_entry^.mtime , ino_cache^.dir_entry^.mdate);
     ino^.dtime := 0 ;

    { proteccion al nodo de dev }
    if (ino_cache^.dir_entry^.atributos and attr_read_only = attr_read_only ) then
    ino^.flags := I_RO else ino^.flags := I_RO or I_WO or I_XO ;

    exit
   end
  else
    begin

    {si hay es un archivo regular }
    if (ino_cache^.dir_entry^.atributos and attr_read_only = attr_read_only ) then
    ino^.flags := I_RO else ino^.flags := I_RO or I_WO or I_XO ;


 {solo existen ficheros y directorio}
  if (ino_cache^.dir_entry^.atributos and attr_directory = attr_directory) then
   begin
    ino^.mode := dt_dir;
    ino^.size := 0 ;

    {los dir. no poseen tama¤o}
    ino^.blocks := 0 ;
    end
    else
     begin
      ino^.mode := dt_reg ;
      ino^.size := ino_cache^.dir_entry^.size ;
      ino^.blocks := ino^.size div ino^.blksize ;
     end;

ino^.op := @fat_inode_op;
ino^.state := 0 ;

ino^.atime := 0 ;
ino^.ctime := 0  ;
ino^.mtime := date_dos2unix (ino_cache^.dir_entry^.mtime , ino_cache^.dir_entry^.mdate);
ino^.dtime := 0 ;

end;

end;



{ * Fat_Write_Inode :                                                       *
  *                                                                         *
  * ino : puntero a un ino de vfs                                           *
  *                                                                         *
  * Realiza la escritura de un inodo de vfs a fat                           *
  *                                                                         *
  ***************************************************************************
}
procedure fat_write_inode ( ino : p_inode_t ) ; [public , alias :'FAT_WRITE_INODE'];
var tmp : pfat_inode_cache ;
begin

tmp := find_in_cache (ino^.ino , ino^.sb);

{grave error}
if tmp = nil then Panic ('/VVFS/n : fat12fs se hace write a un buffer no pedido \n');

{los atributos pueden ser modificados con chmod}
if (ino^.flags and I_RO = I_RO ) and (ino^.flags and I_WO <> I_WO) then
 tmp^.dir_entry^.atributos := tmp^.dir_entry^.atributos or attr_read_only ;

{es un bloque sucio!!!!}
mark_buffer_dirty (tmp^.bh);

ino^.state := 0 ;
end;



{ * Fat_Delete_Inode :                                                  *
  *                                                                     *
  * Funcion llamada por el sistema cuando deve quitar del buffer        *
  * un inodo  , la memoria es liberada                                  *
  *                                                                     *
  ***********************************************************************
}
procedure fat_delete_inode ( ino : p_inode_t ) ; [public ,alias : 'FAT_DELETE_INODE'];
var tmp : pfat_inode_cache ;
begin

tmp := find_in_cache (ino^.ino , ino^.sb) ;

{grave error}
if tmp = nil then Panic ('/VVFS/n : fat12fs se quita un buffer no pedido \n');

{se quita del sitema el inodo}
remove_inode_fat (tmp);

end;



{ * fat_put_inode : funcion no utilizada por fat                * }

procedure fat_put_inode (ino : p_inode_t) ; [public , alias :'FAT_PUT_INODE'];
begin
{$IFDEF debug}
printk('/Vfat_put_inode/n : No implementado en fat12fs\n',[],[]);
{$ENDIF}
end;




{ * Fat_mkdir :                                                              *
  *                                                                          *
  * ino : puntero a un inodo                                                 *
  * dentry : solo posee el nombre del nuevo fichero                          *
  * mode: proteccion    , igual ino.flags                                    *
  *                                                                          *
  * Se encarga de crear un directorio                                        *
  *                                                                          *
  ****************************************************************************
}
function fat_mkdir (ino : p_inode_t ; dentry : p_dentry ; mode : dword ) : dword ;[public , alias : 'FAT_MKDIR'];
var dent : directory_entry ;
    pdir : pdirectory_entry ;
    tmp,cluster,ret : dword ;
    bh : p_buffer_head ;
    inofat : pfat_inode_cache;

label _fault;
begin

if ino^.ino = 1 then  inofat := nil else inofat := find_in_cache (ino^.ino , ino^.sb);

fillbyte(@dent.nombre[1],11,32);

fat_name (dentry^.name,@dent.nombre[1]);

for tmp := 1 to 10 do dent.reservado[tmp] := 0 ;

dent.atributos := attr_directory ;

if (mode and I_RO = I_RO ) and (mode and I_WO <> I_WO) then dent.atributos := dent.atributos or attr_read_only ;

cluster := get_free_cluster(ino^.sb) ;

if cluster = 0 then exit(-1) else dent.entradafat := cluster - 31 ;

dent.size := 0 ;

date_unix2dos (get_datetime,dent.mtime,dent.mdate);

if ino^.ino = 1 then ret := add_rootentry (ino,@dent) else ret:= add_direntry (ino,@dent);

if ret = -1 then goto _fault ;

{aca no puedo hacer una add_direntry para las entradas "." y ".." puesto }
{que deveria hacer un get_inode y este no resultaria}

bh := get_block (ino^.mayor,ino^.menor,cluster,ino^.blksize);

if bh = nil then goto _fault;

pdir := bh^.data ;

{directorios obligatorios}
dent.nombre := first_dir ;
pdir^ := dent ;

pdir += 1;

dent.nombre := second_dir ;

{es sobre el root!!!}
if inofat = nil then dent.entradafat := 0
 else
  begin
   dent.entradafat := inofat^.dir_entry^.entradafat;
   dent.mtime := inofat^.dir_entry^.mtime;
   dent.mdate := inofat^.dir_entry^.mdate  ;
  end;

pdir^ := dent ;

{final del direc}
pdir += 1;
pdir^.nombre[1] := #0;

mark_buffer_dirty (bh);

put_block (bh);
exit(0);

{ah ocurrido un error grave}
_fault :

free_cluster (ino^.sb,cluster);
exit(-1);
end;



{ * Fat_mknod : Funcion no implementada en fat!!!!!!!!!!!! }

function fat_mknod (ino : p_inode_t ; dentry : p_dentry ; int , mayor , menor : dword ) : dword ; [public , alias :'FAT_MKNOD'];
var dent : directory_entry ;
    ret , tmp : dword ;
    inofat : pfat_inode_cache;

label _fault;
begin

{ el archivo es sobre root ? }
if ino^.ino = 1 then  inofat := nil else inofat := find_in_cache (ino^.ino , ino^.sb);

fat_name (dentry^.name,@dent.nombre[1]);

for tmp := 1 to 10 do dent.reservado[tmp] := 0 ;

{ asi se implementan los archivos de dispositivos }
if (mayor < Nr_blk) then dent.atributos := attr_system or attr_blk
 else if (mayor > Nr_blk) and ( mayor < Nr_chr) then dent.atributos := attr_system or attr_chr ;

{ la entrada fat contiene los numero de dev }
dent.size := (mayor shl 16) or menor ;
dent.entradafat := last_sector ;

{ proteccion al archivo }
if (int and I_RO = I_RO ) and (int and I_WO <> I_WO) then dent.atributos := dent.atributos or attr_read_only ;

date_unix2dos (get_datetime,dent.mtime,dent.mdate);

{ es agregada la entrada }
if ino^.ino = 1 then ret := add_rootentry (ino,@dent) else ret:= add_direntry (ino,@dent);

if ret = -1 then goto _fault ;

exit(0);

_fault :
exit(-1);

end;


{ * fat_rmdir :                                                         *
  *                                                                     *
  * ino : puntero a un inodo                                            *
  * dentry : puntero a una dentry del cache                             *
  *                                                                     *
  * funcion que elimina a un archivo ya se este directorio o archivo    *
  *                                                                     *
  ***********************************************************************
  }

function fat_rmdir ( ino : p_inode_t ; dentry : p_dentry ) : dword ;[public , alias : 'FAT_RMDIR'];
var tmpd,tmps : pfat_inode_cache ;
    next_sector , prev_sector , count  : dword ;
    dir : pdirectory_entry ;

label _vacio , _novacio , _nada ;

begin

printk('/Vfat_rmdir/n : funcion no implementada \n',[],[]);
exit(-1);


{ siempre debe ser un dir ino!!! }
if ino^.mode <> dt_dir then exit(-1);

{ archivo que sera eliminado }
tmpd := find_in_cache (dentry^.ino^.ino , dentry^.ino^.sb) ;

{ se debera eliminar uno por uno cada archivos para que el dir sea libre }
if (dentry^.ino^.mode = dt_dir ) and (tmpd^.dir_entry^.entradafat <> last_sector) then
 begin
  printk('/Vfatfs/n : rmdir en directorio no vacio \n',[],[]);
  exit(-1);
 end;

{ comienzo del archivo }
 next_sector := tmpd^.dir_entry^.entradafat + 31 ;

  if (dentry^.ino^.mode <> dt_dir) then
   begin


   { son liberados todos los clusters del archivo }

   while (next_sector <> last_sector) do
    begin
    prev_sector := get_sector_fat (ino^.sb,next_sector);
    free_cluster (ino^.sb,next_sector);

    next_sector := prev_sector ;
   end;


  _nada :

   dir := tmpd^.bh^.data ;

   {sera una entrada libre en el dir}
   tmpd^.dir_entry^.nombre[1] := #$e5 ;

   { debera ser escrito!! }
   mark_buffer_dirty (tmpd^.bh);

   { el directorio de donde saco la entrada esta vacio ? }
   for count := 1 to (512 div (sizeof(directory_entry))) do
    begin

    { marca de fin de dir }
    if (dir^.nombre[1] = #0 ) then goto _vacio
     else if dir^.nombre[1] <> #$e5 then goto _novacio;

     dir += 1;
    end;

  _vacio :


   { inodo donde reside el archivo eliminado }
   tmps := find_in_cache (ino^.ino,ino^.sb);


   { el bloque donde esta la entrada del archivo eliminado }
   { es el ultimo sector del dir }
   if get_sector_fat (dentry^.ino^.sb,tmpd^.bh^.bloque) = last_sector then
    begin

      { si es el unico sector del dir  y esta vacio!!}
      if (tmps^.dir_entry^.entradafat + 31  = tmpd^.bh^.bloque) then
       begin
        free_cluster (ino^.sb,tmpd^.bh^.bloque);
        tmps^.dir_entry^.entradafat := last_sector ;
        mark_buffer_dirty (tmps^.bh);

       end
        else
         begin


         next_sector := tmps^.dir_entry^.entradafat + 31;

         { voy al anteultimo sector }
         while (next_sector <>  tmpd^.bh^.bloque) do
          begin
           prev_sector := next_sector ;
           next_sector := get_sector_fat (ino^.sb,next_sector);
          end;

         put_sector_fat (dentry^.ino^.sb,prev_sector,last_sector) ;
         free_cluster (ino^.sb,prev_sector) ;

      end;
   end;

        _novacio :
        remove_inode_fat (tmpd) ;
        exit(0);

        end

         { es un directorio }
         else goto _nada ;

end;


function fat_rename (dentry , ndentry : p_dentry) : dword ; [public , alias : 'FAT_RENAME'];
begin
printk('/Vvfs/n : fat_rename funcion no implementada en fat\n',[],[]);
exit(-1);
end;



end.
