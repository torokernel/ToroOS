
{ * Toro Kernel :                                                     *
  *                                                                   *
  * Este el kernel de TORO , aqui son cargados todos los modulos y la *
  * tarea inicial INIT , luego se entra en un bucle al que nunca se   *
  * devera llegar                                                     *
  *                                                                   *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>        *
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

{$I ../Include/Head/asm.h}
{$I ../Include/Toro/procesos.inc }
{$I ../Include/Toro/buffer.inc}
{$I ../Include/Head/gdt.h}
{$I ../Include/Head/malloc.h}
{$I ../Include/Head/vmalloc.h}
{$I ../Include/Head/mm.h}
{$I ../Include/Head/paging.h}
{$I ../Include/Head/mapmem.h}
{$I ../Include/Head/init_.h}
{$I ../Include/Head/cpu.h}
{$I ../Include/Head/idt.h}
{$I ../Include/Head/relog.h}
{$I ../Include/Head/ll_rw_block.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/syscall.h}
{$I ../Include/Head/devices.h}
{$I ../Include/Head/irq.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/dma.h}
{$I ../Include/Head/fat12fs/super.h}
{$I ../Include/Toro/drivers/tty.inc}
{$I ../Include/Toro/drivers/keyb.inc}

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
printk('/nCargando Sistema TORO... \n',[],[]);

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
kdev_Init;

Buffer_Init;
fatfs_init;

Init_Task;

cerrar;

scheduler_init;
Scheduling;


debug($1987);
end.
