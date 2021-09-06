
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


{$M 2048,4096}

uses multiboot, printk, arch, memory, process, filesystem, syscall, dma, floppy, tty, fat;
{$define SHELL_PATH := '/bin/sh' }

procedure init_;
var tmp:dword;
    path: PChar;
begin
asm
// MountRoot
xor eax , eax
int 50
end;
path := SHELL_PATH;
asm
// Exec
mov eax , 25
mov ebx , path
mov ecx , 0
int 50
// WaitPid
@loop:
mov eax , 7
mov ebx , tmp
int 50
mov tmp , ebx
jmp @loop 
end;
end;

var Init_proc , Null : p_tarea_struc;
    init_Page , Stack : pointer;
    ttyino , keybino : p_inode_t ;
    ttyfile,keybfile : p_file_t ;
    r : dword ;
 
{$I ../arch/macros.inc}

begin
cerrar;
printkf('/nLoading Toro... \n',[]);
ArchInit;
MMInit;
Process_Init;
Devices_Init;
Syscall_Init;
dma_init;
Fd_Init;
tty_Init;
Buffer_Init;
fatfs_init;

 // init task 
 Init_proc := Proceso_Crear(1,Sched_RR);
 
 Init_Page:= get_free_page;
 stack:= get_free_page;
 umapmem(stack,pointer(HIGH_MEMORY),Init_Proc^.dir_page,Present_Page  or Write_Page or User_mode);
 umapmem(Init_Page,pointer(HIGH_MEMORY+Page_Size),Init_Proc^.dir_page,Present_Page or User_mode);

 memcopy(@Init_,Init_Page,Page_Size);

With Init_Proc^ do
 begin
 text_area.add_l_comienzo := pointer(HIGH_MEMORY + Page_Size);
 text_area.add_l_fin := pointer(HIGH_MEMORY + 2 * Page_Size);
 text_area.size := Page_Size;
 text_area.flags := VMM_READ;

 stack_area.add_l_comienzo := pointer(HIGH_MEMORY);
 stack_area.add_l_fin := pointer(HIGH_MEMORY + Page_Size - 1);
 stack_area.size := Page_Size;
 stack_area.flags := VMM_WRITE;

 reg.eip:= pointer(HIGH_MEMORY + Page_Size);
 reg.esp := pointer(HIGH_MEMORY + Page_Size -1);
end;

add_task(Init_Proc);

ttyino := kmalloc(sizeof(inode_t));
ttyfile := @Init_proc^.Archivos[1];

keybino := kmalloc (sizeof(inode_t));
keybfile := @Init_proc^.Archivos[2];

ttyino^.mode := dt_chr ;
ttyino^.flags := I_RO or I_WO ;
ttyino^.rmayor := tty_mayor ;
ttyino^.rmenor := 0  ;
ttyfile^.f_op := chr_dev[tty_mayor].fops ;
ttyfile^.inodo := ttyino ;
ttyfile^.f_mode := O_RDWR ;

ttyfile^.f_pos := y * 160 + x * 2 ;
keybino^.mode := dt_chr ;
keybino^.flags := I_RO or I_WO ;
keybino^.rmayor := keyb_mayor ;
keybino^.rmenor := 0  ;
keybfile^.f_op := chr_dev[keyb_mayor].fops ;

keybfile^.inodo := keybino ;
keybfile^.f_mode := O_RDWR ;

cerrar;
scheduler_init;
Scheduling;

while true do;
	{	
kdev_Init;
}
end.
