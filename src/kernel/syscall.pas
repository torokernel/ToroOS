//
// syscall.pas
//
// This unit contains the syscall interface.
// 
// Copyright (c) 2003-2022 Matias Vara <matiasevara@gmail.com>
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
Unit Syscall;

interface

const
  NR_SYSCALL = 50;

var syscall_table:array [0..NR_SYSCALL] of pointer;
procedure Syscall_Init;

implementation
uses arch, process, memory, filesystem;

procedure kernel_entry;assembler;
asm
   push  eax
   push  es
   push  ds
   push  ebp
   push  edi
   push  esi
   push  edx
   push  ecx
   push  ebx


    mov   edx, KERNEL_DATA_SEL
    mov   ds , dx
    mov   es , dx



   cmp   eax , NR_SYSCALL
   jg    @error


   shl   eax, 2
   lea   edi, syscall_table
   mov   ebx, dword [edi + eax]
   sti
   call  ebx
   jmp @ret_to_user_mode


   @error:
    mov  eax , -EINVAL

   @ret_to_user_mode:
      mov   dword [esp+32], eax
      pop   ebx
      pop   ecx
      pop   edx
      pop   esi
      pop   edi
      pop   ebp
      pop   ds
      pop   es
      pop   eax
      iret
   end;


procedure Syscall_Init;
var 
m: dword;
begin
Set_Int_Gate_User(50,@kernel_entry);
for m := 0 to 34 do
  syscall_table[m] := nil;

syscall_table[0]:= @Sys_MountRoot;
Syscall_Table[1]:= @Sys_Exit;
Syscall_Table[2]:= @Sys_Fork;{
Syscall_Table[3]:= @Sys_Mkdir;
Syscall_Table[4]:= @Sys_Mknod;
Syscall_Table[5]:= @Sys_Create;
}Syscall_Table[6]:= @Sys_Open;
SYSCALL_Table[7]:= @Sys_WaitPid;
Syscall_Table[8]:= @Sys_Read;
Syscall_Table[9]:= @Sys_Write;
{Syscall_Table[10]:= @Sys_Close;
Syscall_Table[12]:= @Sys_Chmod;
Syscall_Table[13]:= @Sys_Time;
Syscall_Table[14]:= @Sys_Rename;
Syscall_Table[15]:= @Sys_Mount;
Syscall_Table[16]:= @Sys_Unmount;
Syscall_Table[17]:= @Sys_sleep;
Syscall_Table[18]:= @sys_setitimer;
Syscall_Table[19]:= @Sys_GetPid;
Syscall_Table[20]:= @Sys_GetPPid;
Syscall_Table[21]:= @Sys_Detener;}
Syscall_Table[22] := @Sys_Stat;{
Syscall_Table[23] := @Sys_Utime;
Syscall_Table[24] := @Sys_Stime ;
}Syscall_Table[25]:= @SysExec;
{Syscall_Table[26] := @sys_getitimer;}
Syscall_Table[27] := @Sys_chdir ;
Syscall_Table[28] := @Sys_ReadErrno ;{
syscall_Table[29] := @sys_setscheduler ;
syscall_table[31] := @sys_getscheduler ;
Syscall_Table[36]:= @Sys_Sync;
}Syscall_Table[45]:= @Sys_Brk;
{Syscall_Table[37]:= @Sys_Kill;
Syscall_Table[48]:= @Sys_Signal;
}
Syscall_Table[30]:= @Sys_Seek;
syscall_table [33] := @Sys_Ioctl;
{syscall_table[32] := @Reboot ;
syscall_table[34] := @sys_rmdir;}
end;



end.
