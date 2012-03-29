Unit Dcache;

{ * Dcache :                                                    *
  *                                                             *
  * Unidad encargada dl mantenimiento del cache de nombres a    *
  * traves del arbol de dentrys del sistema .  Es utilizada     *
  * por la unida namei.pas                                      *
  *                                                             *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>  *
  * All Rights Reserved                                         *
  *                                                             *
  * Version :                                                   *
  *                                                             *
  * 10 / 10 / 2005 : Corregido bug en Alloc_dentry()            *
  * 03 / 10 / 2005 : Corregido error en Find_in_Dentry          *
  * 20 / 08 / 2005 : Corregido bug en Enqueue_dentry()          *
  * 29 / 06 / 2005 : Primera version                            *
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

{define debug}
{$DEFINE Use_Tail }
{$DEFINE nodo_struct := p_dentry}
{$DEFINE next_nodo := next_dentry }
{$DEFINE prev_nodo := prev_dentry }

{Macros creados solo para comodidad}
{$DEFINE Push_Dentry := Push_Node }
{$DEFINE Pop_Dentry:= Pop_Node }


{dentrys sin uso}
const Free_dentrys : p_dentry = nil ;


var dentry_root : p_dentry ;
    Max_dentrys : dword ;


implementation


{$I ../include/head/string.h}

{$I ../include/head/list.h}
{$I ../include/head/lock.h}

procedure Init_dentry (dt : p_dentry);
begin


with dt^ do
 begin
 ino := nil ;
 flags := 0 ;
 count := 0 ;
 name[0] := char(0) ;
 down_tree := nil ;
 next_dentry := nil ;
 prev_dentry := nil ;
 down_mount_Tree := nil;
 down_tree := nil;
 parent := nil ;
 l_count := 0 ;
end;
end;



{ * encola un dentry en su padre * }

procedure Enqueue_dentry (dt : p_dentry );
begin
Push_dentry (dt,dt^.parent^.down_tree);
dt^.parent^.l_count += 1;
end;


{ * quita un dentry de su padre * }

procedure Remove_queue_dentry (dt :p_dentry );inline;
begin
Pop_dentry (dt,dt^.parent^.down_tree);
dt^.parent^.l_count -= 1;
end;


{ * busca un nombre dentro de un dentry  y devuelve un puntero dentry * }

function Find_in_Dentry (const name : string ; dt : p_dentry ) : p_dentry ;
var tmp : p_dentry ;
begin

tmp := dt^.down_tree;

if tmp = nil then exit(nil);

repeat
if dword(name[0]) <> dword(tmp^.name[0]) then exit(nil);
if chararraycmp(@name[1], @tmp^.name[1],dword(tmp^.name[0])) Then exit(tmp);
tmp := tmp^.next_dentry;
until (tmp = dt^.down_tree) ;

exit(nil);
end;


{ * Alloc_dentry  :                                                     *
  *                                                                     *
  * name : Nombre de la entrada                                         *
  *                                                                     *
  * Esta funcion devuelve un estructura dentry libre , primero tratara  *
  * de crear y si no hay memoria suficiente tomara una estrutura de la  *
  * cola de libres ,  y si en este caso no puede devuelve nil           *
  *                                                                     *
  ***********************************************************************
}
function Alloc_dentry (const name : string ) : p_dentry ;[public , alias :'ALLOC_DENTRY'];
var tmp : p_dentry ;

label _exit,_lru ;
begin

if Max_dentrys = 0 then
 begin

  _lru :

  if Free_dentrys = nil then exit(nil);

  {se toma el menos utilizado}
  tmp := free_dentrys^.prev_dentry ;

  goto _exit ;
 end;

 tmp := kmalloc (sizeof(dentry));

 if tmp = nil then goto _lru ;

 Max_dentrys -= 1;

 _exit :

 init_dentry (tmp);

 memcopy (@name[0],@tmp^.name[0],dword(name[0]));
 tmp^.len := byte(tmp^.name[0]);
 tmp^.name[0] := char(tmp^.len);

 exit (tmp);
 end;



{ * Alloc_Entry :                                                       *
  *                                                                     *
  * ino_p : puntero al inodo directorio padre                           *
  * name : nombre de la entrada                                         *
  *                                                                     *
  * Esta funcion es bastante compleja , lo que hace primeramente es     *
  * buscar name en el arbol del padre , si la encuentra aumenta el      *
  * contador del dentry y devuelve la dentry  . Si fuese una entrada    *
  * vacia hace un lookup sobre el ino_p para traer el inodo a memoria   *
  *  . Llena la dentry con el inodo y el driver devera puntear el       *
  * campo i_dentry del inodo al dentry que se le pasa como parametro    *
  * Si no estubiese trata de crear la estruc. busca un dentry libre     *
  * y hace un lookup con name , es encolada y devera ser devuelta con   *
  * Put_dentry                                                          *
  *                                                                     *
  ***********************************************************************
}


const 
	DIR :  pchar = '.';
	DIR_PREV  : pchar = '..';

function Alloc_Entry ( ino_p : p_inode_t ; const name : string ) : p_dentry ;[public , alias :'ALLOC_ENTRY'];
var tmp :p_dentry ;
label _1 ;
begin

Inode_Lock (@ino_p^.wait_on_inode);

{entradas estandart}
if chararraycmp(@name[1],@DIR[1],1) then
 begin
 tmp := ino_p^.i_dentry ;
 goto _1;
 end
  else if chararraycmp(@name[1],@DIR_PREV[1],2) then
   begin
    tmp := ino_p^.i_dentry^.parent ;
    goto _1 ;
    end;

tmp := find_in_dentry (name,ino_p^.i_dentry);

if tmp <> nil then
 begin

_1:

  {esta encache}
  if (tmp^.state = st_incache) then
   begin
    tmp^.count += 1;

    {esta en cache pero el inodo esta en lru}
    if tmp^.ino^.count = 0 then
     begin
     get_inode (tmp^.ino^.sb,tmp^.ino^.ino);
     tmp^.ino^.count := 1 ;
     end;

    {$IFDEF debug}
     printk('/Vdcache/n : entrada en cache %p\n',[name],[]);
    {$ENDIF}

    Inode_Unlock (@ino_p^.wait_on_inode);
    exit (tmp);
   end;

  {entrada zombie}
  if (tmp^.state = st_vacio) then
   begin

    {una parte del arbol esta invalidado por que fue eliminada una entrada fisica}
    if ino_p^.op^.lookup (ino_p , tmp) = nil then Panic ('VFS : Arbol invalido!!!!');

    {se trae el inodo al cache de inodos}
    {lookup deve llenar el campo ino del cache y poner al campo count en 1}
    tmp^.state := st_incache;
    tmp^.flags := tmp^.ino^.flags;
    tmp^.l_count := 0 ;
    tmp^.count := 1;
    Inode_Unlock (@ino_p^.wait_on_inode);
    exit(tmp );
   end;

end;

tmp := alloc_dentry (name) ;

{no se puede seguir la ruta!!!}
if tmp = nil then
 begin
  Inode_Unlock (@ino_p^.wait_on_inode);
  exit(nil);
 end;

{no existe la dentry!!!??}
if ino_p^.op^.lookup (ino_p,tmp) = nil then
 begin
  Push_dentry (free_dentrys,tmp);
  Inode_Unlock (@ino_p^.wait_on_inode);
  exit(nil);
 end;

tmp^.state := st_incache;
tmp^.parent := ino_p^.i_dentry ;
tmp^.flags := tmp^.ino^.flags ;
tmp^.count := 1 ;
tmp^.ino^.i_dentry := tmp;

{se pone en la cola del padre}
Enqueue_Dentry (tmp);

 {$IFDEF DEBUG}
  printk('/Vdcache/n : nueva entrada %p\n',[name],[]);
 {$ENDIF}

Inode_Unlock (@ino_p^.wait_on_inode);

exit(tmp);
end;





{ * Put_dentry :                                                         *
  *                                                                      *
  * dt : puntero al dentry                                               *
  *                                                                      *
  * Decrementa el uso de una dentry si no posee mas usuarios se devuelve *
  * el inodo al cache . Cuando un  inodo quitado totalmente del sistema  *
  * si no posee enlaces se libera la estructura , si posee se vuelve un  *
  * dentry vacio puesto que podra ser utilizada en una futura busqueda   *
  * Las que poseen enlaces son enlazadas ya que es muy posible que se    *
  * vuelven totalmente obsoletas , proc. sync rastrea esta cola en busca *
  * de dentrys obsoletas y las coloca en la cola de libres               *
  * (no implementado)                                                    *
  *                                                                      *
  ************************************************************************
}
procedure Put_dentry (dt : p_dentry ) ; [public , alias : 'PUT_DENTRY'];
begin
dt^.count -= 1;
if dt^.count = 0 then put_inode (dt^.ino);
end;




{ * Llamada que quita un dentry y la coloca como libre * }

procedure Free_Dentry ( dt : p_dentry ) ; [public ,alias :'FREE_DENTRY'];
begin
Remove_queue_dentry (dt);
Push_Dentry (Free_dentrys,dt);
end;


end.
