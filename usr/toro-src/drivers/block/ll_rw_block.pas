Unit ll_rw_block;

{ * ll_Rw_Block :                                                       *
  *                                                                     *
  * Esta unidad se encarga de los accesos a los dispositivos de bloque  *
  * por parte del kernel debido a que el kernel no trabaja con descrip  *
  * tores de archivos                                                   *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 25 / 05 / 2005 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************
}

interface


{$I ../../Include/Head/asm.h}
{$I ../../Include/Toro/procesos.inc}
{$I ../../Include/Toro/buffer.inc}
{$I ../../Include/Head/buffer.h}
{$I ../../Include/Head/devices.h}
{$I ../../Include/Head/procesos.h}
{$I ../../Include/Head/scheduler.h}
{$I ../../Include/Head/printk_.h}
{$I ../../Include/Head/malloc.h}
{$I ../../Include/Head/paging.h}
{$I ../../Include/Head/mm.h}


const block_size = 512 ;

implementation

{$I ../../Include/Head/lock.h}


{ * Buffer_Read :                                                       *
  *                                                                     *
  * Puntero a un buffer_head                                            *
  * Retorno : 0 si ok o -1 si falla                                     *
  *                                                                     *
  * Funcion q lee del disco un buffer                                   *
  *                                                                     *
  ***********************************************************************
}

function buffer_read ( Bh : P_buffer_head):dword;[public , alias :'BUFFER_READ'];
var fd : file_t ;
    i : inode_t ;
    res : dword ;
begin

buffer_lock (@bh^.wait_on_buffer);

{Es creado el inodo temporal}
fd.inodo := @i ;
fd.f_pos := bh^.bloque * ( bh^.size div block_size) ;

i.rmayor := bh^.mayor ;
i.rmenor := bh^.menor ;

res := Blk_Dev[bh^.mayor].fops^.read (@fd , (bh^.size div block_size) , bh^.data);

If res <> (bh^.size div block_size) then buffer_Read := -1  else Buffer_Read := 0;


buffer_unlock (@bh^.wait_on_buffer);

end;





{ * Buffer_Write :                                                         *
  *                                                                        *
  * Buffer : Puntero a un buffer_head                                      *
  * Retorno : 0 si ok o -1 si falla                                        *
  *                                                                        *
  * Funcion q escribe sobre el disco un buffer dado                        *
  *                                                                        *
  **************************************************************************
}

function buffer_write(bh:p_buffer_head):dword;[public , alias : 'BUFFER_WRITE'];
var fd : file_t ;
    i : inode_t ;
    res: dword ;
begin

buffer_lock (@bh^.wait_on_buffer);

{ Es creado el inodo temporal }
fd.inodo := @i ;
fd.f_pos := bh^.bloque * ( bh^.size div block_size) ;

i.rmayor := bh^.menor ;
i.rmenor := bh^.menor ;


res := Blk_Dev[bh^.mayor].fops^.write (@fd ,(bh^.size div block_size) , bh^.data);

If res <> (bh^.size div block_size) then Buffer_Write := -1 else Buffer_Write := 0 ;


buffer_unlock (@bh^.wait_on_buffer);

end;


{ * Read_Async_Block :                                                     *
  *                                                                        *
  * Realiza la lectura de un bloque sin el cache                           *
  *                                                                        *
  **************************************************************************
}
function Read_Sync_Block (mayor,menor,bloque,size : dword ; buffer : pointer):dword ; [public , alias  :'READ_SYNC_BLOCK'];
var bh : buffer_head ;
begin

bh.wait_on_buffer.lock := false;
bh.mayor := mayor ;
bh.menor := menor ;
bh.size := size ;
bh.data := buffer ;

exit(buffer_read(@bh));
end;


{ * Write_Sync_Block                                                    *
  *                                                                     *
  * Realiza la escritura de un bloque sin cache                         *
  *                                                                     *
  ***********************************************************************
}
function Write_Sync_Block (mayor,menor,bloque,size : dword ; buffer : pointer):dword;[public , alias : 'WRITE_SYNC_BLOCK'];
var bh : buffer_head ;
begin

bh.wait_on_buffer.lock := false;
bh.mayor := mayor ;
bh.menor := menor ;
bh.size := size ;
bh.data := buffer ;

exit(buffer_write(@bh));
end;



end.
