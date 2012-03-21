Unit Inodes;

{ * Inodes :                                                          *
  *                                                                   *
  * Esta unidad en encarga del cache de inodos a traves de las llama  *
  * das al sistema get_inode y put_inode .                            *
  *                                                                   *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>        *
  * All Rights Reserved                                               *
  *                                                                   *
  * Versiones  :                                                      *
  *                                                                   *
  * 27 / 05 / 2005 : Se modifican las estructuras para dar soporte    *
  * al nuevo VFS                                                      *
  *                                                                   *
  * 07 / 03 / 2005 : Se crean las funciones Inode_Write , Inode_Read ,*
  * Inode_Close , y son protegidos con Inode_Lock e Inodo_Unlock      *
  *                                                                   *
  * 24 / 02 / 2004  : Primera Version                                 *
  *                                                                   *
  *********************************************************************
}


interface


{$I ../include/toro/procesos.inc}
{$I ../include/head/procesos.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/asm.h}
{$I ../include/toro/buffer.inc}
{$I ../include/head/buffer.h}
{$I ../include/head/super.h}
{$I ../include/head/printk_.h}
{$I ../include/head/malloc.h}
{$I ../include/head/dcache.h}
{$I ../include/head/devices.h}

{$define Use_Tail }
{$define nodo_struct := p_inode_t}
{$define next_nodo := ino_next}
{$define prev_nodo := ino_prev}
{$define Push_Inode := Push_Node }
{$define Pop_Inode  := Pop_Node }

{$define inode_lock := lock }
{$define inode_unlock := unlock }

{Tabla con los inodos en memoria}
const Inodes_Lru : p_inode_t = nil ;
      Inodes_Free : p_inode_t = nil ;
      Inodes_Dirty : p_inode_t = nil;


var Max_Inodes : dword ;

implementation

{$I ../include/head/list.h}
{$I ../include/head/lock.h}

{ * funcion que quita de la cola simple un inodo sucio * }

procedure remove_ino_dirty ( ino : p_inode_t);inline;
var tmp : p_inode_t ;
begin

if inodes_dirty = ino then
 inodes_dirty^.ino_dirty_next := ino^.ino_dirty_next
  else
   begin

   {se busca por toda la cola }
   while (tmp^.ino_dirty_next <> ino)   do tmp := tmp^.ino_dirty_next ;

   tmp^.ino_dirty_next := ino^.ino_dirty_next ;
   end;

end;

{ * Inode_Update :                                                      *
  *                                                                     *
  * Ino : Puntero a un inodo                                            *
  * Retorno : 0 si ok o -1 si falla                                     *
  *                                                                     *
  * Funcion que actualiza la version en el dev dado                     *
  *                                                                     *
  ***********************************************************************
}
function Inode_Update (Ino : p_inode_t ) : dword ;inline;
begin
if (ino^.state and I_Dirty ) <> I_Dirty then exit(0)
 else
  begin
   ino^.sb^.op^.write_inode (ino) ;

    if (ino^.state and I_Dirty ) <> I_Dirty then exit(0)
     else exit(-1);
  end;
end;




{ * Inode_Uptodate :                                                    *
  *                                                                     *
  * Ino : Puntero a un inodo                                            *
  *                                                                     *
  * Funcion que trae un inodo al cache                                  *
  *                                                                     *
  ***********************************************************************
}
function Inode_Uptodate (Ino : p_inode_t ) : dword ;inline;
begin
ino^.sb^.op^.read_inode (ino) ;

if (ino^.state and I_Dirty) = I_dirty  then exit(-1) else exit(0);
end;





{ * devuelve un inodo libre de la cola de inodos invalidados * }

function alloc_from_free : p_inode_t ; inline ;
var tmp : p_inode_t ;
begin

if Inodes_Free = nil then exit(nil)
 else
  begin
   tmp := Inodes_Free^.ino_prev;
   Pop_Inode (Inodes_Free,tmp);
   exit(tmp);
  end;
