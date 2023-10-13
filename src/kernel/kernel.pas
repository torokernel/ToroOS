//
// kernel.pas
//
// This program contains the initialization of the kernel.
//
// Copyright (c) 2003-2023 Matias Vara <matiasevara@torokernel.com>
// All Rights Reserved
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

{$M 2048,4096}

uses multiboot, printk, arch, memory, process, filesystem, syscall, dma,
floppy, tty, fat;

{$define SHELL_PATH := '/bin/sh' }

procedure init_;
var
  tmp: DWORD;
  path: PChar;
begin
  asm
  // mount root fs
  xor eax , eax
  int 50
  end;
  path := SHELL_PATH;
  asm
  // exec the shell
  mov eax , 25
  mov ebx , path
  mov ecx , 0
  int 50
  // wait
  @loop:
    mov eax , 7
    mov ebx , tmp
    int 50
    mov tmp , ebx
    jmp @loop
  end;
end;

var
  Init_proc, Null: p_tarea_struc;
  init_Page, Stack: pointer;
  ttyino, keybino: p_inode_t;
  ttyfile, keybfile: p_file_t;
  r: DWORD;

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
  TtyInit;
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
  ttyfile := @Init_proc^.Archivos[F_STDOUT];

  keybino := kmalloc (sizeof(inode_t));
  keybfile := @Init_proc^.Archivos[F_STDIN];

  ttyino^.mode := dt_chr ;
  ttyino^.flags := I_RO or I_WO ;
  ttyino^.rmayor := TTY_NR_MAJOR;
  ttyino^.rmenor := 0  ;
  ttyfile^.f_op := chr_dev[TTY_NR_MAJOR].fops ;
  ttyfile^.inodo := ttyino ;
  ttyfile^.f_mode := O_RDWR ;
  ttyfile^.f_pos := y * 160 + x * 2 ;

  keybino^.mode := dt_chr ;
  keybino^.flags := I_RO or I_WO ;
  keybino^.rmayor := KEYB_NR_MAJOR;
  keybino^.rmenor := 0  ;
  keybfile^.f_op := chr_dev[KEYB_NR_MAJOR].fops ;
  keybfile^.inodo := keybino ;
  keybfile^.f_mode := O_RDWR ;

  cerrar;
  scheduler_init;
  Scheduling;

  while true do;
end.
