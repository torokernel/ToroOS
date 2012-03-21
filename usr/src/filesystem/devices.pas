Unit Devices;

{ * Devices :                                                           *
  *                                                                     *
  * Unidad que se encarga del acceso a los dispositivos hard atraves    *
  * del Fs  . Es una implementacion parecida al VFS de Linux            *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  * 19 / 01 / 2005 : Version Inicial                                    *
  *                                                                     *
  ***********************************************************************
}


interface


{$I ../include/head/asm.h}
{$I ../include/toro/procesos.inc}
{$I ../include/head/procesos.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/printk_.h}

{$define Use_Tail }
{$define nodo_struct := p_file_system_type }
{$define next_nodo := next_fs }
{$define prev_nodo := prev_fs }
{$define nodo_tail := Fs_type }

{$define Push_Fs := Push_Node }
{$define Pop_Fs := Pop_Node }


var Blk_Dev:array[1..Nr_Blk] of device ;
    Chr_Dev:array[Nr_Blk..Nr_Chr] of device ;
    Fs_type : p_file_system_type;


implementation

{$I ../include/head/string.h}
{$I ../include/head/list.h}


{ * Register_Filesystem :                                               *
  *                                                                     *
  * fs : Puntero a un driver de Sistema de archivo                      *
  *                                                                     *
  * Procedimiento que registra un driver de Fs                          *
  *                                                                     *
  ***********************************************************************
}
function Register_Filesystem (fs : p_file_system_type) : dword ;[public , alias :'REGISTER_FILESYSTEM'];
var tmp : p_file_system_type ;
begin

tmp := Fs_Type ;

{fue agregado el driver??}
while (tmp <> nil) do
 begin
  if tmp^.fs_id = fs^.fs_id then exit (-1);
  tmp := tmp^.next_fs ;
 end;

if fs^.read_super = nil then exit(-1);

cerrar;
Push_Fs (fs);
abrir;

exit(0);
end;



{ * Register_Chrdev :                                                   *
  *                                                                     *
  * nb : Numero mayor                                                   *
  * name : Nombre del Dispositivo                                       *
  * fops : Puntero a un array de manejadores del dispositivo            *
  *                                                                     *
  * Procedimiento que registra un dispositivo de caracteres             *
  *                                                                     *
  ***********************************************************************
}
procedure Register_Chrdev(nb : byte ; name : pchar ; fops : p_file_ops);[public , alias : 'REGISTER_CHRDEV'];
begin

If fops = nil then exit;
If (nb > Nr_Chr) or (nb < Nr_Blk) then exit;
If Chr_Dev[nb].fops <> nil then exit;

cerrar;

Chr_Dev[nb].fops := fops ;
chr_dev[nb].name[0] := char(pcharlen(name));

if byte(chr_dev[nb].name[0]) > 20 then exit ;

pcharcopy (name , Chr_Dev[nb].name);
chr_dev[nb].name[0] := char(pcharlen(name)) ;

abrir;

end;


{ * Register_Blkdev :                                                   *
  *                                                                     *
  * nb : Numero mayor                                                   *
  * name : Nombre del Dispositivo                                       *
  * fops : Puntero al array de manejadores                              *
  *                                                                     *
  * Procedimiento que registra un dispositivo de bloque                 *
  *                                                                     *
  ***********************************************************************
}
procedure Register_Blkdev (nb : byte ; name : pchar ; fops : p_file_ops);[public , alias : 'REGISTER_BLKDEV'];
begin

If fops = nil then exit ;
if nb > Nr_Blk then exit ;
If Blk_Dev[nb].fops <> nil then exit ;


cerrar;
Blk_Dev[nb].fops := fops ;
blk_dev[nb].name[0] := char(pcharlen(name)) ;

if byte(blk_dev[nb].name[0]) > 20 then exit ;

pcharcopy (name , Blk_Dev[nb].name);
blk_dev[nb].name[0] := char(pcharlen(name)) ;

abrir;

end;





procedure Devices_Init ; [public ,alias : 'DEVICES_INIT'];
var cont : dword ;
begin
cont := 0 ;
for cont := 1 to Nr_Blk do Blk_Dev[cont].fops := nil ;
for cont := Nr_Blk to Nr_Chr do Chr_Dev[cont].fops := nil ;

fs_type := nil ;

end;


end.

