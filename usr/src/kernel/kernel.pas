
{ * Toro Kernel :                                                     *
  *                                                                   *
  * Este el kernel de TORO , aqui son cargados todos los modulos y la *
  * tarea inicial INIT , luego se entra en un bucle al que nunca se   *
  * devera llegar                                                     *
  *                                                                   *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>        *
  * All Rights Reserved                                               *
  *                                                                   *
  * Versiones :                                                       *
  * 17 / 02 / 2006 : Version 1.1.2 del kernel Toro .Autor Matias Vara *
  * 16 / 10 / 2005 : Es eliminado el thread nulo!!!                   *
  *                                                                   *
  * 31 / 07 / 2005 : Version 1.1 del kernel Toro . Autor Matias Vara  *
  *                                                                   *
  * 29 / 04 / 2005 : Version 1.0.4 .Autor Matias Vara                 *
  *                                                                   *
  * 10 / 02 / 2005 : Se aplica un VFS para dispositivos hard          *
  * Toro version 1.0.3                                                *
  *                                                                   *
  * 02 / 08 / 2004 : Es creada la tarea inicial desde aqui , se aplica*
  * el modelo paginado de memoria                                     *
  *                                                                   *
  * 20 / 05 / 2004 : Version Inicial . Autor Matias Vara              *
  *                                                                   *
  *********************************************************************
}


{$I-}
{$M 2048,4096}

{$I ../include/head/asm.h}
{$I ../include/toro/procesos.inc }
{$I ../include/toro/buffer.inc}
{$I ../include/head/gdt.h}
{$I ../include/head/malloc.h}
{$I ../include/head/vmalloc.h}
{$I ../include/head/mm.h}
{$I ../include/head/paging.h}
{$I ../include/head/mapmem.h}
{$I ../include/head/init_.h}
{$I ../include/head/cpu.h}
{$I ../include/head/idt.h}
{$I ../include/head/relog.h}
{$I ../include/head/ll_rw_block.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/procesos.h}
{$I ../include/head/syscall.h}
{$I ../include/head/devices.h}
{$I ../include/head/irq.h}
{$I ../include/head/printk_.h}
{$I ../include/head/dma.h}
{$I ../include/head/fat12fs/super.h}
{$I ../include/toro/drivers/tty.inc}
{$I ../include/toro/drivers/keyb.inc}

{Procedimiento que inicializan los drivers , por ahora se inician con el}
{kernel}

procedure pci_init;external name 'PCI_INIT';
procedure Buffer_Init;external name 'BUFFER_INIT';
procedure Fd_Init;external name 'FD_INIT';
procedure Keyb_Init;external name 'KEYB_INIT';
procedure Tty_Init;external name 'TTY_INIT';
procedure kdev_init ;external name 'KDEV_INIT';

var Init_proc , Null : p_tarea_struc;
    init_Page , Stack : pointer;
    ttyino , keybino : p_inode_t ;
    ttyfile,keybfile : p_file_t ;
    r : dword ;

begin
cerrar;
printk('/nCargando Sistema TORO... \n',[]);

{Son cargados todos los modulos del sistema}
Gdt_Init;
Mm_Init;


Idt_Init;
Cpu_Init;

Proceso_Init;
Devices_Init;
Syscall_Init;

{Son inicializados los drivers}
dma_init;
Fd_Init;
tty_Init;
while true do;
kdev_Init;

Buffer_Init;

fatfs_init;

Init_Task;

cerrar;

scheduler_init;
Scheduling;


debug($1987);
end.
