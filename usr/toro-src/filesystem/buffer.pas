Unit Buffer;

{ * Buffer :                                                         *
  *                                                                  *
  * Aqui es implementado el buffer cache del sistema , los bloques   *
  * son anidados en dos colas las cola Lru y la cola Hash , por      *
  * ahora solo maneja el cache de bloques de dispositivos de bloque  *
  *                                                                  *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>       *
  * All Rights Reserved                                              *
  *                                                                  *
  *                                                                  *
  * 12 / 04 / 06 : Es solucionado bug en pop_buffer                  *
  *                                                                  *
  * 14 / 10 / 05 : Solucionado bug en Invalid_sb()                   *
  *                                                                  *
  * 24 / 06 / 05 : Es reescritoro dando soporte al vfs               *
  *                                                                  *
  * 07 / 03 / 05 : Es creada la funcion Get_Virtual_Block  , y       *
  * las funciones Buffer_Read y Buffer_Write , se protegen los       *
  * bufferes con Buffer_Lock y Buffer_Unlock . Get_block devuelve    *
  * ahora buffer_head                                                *
  *                                                                  *
  * 15 / 12 / 04 : Es resuelto el probleme de lecturas erroneas , se *
  * elimna el sistema de tablas y se implementan buffer_heads dina   *
  * mincos                                                           *
  *                                                                  *
  * 18 / 08 / 04 : Se aplica la syscall Sync y se modifica la        *
  * estructura Buffer_Head                                           *
  *                                                                  *
  * 11 / 02 / 04 : Primera Version                                   *
  *                                                                  *
  ********************************************************************
}

{DEFINE DEBUG}

interface


{$I ../Include/Head/asm.h}
{$I ../Include/Toro/procesos.inc}
{$I ../Include/Toro/buffer.inc}
{$I ../Include/Head/devices.h}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/malloc.h}
{$I ../Include/Head/paging.h}
{$I ../Include/Head/mm.h}
{$I ../Include/Head/ll_rw_block.h}
{$I ../Include/Head/dcache.h}
{$I ../Include/Head/inodes.h}
{$I ../Include/Head/super.h}
{$I ../Include/Head/itimer.h}


{$define Use_Tail }

{$define nodo_struct := p_buffer_head }
{$define next_nodo := next_buffer }
{$define prev_nodo := prev_buffer }

{$define Push_Buffer := Push_Node}
{$define Pop_Buffer := Pop_Node }

{$define buffer_lock := lock }
{$define buffer_unlock := unlock }


var Buffer_Hash:array[1..Nr_blk] of p_buffer_head;
    Buffer_Lru : p_buffer_head ;
    Buffer_Dirty : p_buffer_head;
    Max_Buffers:dword;


procedure Sys_Sync ;

implementation


{$I ../Include/Head/list.h}
{$I ../Include/Head/lock.h}


{ * Lru_Find :                                                          *
  *                                                                     *
  * Dev_blk : Dispositivo de Bloque                                     *
  * Bloque : Numero de Bloque                                           *
  * Retorno : Puntero buffer_head o nil se falla                        *
  *                                                                     *
  * Esta funcion busca dentro de la cola Lru un bloque dado y si lo     *
  * encuentra devuelve un puntero a la estructura buffer_head o de lo   *
  * contrario nil                                                       *
  *                                                                     *
  ***********************************************************************
}
function lru_find(Mayor,Menor,Bloque,Size:dword):p_buffer_head;
var tmp:p_buffer_head;
begin

If Buffer_Lru = nil then exit (nil) ;

tmp:=Buffer_Lru;

repeat
if (tmp^.Mayor=Mayor)  and (tmp^.menor = Menor) and (tmp^.bloque=bloque) and (tmp^.size = size) then exit(tmp);

tmp := tmp^.next_buffer;
until ( tmp = Buffer_Lru);

exit(nil);
end;





{ * Push_Hash :                                                         *
  *                                                                     *
  * Procedimiento que coloca un buffer_head en la cola hash             *
  *                                                                     *
  ***********************************************************************
}
procedure push_hash(buffer:p_buffer_head);inline;
begin
Push_Buffer (buffer , Buffer_Hash[buffer^.mayor]);
end;




{ * Pop_Hash :                                                          *
  *                                                                     *
  * Procedimiento que quita un buffer_head de la cola hash              *
  *                                                                     *
  ***********************************************************************
}

procedure pop_hash(Buffer:p_buffer_head);inline;
begin
Pop_Buffer (buffer , Buffer_Hash[buffer^.mayor]);
end;



function hash_find(Mayor,Menor,Bloque,size:dword):p_buffer_head;[public , alias :'HASH_FIND'];
var tmp:p_buffer_head;
begin

tmp:=Buffer_Hash[Mayor];
if tmp=nil then exit(nil);

