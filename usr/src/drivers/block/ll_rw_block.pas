Unit ll_rw_block;

{ * ll_Rw_Block :                                                       *
  *                                                                     *
  * Esta unidad se encarga de los accesos a los dispositivos de bloque  *
  * por parte del kernel debido a que el kernel no trabaja con descrip  *
  * tores de archivos                                                   *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 25 / 05 / 2005 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************
}

interface


{$I ../../include/head/asm.h}
{$I ../../include/toro/procesos.inc}
{$I ../../include/toro/buffer.inc}
{$I ../../include/head/buffer.h}
{$I ../../include/head/devices.h}
{$I ../../include/head/procesos.h}
{$I ../../include/head/scheduler.h}
{$I ../../include/head/printk_.h}
{$I ../../include/head/malloc.h}
{$I ../../include/head/paging.h}
{$I ../../include/head/mm.h}


const block_size = 512 ;

implementation

{$I ../../include/head/lock.h}


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
