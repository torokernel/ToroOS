Unit Syscall;

{ * Syscall:
  *                                                                         *
  * Aqui se trata la interrupcion de soft 50 , con  DPL 3  , los parametros *
  * de las funciones son pasados por los registros  , lo cual limite hasta  *
  * 6 parametros  , el array Syscall_Table mantiene la lista de punteros    *
  * de las syscall del sistema                                              *
  *                                                                         *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>              *
  * All Rights Reserved                                                     *
  *                                                                         *
  * Versiones :                                                             *
  * 10 / 03 / 2004 : Version Inicial                                        *
  *                                                                         *
  ***************************************************************************
}
interface

const
  NR_SYSCALL = 50;

var syscall_table:array [0..NR_SYSCALL] of pointer;
procedure Syscall_Init;

implementation
uses arch, process, memory, filesystem;

{ * Kernel_Entry :                                                       *
  *                                                                      *
  * Procedimiento que captura las Int. de soft  , busca la syscall segun *
  * eax y salta a su puntero                                             *
  *                                                                      *
  ************************************************************************
}

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



{ * Sycall_Init :                                                        *
  *                                                                      *
  * Proceso que es llamado solo una vez al cargar el nucleo , este inic  *
  * ializa el array de punteros que mantiene las syscall , syscall_table *
  *                                                                      *
  ************************************************************************
}
procedure Syscall_Init;
var 
m: dword;
begin
Set_Int_Gate_User(50,@kernel_entry);
for m := 0 to 34 do
  syscall_table[m] := nil;

syscall_table[0]:= @Sys_MountRoot; {Solo puede ser llamada una vez}
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