repeat
If (tmp^.menor = Menor) and (tmp^.bloque = Bloque) and (tmp^.size = size) then exit(tmp);
tmp:=tmp^.next_buffer;
until (tmp=Buffer_Hash[Mayor]);


exit(nil);
end;





function buffer_update (Buffer:p_buffer_head):dword;[public , alias : 'BUFFER_UPDATE'];
begin
if ( buffer^.state and Bh_Dirty = Bh_Dirty) then
  begin

  if buffer_write (buffer) <> -1 then
   begin
   buffer^.state := buffer^.state xor Bh_dirty;
    exit(0)
    end
     else exit(-1);
    end
 else exit(0);
end;


procedure Init_Bh (bh : p_buffer_head ; mayor , menor , bloque : dword) ;inline;
begin
bh^.mayor := mayor ;
bh^.menor := menor ;
bh^.bloque := bloque ;
bh^.count := 1;
bh^.state := 0 ;
bh^.wait_on_buffer.lock := false;
bh^.wait_on_buffer.lock_wait := nil ;
bh^.prev_buffer := nil ;
bh^.next_buffer := nil ;
end;



{ * Alloc_Buffer :                                                      *
  *                                                                     *
  * size : Tama¤o del nuevo bloque a crear                              *
  *                                                                     *
  * crea un buffer utilizando la variable Max_Buffers como indicador    *
  *                                                                     *
  ***********************************************************************
}
function alloc_buffer (size : dword ) : p_buffer_head ;
var tmp :p_buffer_head ;
    tm : pointer ;
begin

{situacion critica}
if Max_Buffers = 0 then
 begin

 if buffer_lru = nil then  exit(nil);

 tmp := Buffer_Lru^.prev_buffer;

 {limpiar la cola de sucios}
 if (tmp^.state and BH_dirty ) = Bh_Dirty then sys_sync;

 {si el tama¤o del buffer no es igual habra que liberar y solicitar}
 if tmp^.size <> size then
  begin
   tm := kmalloc (size);
   if tm = nil then  exit (nil);
   kfree_s (tmp^.data,tmp^.size);
   tmp^.data := tm ;
   tmp^.size := size;
  end;

 Pop_Buffer(tmp,Buffer_Lru);

 exit(tmp);
 end;

{hay suficiente memoria como para seguir creando estructuras}

tmp := kmalloc (sizeof (buffer_head));

if tmp = nil then exit (nil) ;

tmp^.data := kmalloc (size) ;


if tmp^.data = nil then
 begin
  kfree_s (tmp,sizeof(buffer_head));
  exit(nil);
 end;

tmp^.size := size ;
Max_Buffers -= 1;

exit (tmp);
end;


procedure free_buffer (bh : p_buffer_head );inline;
begin
kfree_s (bh^.data,bh^.size);
kfree_s (bh,sizeof(buffer_head));
end;



{ * Get_Block :                                                         *
  *                                                                     *
  * Mayor : Dev Mayor                                                   *
  * Menor : Dev Menor                                                   *
  * Bloque  : Numero de bloque                                          *
  * Retorno : nil si fue incorrecta o puntero a los datos               *
  *                                                                     *
  * Esta funcion es el nucleo del buffer , por ahora solo trabaja con   *
  * bloques de dispostivos de bloque y con un tamano constante          *
  *                                                                     *
  ***********************************************************************
}
function get_block(Mayor,Menor,Bloque,size:dword):p_buffer_head;[public , alias :'GET_BLOCK'];
var tmp:p_buffer_head;
begin

{Busco en la tabla hash}
tmp := Hash_Find(Mayor,Menor,Bloque,size);

{esta en uso}
If tmp <> nil then
 begin
 tmp^.count += 1;
 exit (tmp);
end;

{Es Buscado en la tabla Lru}
tmp := Lru_Find(Mayor,Menor,Bloque,size);

If tmp <> nil then
 begin

  { En la Lru se guardan los q no estan en uso}
   Pop_Buffer(tmp,Buffer_Lru);

   tmp^.count := 1;

   Push_Hash(tmp);
   exit(tmp);
end;

tmp := alloc_buffer (size);

{situacion poco querida}

if tmp = nil then
 begin
 printk('/Vvfs/n : No hay mas buffer-heads libres\n',[],[]);
 exit(nil);
 end;

Init_Bh (tmp,mayor,menor,bloque);

{se trae la data del disco}
 If  Buffer_Read(tmp) = 0 then
  begin
  Push_Hash(tmp);
  Get_Block := tmp;
  end
  else
   begin
     {hubo un error se devuelve el buffer}
     printk('/Vvfs/n : Error de Lectura : block %d dev %d %d \n',[tmp^.bloque,tmp^.mayor,tmp^.menor],[]);
     free_buffer (tmp);
     Max_Buffers += 1;
     exit(nil);
   end;

end;