end;



{ * devuelve un inodo libre de la cola de inodos no utilizados * }

function alloc_from_lru : p_inode_t ; inline ;
var tmp : p_inode_t ;
begin

if Inodes_Lru = nil then exit(nil);

tmp := Inodes_Lru^.ino_prev;

{por si esta sucio , esto es un grave error}
if Inode_Update (tmp) <> 0 then
    printk('/VVFS/n : Error de escritura del Inodo : %d dev : %d \n',[tmp^.ino,tmp^.mayor,tmp^.menor],[]);

{fue quitado de la cola de sucios}
remove_ino_dirty (tmp);

{si actualmente no posee enlaces en el arbol puede liberarse sino
permanecera como vacio}
if tmp^.i_dentry^.l_count = 0 then Free_dentry (tmp^.i_dentry)
 else tmp^.state := st_vacio;

{se informa al driver que el inodo fue totalmente quitado del sistema}
tmp^.sb^.op^.delete_inode (tmp);

Pop_Inode (Inodes_Lru,tmp);
end;





{ * Alloc_Inode :                                                        *
  *                                                                      *
  * Funcion que devuelve un inodo libre y llena los campos mayor , menor *
  * y ino                                                                *
  *                                                                      *
  ************************************************************************
}

function Alloc_Inode (mayor , menor , inode : dword ) : p_inode_t ;
var tmp : p_inode_t ;
label _exit;
begin


if Max_Inodes = 0 then
  begin

    {se trata de alocar de los inodos invalidos}
    tmp := alloc_from_free ;

    if tmp <> nil then goto _exit ;

    {se alocara tomando de la cola lru}
    tmp := alloc_from_lru ;

    if tmp = nil then exit (nil) else goto _exit ;
  end;

{hay memoria como para seguir alocando}

tmp := alloc_from_free;

if (tmp <> nil) then goto _exit
 else
   begin
    tmp := kmalloc (sizeof(inode_t));
    if tmp = nil then exit(nil);
   end;

Max_Inodes -= 1;

_exit :

tmp^.mayor := mayor ;
tmp^.menor := menor ;
tmp^.ino := inode ;
tmp^.wait_on_inode.lock := false ;
tmp^.state := 0 ;
tmp^.count := 0 ;

exit(tmp);
end;




{ *  se encarga de buscar un ino en la cola en uso de un sb * }

function Find_in_Hash (sb : p_super_block_t ; ino : dword ) : p_inode_t ;inline;
var tmp  : p_inode_t ;
begin

if  sb^.ino_hash = nil then exit(nil);

tmp := sb^.ino_hash ;

repeat
if (tmp^.ino = ino) then exit(tmp);
tmp := tmp^.ino_next;
until (tmp = sb^.ino_hash) ;

exit(nil);
end;


{ * busca un inodo en la cola lru * }

function Find_in_Lru (mayor,menor,ino : dword) : p_inode_t ;inline;
var tmp : p_inode_t ;
begin
tmp := inodes_lru ;

if tmp = nil then exit(nil);

repeat

if (tmp^.mayor =mayor ) and ( tmp^.menor = menor) and (tmp^.ino = ino) then exit(tmp);

until (tmp = inodes_lru) ;


exit(nil);
end;




{ * Get_Inode :                                                         *
  *                                                                     *
  * Dev_blk : Dispostivo logico de donde sera leido el inodo            *
  * Inode : Numero de Inodo                                             *
  * Devuelve : Puntero al inodo o nil si falla                          *
  *                                                                     *
  * Carga un Inodo en memoria y devuelve su puntero                     *
  *                                                                     *
  ***********************************************************************
}
function Get_Inode(sb : p_super_block_t ; ino : dword ):p_inode_t;[public , alias :'GET_INODE'];
var tmp : p_inode_t ;
begin

if sb = nil then exit(nil);

