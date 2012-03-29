Unit Super_Bloque;

{ * Super_Bloque :                                                          *
  *                                                                         *
  * Esta unidad se dedica al mantenimiento de los superbloques y al montado *
  * de los sistema de archivo                                               *
  *                                                                         *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>              *
  * All Rights Reserved                                                     *
  *                                                                         *
  * Versiones :                                                             *
  * 25 / 06 / 2006 : Primera Version del VFS                                *
  *                                                                         *
  * 04 / 03 / 2005 : Segunda Version                                        *
  *                                                                         *
  * 23 - 02 - 2004 : Primera Version                                        *
  *                                                                         *
  ***************************************************************************
  }

interface


{$I ../include/toro/procesos.inc}
{$I ../include/toro/buffer.inc}
{$I ../include/toro/mount.inc}
{$I ../include/head/buffer.h}
{$I ../include/head/asm.h}
{$I ../include/head/inodes.h}
{$I ../include/head/dcache.h}
{$I ../include/head/open.h}
{$I ../include/head/procesos.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/read_write.h}
{$I ../include/head/devices.h}
{$I ../include/head/printk_.h}
{$I ../include/head/malloc.h}

{Simbolos utilizados para los macros de la cola ligada de spblk}

{$DEFINE Use_Tail }
{$DEFINE nodo_struct := p_super_block_t}
{$DEFINE next_nodo := next_spblk }
{$DEFINE prev_nodo := prev_spblk }
{$DEFINE nodo_tail := Super_Tail }

{Macros creados solo para comodidad}
{$DEFINE Push_Spblk := Push_Node }
{$DEFINE Pop_Spblk := Pop_Node }

{$define Super_Lock := Lock }
{$define Super_unlock := Unlock }

const  Super_Tail:p_super_block_t = nil;
       Nr_Spblk : dword = 0 ;


var   I_Root:p_inode_t;


implementation

{$I ../include/head/string.h}
{$I ../include/head/list.h}
{$I ../include/head/lock.h}


procedure Init_Super (Super : p_super_block_t);inline;
begin
super^.mayor := 0 ;
super^.menor := 0 ;
super^.dirty := false ;
super^.flags := 0 ;
super^.blocksize := 0 ;
super^.driver_space := nil ;
super^.wait_on_sb.lock := false ;
super^.ino_hash := nil ;
end;


procedure Remove_Spb (sp : p_super_block_t ) ;
begin
Pop_spblk (sp);
kfree_s(sp , sizeof (super_block_t));
end;


{ * Read_Super :                                                        *
  *                                                                     *
  * Mayor  , Menor : Dev                                                *
  * Flags : tipo de sb                                                  *
  * fs : Puntero al driver de fs                                        *
  *                                                                     *
  * Funcion que lee un superbloque y lo agrega a la cola de sp montados *
  *                                                                     *
  ***********************************************************************
  }
function read_super ( Mayor , Menor , flags : dword ; fs : p_file_system_type ) : p_super_block_t ;[public , alias : 'READ_SUPER'];
var tmp : p_super_block_t;
    p : p_inode_t ;
begin

if Nr_Spblk = Max_Spblk then exit (nil);

tmp := kmalloc (sizeof(super_block_t));

if tmp = nil then exit (nil);

Init_Super (tmp);

tmp^.mayor := mayor ;
tmp^.menor := menor ;
tmp^.flags := flags ;
tmp^.fs_type := fs ;

if  fs^.read_super (tmp) = nil then
 begin
  Invalid_sb (tmp);
  kfree_s (tmp,sizeof(super_block_t));
  exit(nil);
 end;


{es metido en la cola de spb}
push_spblk (tmp);

{este debera permanecer el memoria}
p := get_inode (tmp,tmp^.ino_root);

{no se pudo traer !!!}
if (p = nil) then
 begin
  {todo el cache perteneciente al sp es removido!!!}
  Invalid_sb (tmp);
  Remove_spb (tmp);
  exit(nil);
 end;

{el driver nunca trabaja con el dcache , por eso el campo i_dentry debe }
{estar a nil!!!}
tmp^.pino_root := p;

{se puede crear un dentry para el cache??}
tmp^.pino_root^.i_dentry := alloc_dentry (' ');

{error al crear el la entrada}
if tmp^.pino_root^.i_dentry = nil then
 begin
  put_inode (tmp^.pino_root);
  Invalid_sb (tmp);
  remove_spb (tmp);
  exit(nil);
 end;

tmp^.pino_root^.i_dentry^.ino := tmp^.pino_root;

{siempre estara en memoria , prevego a que un put_dentry me saque el ino}
{root}
tmp^.pino_root^.i_dentry^.count := 1;

Nr_Spblk += 1;

exit(tmp);

end;


{ * Get_Super :                                                         *
  *                                                                     *
  * Mayor y Menor : Idet. del dispositivo                               *
  * Devuelve : Un puntero al superbloque                                *
  *                                                                     *
  * Esta funcion devuelve el superbloque de un dispotivo dado , este    *
  * devera estar previamente registrado                                 *
  *                                                                     *
  ***********************************************************************
}
function Get_Super(Mayor,Menor:dword) : p_super_block_t;[public , alias :'GET_SUPER'];
var tmp:p_super_block_t ;
begin

tmp := Super_Tail ;

repeat
If (tmp^.mayor = mayor) and (tmp^.menor = menor) then exit(tmp);

tmp := tmp^.next_spblk;
until (tmp = Super_Tail);

exit(nil);
end;


{ * Get_Fstype :                                                        *
  *                                                                     *
  * name : Nombre del sistema de archivo                                *
  * retorno : a la estructura del driver                                *
  *                                                                     *
  * funcionque que devuelve un puntero al driver dado en name dentro de *
  * los drivers instalados                                              *
  *                                                                     *
  ***********************************************************************
}
function get_fstype ( const name : string ) : p_file_system_type ; [public , alias : 'GET_FSTYPE'];
var tmp  , id : dword ;
    fs : p_file_system_type ;

begin

id := 0 ;

for tmp := 1 to High (fsid) do 
 begin
	if chararraycmp(@fsid[tmp].name[1],@name[1],dword(name[0])) then
        begin 
       	 id := fsid[tmp].id ;
         break;
	end;
 end;         

if id = 0 then exit(nil);

if fs_type = nil then exit(nil);

{se buscara el id en la cola de driver instalados}
fs := fs_type ;

repeat
if fs^.fs_id = id then exit(fs) ;

fs := fs^.next_fs ;
until ( fs = fs_type) ;


exit(nil);
end;


end.
