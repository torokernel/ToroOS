unit super;

{ * Super :                                                             *
  *                                                                     *
  * Realiza la mantencion de los sp de fat12 y crea la abstraccion      *
  * entre el vfs y fat . Por ahora solo registra fat12  y se limita     *
  * montar una sola unidad                                              *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 27 / 07 / 2005 : Primera version .                                  *
  *                                                                     *
  *                                                                     *
  ***********************************************************************

  }


interface


{$I ../../include/toro/procesos.inc}
{$I ../../include/toro/buffer.inc}
{$I ../../include/toro/mount.inc}
{$I ../../include/head/buffer.h}
{$I ../../include/head/asm.h}
{$I ../../include/head/inodes.h}
{$I ../../include/head/dcache.h}
{$I ../../include/head/open.h}
{$I ../../include/head/procesos.h}
{$I ../../include/head/scheduler.h}
{$I ../../include/head/read_write.h}
{$I ../../include/head/devices.h}
{$I ../../include/head/printk_.h}
{$I ../../include/head/malloc.h}
{$I ../../include/toro/fat12fs/fat12.inc}
{$I ../../include/head/fat12fs/inodes.h}
{$I ../../include/head/fat12fs/files.h}


const mounted : boolean = false ;


var fat_fstype : file_system_type ;
    fat_super_op : super_operations;
    fat_file_op : file_operations ;

    {estructura temporal }
    fat : array[0..4608] of byte;


implementation

{$I ../../include/head/string.h}

{ * alloc_super_fat : crea la estrcutura de un superbloque para fat * }

function alloc_super_fat  : psb_fat ;inline;
var tmp : psb_fat ;
    ret : dword ;
begin

tmp := kmalloc (sizeof(super_fat));

if tmp = nil then exit(nil);

tmp^.hash_ino := kmalloc (4096) ;

if tmp^.hash_ino = nil then
 begin
  kfree_s (tmp,sizeof(super_fat));
  exit(nil);
 end;


{es limpiada la cola hash}
for ret := 1 to Max_Inode_Hash do tmp^.hash_ino^[ret] := nil ;

exit(tmp);
end;


{ * remove_super_fat : libera todo la memoria dentro de un descriptor de sb * }

procedure remove_super_fat ( sb : psb_fat) ;inline;
begin
kfree_s (sb^.hash_ino,4096);
kfree_s (sb,sizeof(super_fat));
end;



{ * carga toda la fat en el cache del sistema suelen ser 9 bloques * }

function cargar_fat ( sb : p_super_block_t ) : boolean ;
var cont : dword ;
    sb_fat : psb_fat ;
    bh : p_buffer_head ;
    pfat : pointer ;
label _exit ;
begin

{estructura de la super de fat}
sb_fat := sb^.driver_space ;

pfat := @fat;

{son cargados en cache los bloques pertenecientes a la fat}
{y copiados a un buffer para tenerlos de forma continua}
for cont := 1 to sb_fat^.pbpb^.bpb_fatsz16 do
 begin
 bh := get_block (sb^.mayor,sb^.menor,cont,sb_fat^.pbpb^.bpb_bytspersec) ;

 if bh = nil then goto _exit ;

 memcopy (bh^.data,pfat,sb_fat^.pbpb^.bpb_bytspersec);
 pfat += sb_fat^.pbpb^.bpb_bytspersec;
 end;

sb_fat^.pfat := @fat;
exit(true);

_exit :
printk('/Vfat12fs/n : Error al Cargar FAT12\n',[]);
exit(false);
end;


{ * carga todo el directorio root en cache * }

function cargar_rootdir ( sb : p_super_block_t ) : boolean;
var bh : p_buffer_head ;
    count : dword ;
begin

for count := 19 to 32 do
  begin
   bh := get_block (sb^.mayor,sb^.menor,count,512);
   if bh = nil then exit (false) ;
  end;

exit(true);
end;

const
 FAT12ID : pchar = 'FAT12';

{ * Fat12fs_Read_Super :                                                *
  *                                                                     *
  * sb : Puntero a un superbloque                                       *
  * Retorno : puntero al sp o nil si falla                              *
  *                                                                     *
  * Realiza la lectura de un superbloque de fat12 y carga toda la fat   *
  *                                                                     *
  ***********************************************************************
}
function fat_read_super (sb : p_super_block_t ) : p_super_block_t;
var bh , bh2 : p_buffer_head ;
    sb_fat : psb_fat ;
    ret  : dword ;
