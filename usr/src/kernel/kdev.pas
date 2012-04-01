Unit kdev;

{ * Kdev :                                                              *
  *                                                                     *
  * Unidad encarga del driver de kernel implementada para permitir el   *
  * acceso a variables del kernel  , en un futuro puede tener mas       *
  * implementaciones  , por ahora solo da acceso a un par de variables  *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  *                                                                     *
  * Versiones                                                           *
  *                                                                     *
  * 02 / 03 / 2006 : Primer Version                                     *
  *                                                                     *
  ***********************************************************************
}

interface

{$I ../include/toro/kdev.inc}
{$I ../include/head/printk_.h}
{$I ../include/toro/procesos.inc}
{$I ../include/toro/buffer.inc}
{$I ../include/head/procesos.h}
{$I ../include/head/devices.h}
{$I ../include/head/mm.h}
{$I ../include/head/malloc.h}
{$I ../include/head/cpu.h}
{$I ../include/head/gdt.h}
{$I ../include/head/inodes.h}
{$I ../include/head/dcache.h}
{$I ../include/head/paging.h}
{$I ../include/head/buffer.h}




var kdev_ops : file_operations ;

implementation


{ * kdev_ioctl :                                                        *
  *                                                                     *
  * Fichero : Puntero al descriptor de fichero                          *
  * req : numero de peticion                                            *
  * argp : Puntero a los argumentos                                     *
  *                                                                     *
  * Llamada de control al dispositivo de kernel                         *
  *                                                                     *
  ***********************************************************************
}
function kdev_ioctl (fichero : p_file_t ; req : dword ; argp : pointer ) : dword ;
var tmp : ^dword;
begin

tmp := argp ;

{ el unico numero menor es el 0 }
if fichero^.inodo^.rmenor <> 0 then exit(-1);

case req of
kdev_mem_free : tmp^ := mm_memfree ;
kdev_mem_all : tmp^ := mm_totalmem ;
kdev_mem_free_page : tmp^ := nr_free_page ;
kdev_mem_alloc : tmp^ := Mem_alloc ;
kdev_cpu_type : tmp^ := p_cpu.marca;
kdev_cpu_family : tmp^ := p_cpu.family ;
kdev_cpu_model : tmp^ := p_cpu.model ;
kdev_gdt_free : tmp^ := gdt_huecos_libres ;
kdev_fs_buffer_use_mem : tmp^ := buffer_use_mem ;
kdev_fs_free_buffers : tmp^ := Max_Buffers ;
kdev_fs_free_Inodes : tmp^ := Max_Inodes ;
kdev_fs_free_dentrys : tmp^ := MaX_dentrys ;
else exit(-1);
end;

exit(0);
end;


procedure kdev_init ; [public , alias :'KDEV_INIT'];
begin

kdev_ops.write := nil;
kdev_ops.read := nil;
kdev_ops.open := nil;
kdev_ops.ioctl := @kdev_ioctl ;

register_chrdev (kdev_mayor,'kdev',@kdev_ops);
printk('/nIniciando kdev0 ... /VOk\n',[]);
end;

end.


