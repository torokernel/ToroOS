Unit Block_Dev;

{ * Block_Dev :                                                      *
  *                                                                  *
  * Se encarga de la escritura y lectura de los dispositivos bloques *
  * Las funciones devuelven los bytes transferidos y el resultado de *
  * la operacion                                                     *                                                            *
  *                                                                  *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>       *
  * All Rights Reserved                                              *
  *                                                                  *
  * Versiones :                                                      *
  * 21 / 01 / 2005 : Es modifica la estrutura y no las lecturas se   *
  * cuentan por bloques logicos y no por bytes                       *
  *                                                                  *
  * 12 / 03 / 2004  : Primera Version                                *
  *                                                                  *
  ********************************************************************
}

interface


{$I ../include/toro/procesos.inc}
{$I ../include/head/scheduler.h}
{$I ../include/head/procesos.h}
{$I ../include/toro/buffer.inc}
{$I ../include/head/ll_rw_block.h}
{$I ../include/head/asm.h}
{$I ../include/head/devices.h}



implementation


{$I ../include/head/lock.h}




{ * Blk_Read :                                                           *
  *                                                                      *
  * Fichero : Puntero al descriptor de archivo                           *
  * count : Cantidad de bytes a leer                                     *
  * buff : Buffer donde sera movido                                      *
  * Retorno : Resultado  de la operacion                                 *
  *                                                                      *
  * Se encarga de realizar lectura sobre dispositivos de bloque a traves *
  * del buffer cache                                                     *
  *                                                                      *
  ***********************************************************************
}
function blk_read(Fichero : p_file_t ; count : dword ; buff : pointer):dword;[public , alias : 'BLK_READ'];
var cont , blk , mayor , menor , size :dword;
begin

cont := 0 ;
blk := fichero^.f_pos;

mayor := Fichero^.inodo^.mayor ;
menor := Fichero^.inodo^.menor ;
size := fichero^.inodo^.sb^.blocksize;


repeat

{la lectura se realiza sin cache}
If Read_Sync_Block (mayor,menor,blk,size,buff) = -1 then break;

{se actualizan los contadores}
buff += size ;
cont += 1;
blk += 1;
fichero^.f_pos += 1;

until (cont = count) ;

{ Salgo con el contador }
exit(cont);
end;



{ * Blk_Write :                                                         *
  *                                                                     *
  * Fichero : Puntero al decriptor de archivoq                          *
  * count : Contador                                                    *
  * buff : Buffer de usuario                                            *
  * Retorno : Nuemero de bloques escritos                               *
  *                                                                     *
  * Funcion que escribe sobre un bloque a traves del cache de bloques   *
  *                                                                     *
  ***********************************************************************
}
function blk_write(Fichero : p_file_t ; count : dword ; buff : pointer):dword;[public ,alias : 'BLK_WRITE'];
var cont , blk , size,mayor , menor :dword;
begin

cont := 0 ;
blk := Fichero^.f_pos ;
mayor := Fichero^.inodo^.mayor;
menor := Fichero^.inodo^.menor;
size := fichero^.inodo^.sb^.blocksize;

repeat

if Write_Sync_Block (mayor,menor,blk,size,buff) = -1 then break;


buff += size;
cont += 1;
blk += 1 ;
fichero^.f_pos += 1;

until (cont = count) ;

{ Salgo con el contador }
exit(cont);
end;


end.