label _exit;
begin

if mounted then
 begin
  printk('/Vfatfs/n : Solo se puede montar una unidad \n',[]);
  exit(nil)
 end;

sb_fat := alloc_super_fat ;


if sb_fat = nil then exit(nil);

bh := get_block (sb^.mayor,sb^.menor,0,512);

if bh = nil then goto _exit ;

sb_fat^.pbpb := bh^.data ;

{letras magicas , por ahora solo soporto Fat12}
if not(chararraycmp(@sb_fat^.pbpb^.bs_filsystype[1],FAT12ID,5)) then goto _exit ;

sb^.driver_space := sb_fat ;

{no utilizado por ahora !!!}
sb_fat^.tfat := 1 ;

sb^.blocksize := sb_fat^.pbpb^.bpb_bytspersec;

{se carga en memoria toda la fat}
if cargar_fat (sb) then else goto _exit ;

sb^.op := @fat_super_op;

sb^.ino_root := 1;

{ solo se limita a un montage }

mounted := true ;

exit(sb);

_exit :
 remove_super_fat (sb_fat);
 printk('/VVFS/n : Error de lectura de Super FAT12\n',[]);
 exit(nil);
end;


{ * Mark_Fat_dirty :                                                    *
  *                                                                     *
  * Procedimiento que dado un sector dentro de la fat calcula el bloque *
  * donde se encuentra en la fat y lo marca como sucio                  *
  *                                                                     *
  ***********************************************************************
}
procedure mark_fat_dirty ( sb : p_super_block_t ; sector : dword ) ;[public , alias : 'MARK_FAT_DIRTY'];
var bh : p_buffer_head ;
    blk : dword ;
    tmp : pointer ;
begin

tmp := @fat ;
sector -= 31 ;
blk := (sector * 3 ) shr 1  ;

{posicion sobre la fat }
tmp += (blk div 512) * 512 ;

bh := get_block (sb^.mayor,sb^.menor,( 1 + blk div 512) , sb^.blocksize);

{se copia el array de fat al bloque }
memcopy (tmp,bh^.data,sb^.blocksize);

mark_buffer_dirty (bh);
put_block(bh);

blk += 1;

{el siguiente offset se encuentra en otro bloque de la fat??}
if dword((blk div 512))  = dword(((blk -1 ) div 512)) then  exit ;

tmp += sb^.blocksize;

bh := get_block (sb^.mayor,sb^.menor,(1 +blk div 512),sb^.blocksize);

memcopy (tmp,bh^.data,sb^.blocksize);

mark_buffer_dirty (bh);
put_block (bh);
end;


{ * Fat12fs_init :                                                      *
  *                                                                     *
  * Inicia las estructuras para el manejo de el driver de fat12         *
  *                                                                     *
  *                                                                     *
  ***********************************************************************
}
procedure fatfs_init ; [public , alias : 'FATFS_INIT'];
begin

fat_fstype.fs_id := 2 ;
fat_fstype.fs_flag := 0 ;
fat_fstype.read_super := @fat_read_super ;

fat_super_op.read_inode := @fat_read_inode ;
fat_super_op.write_inode := @fat_write_inode;
fat_super_op.delete_inode := @fat_delete_inode;
fat_super_op.put_inode := @fat_put_inode;
fat_super_op.write_super := nil ;

fat_inode_op.lookup := @fat_inode_lookup;
fat_inode_op.default_file_ops := @fat_file_op;
fat_inode_op.mkdir := @fat_mkdir ;
fat_inode_op.create := @fat_file_create ;
fat_inode_op.truncate := @fat_file_truncate;
fat_inode_op.mknod := @fat_mknod;
fat_inode_op.rename := @fat_rename;
fat_inode_op.rmdir := @fat_rmdir ;

fat_file_op.read := @fat_read_file ;
fat_file_op.readdir := @fat_readdir ;
fat_file_op.open := nil ;
fat_file_op.seek := @fat_file_seek;
fat_file_op.write := @fat_file_write;
fat_file_op.ioctl := nil ;

register_filesystem (@fat_fstype);

printk('/Vvfs/n ... registrando /Vfat\n',[]);
end;



end.