{ * Mark_Buffer_Dirty :                                                 *
  *                                                                     *
  * bh : puntero a una estructura buffer                                *
  *                                                                     *
  * Procedimiento que marca a un buffer como sucio y lo coloca en la    *
  * utilizada por sync                                                  *
  *                                                                     *
  ***********************************************************************
}
procedure Mark_Buffer_Dirty (Bh : p_buffer_head );[public , alias :'MARK_BUFFER_DIRTY'];
begin

if (bh^.state and Bh_dirty ) = Bh_Dirty then exit;

Bh^.state := bh^.state or Bh_Dirty ;

bh^.next_bh_dirty := Buffer_Dirty;

Buffer_Dirty := bh ;
end;




{ * Put_Block :                                                                *
  *                                                                            *
  * Mayor   : Dispositivo de bloque                                            *
  * Menor   : Dispositvo Menor                                                 *
  * Bloque : Numero de bloque                                                  *
  *                                                                            *
  * Devuelve el uso de un bloque , y es llamado cada vez que se termina su uso *
  * y decrementa su uso                                                        *
  * Es importante , ya que luego de un GET_BLOCK deve venir un PUT_BLOCK , que *
  * devuelva a la reserva , y si el bloque es del sistema se actualizara la    *
  * version del disco , ademas se decrementara el uso , para que pueda salir de*
  * la cola hash                                                               *
  *                                                                            *
  ******************************************************************************
  }
function Put_Block(buffer:p_buffer_head):dword;[public , alias :'PUT_BLOCK'];
var tmp : p_buffer_head ;
begin

if buffer=nil then panic('VFS : Se quita un buffer no pedido');

buffer^.count -= 1;

{ya nadie lo esta utilizando}

If buffer^.count = 0 then
 begin
  Pop_Hash (buffer);
  Push_buffer (buffer,Buffer_Lru);
 end;
end;


{ * Sys_Sync  :                                                         *
  *                                                                     *
  * Implementacion de la llamada al sistema Sync() que actualiza todos  *
  * bloques no utilizados al disco                                      *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 20 / 06 / 2005 : Rescritura con el nuevo modelo de FS               *
  * 26 / 12 / 2004 : Son escritos tambien los bloques en la cola Hash   *
  *                                                                     *
  ***********************************************************************
}
procedure Sys_Sync ; [public , alias :'SYS_SYNC'];
var tmp:p_buffer_head;
begin

sync_inodes ;

{es simple se rastrea toda la cola de sucios}
tmp := Buffer_Dirty ;

while (tmp <> nil) do
 begin
 if Buffer_Update (tmp) = -1 then printk('/Vvfs/n : Error de escritura : block %d dev %d %d\n',[tmp^.bloque,tmp^.mayor,tmp^.menor],[]);
 tmp := tmp^.next_bh_dirty ;
end;

Buffer_Dirty := nil ;
end;


{ * Invalid_Sb                                                          *
  *                                                                     *
  * sb : Puntero a un superbloque                                       *
  *                                                                     *
  * Procedimiento que limpia todos los bloques y dado un sb manda los   *
  * bloques en uso de ese sb a la cola LRU                              *
  *                                                                     *
  ***********************************************************************
}
procedure Invalid_Sb ( sb : p_super_block_t) ;[public , alias : 'INVALID_SB'];
var mayor,menor : dword ;
    bh , tbh : p_buffer_head ;
begin

mayor := sb^.mayor ;
menor := sb^.menor ;

{primero mando a todos al disco}
sys_sync ;

{ahora que estan todos limpios los quita de las de en uso}

{si no hay salgo!}
if Buffer_Hash[mayor] = nil then exit ;

{todos los bufferes en uso son movidos a la cola lru}
bh := Buffer_Hash [mayor]^.prev_buffer ;

repeat
  pop_hash (bh);
  push_buffer (bh , Buffer_Lru);

  bh := bh^.prev_buffer ;
until (bh <> nil);

end;


{ * Buffer_Init :                                                          *
  *                                                                        *
  * Proceso q inicializa la unidad de Buffer Cache  , se inicializa la     *
  * cola Lru y la cola Hash  y se calcula el numero maximo de Bufferes     *
  *                                                                        *
  **************************************************************************
}
procedure buffer_init;[public , alias :'BUFFER_INIT'];
var tmp:dword;
begin
Buffer_Lru := nil;
Buffer_Dirty := nil;
for tmp:= 1 to Nr_blk do Buffer_Hash[tmp]:=nil;

{Este numero es muy grande aunque Buffer_Use_mem solo valga 1%}
Max_Buffers := ((Buffer_Use_Mem * MM_MemFree ) div 100) div sizeof(buffer_head);

{aqui son configuradas las variables }
Max_dentrys := Max_Buffers ;
Max_Inodes := Max_dentrys ;

printk('/Vvfs/n ... Buffer - Cache /V%d /nBufferes\n',[Max_Buffers],[]);
printk('/Vvfs/n ... Inode  - Cache /V%d /nBufferes\n',[Max_Buffers],[]);

end;


end.