{puede estar en uso}
tmp := Find_in_Hash (sb,ino);

if tmp <> nil then
 begin
  tmp^.count += 1;
  exit(tmp);
 end;

tmp := Find_in_Lru (sb^.mayor,sb^.menor,ino);

{estaba en la cola de libres}
if tmp <> nil then
 begin
  Pop_Inode (inodes_lru,tmp);
  Push_Inode (sb^.ino_hash,tmp);
  tmp^.count := 1 ;
  exit(tmp);
 end;

{se crea o reutiliza una estructura}
tmp := Alloc_Inode (sb^.mayor,sb^.menor,ino);

if tmp = nil then exit(nil);


{sp del inodo}
tmp^.sb := sb ;
tmp^.blksize := sb^.blocksize;
tmp^.count := 1 ;

if Inode_Uptodate (tmp) = -1 then
 begin
  printk('/VVFS/n : Error de lectura de Inodo : %d Dev %d %d \n',[tmp^.ino,tmp^.mayor,tmp^.menor],[]);
  Push_Inode (Inodes_Free,tmp);
 exit(nil);
 end;

{se coloca en la cola en uso}
Push_Inode (sb^.ino_hash,tmp);

exit(tmp);
end;




{ * Put_Inode :                                                          *
  *                                                                      *
  * Inode : Puntero a un inodo                                           *
  * Devuelve : 0 si fue correcto o -1 sino                               *
  *                                                                      *
  ************************************************************************
}

function Put_Inode ( ino:p_inode_t ):dword;[public , alias :'PUT_INODE'];
begin

if (ino^.count = 0) then Panic ('/nSe devuelve un inodo con count =  0\n');

ino^.count -= 1;

 {el dentry del inodo permanece en la cache de dentrys hasta que el inodo}
 {sea quitado totalmente del sistema}
 if (ino^.count = 0) then
  begin

    Pop_Inode (ino^.sb^.ino_hash,ino);
    Push_Inode (Inodes_lru,ino);

    {se le informa al driver que el inodo paso a la cola de desuso}
    ino^.sb^.op^.put_inode(ino)

 end;

exit(0);
end;


{ * Invalidate_Inode :                                                  *
  *                                                                     *
  * simple funcion que quita un inodo en uso y lo manda a la cola de    *
  * inodos invalidados                                                  *
  * Esto siempre se debe hacer suponiedo que no este sucio el inodo  ,  *
  * por lo tanto previamente se debera haber llamado sync               *
  *                                                                     *
  ***********************************************************************
}
procedure Invalidate_Inode ( ino : p_inode_t ) ; [public , alias :'INVALIDATE_INODE'];
begin
Pop_Inode (ino^.sb^.ino_hash,ino);
Push_Inode (Inodes_Free,ino);
end;



{ * Marca a ino como sucio !!! * }

procedure Mark_Inode_Dirty ( Ino : p_inode_t) ;[public , alias : ' MARK_INODE_DIRTY'];
begin
if (ino^.state and I_Dirty) = I_dirty then exit else ino^.state := ino^.state or I_Dirty ;

{es colocado en la cola simple de inodos sucios}
ino^.ino_dirty_next := inodes_dirty ;
inodes_dirty := ino ;
end;


{ * Sync_Inode :                                                        *
  *                                                                     *
  * Marca los bufferes de los inodos como sucios para que luego una     *
  * llamada del sistema sync los envie a disco                          *
  *                                                                     *
  ***********************************************************************
}
procedure Sync_Inodes ; [public , alias :'SYNC_INODES'];
var tmp : p_inode_t ;
begin

tmp := inodes_dirty ;

while (tmp <> nil) do
 begin
 if Inode_Update (tmp) = -1 then printk('/VVFS/n : Error de escritura de inodo\n',[],[]);
 tmp := tmp^.ino_dirty_next ;
end;

inodes_dirty := nil ;
end;

end.
