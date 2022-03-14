//
// floppy.pas
//
// This unit contains functions to manipulate the floppy.
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
Unit Floppy;



interface

uses filesystem, arch, process, dma, printk, memory; 

{$DEFINE fd_lock := lock (@fd_wait) }
{$DEFINE fd_unlock := unlock (@fd_wait) }
{$define dma_lock := lock }
{$define dma_unlock := unlock }

const fls : array[0..1] of boolean = (false,false);
      fd_state_motor : array[0..1] of boolean = ( false , false) ;


const head  : byte = 0 ;
      cyl   : byte = 0 ;
      sector : byte = 0 ;


var
    Fd_ops : file_operations ;

    fd_wait : wait_queue ;

    pgbuffer : pointer ;

    fd_timers_motor : array[0..1] of struc_timer_kernel ;

procedure Fd_Init;

implementation

const

PORT_ESTADO=$3F4;
PORT_DATA=$3F5;
PORT_MOTOR=$3F2;
PORT_CMOS_E=$70;
PORT_CMOS_L=$71;

ENABLED_INT=$0C;
TAM_SECTOR=512;

FDC_WRITE=$c5;
FDC_READ=$46;
FDC_RECALIBRATE=$7;
FDC_SPECIFY=$3;
FDC_SENSE=$8;
FDC_SEEK=$f;

FDC_OK=$1;
FDC_ERROR=-1;
FDC_SEEK_ERROR=-1;
FDC_SEEK_OK=$2;

FDC_WRITE_PROTEC=$2;
FDC_BAD_SECTOR=$3;
FDC_BAD_CYL=$4;

SPEC1=$df;
SPEC2=$2;

FDC_TIMEOUT=128;
MAX_FD=2;

fd_motor_timeout = 3000 ;

FDC_MAYOR = 2 ;


{$I ../arch/macros.inc}

procedure fd_log_to_chs(Log:dword);
begin
cyl:=log div 36;
head:=(log div 18) mod 2;
sector:=1 + (log mod 18);
end;



procedure fd_out(Val:byte);
var time,msr:byte;
begin
for time:= 0 to FDC_TIMEOUT do
 begin
  MSR := Leer_byte(PORT_ESTADO);
  if ((msr and $c0)=$80) then
   begin
    enviar_byte(Val,PORT_DATA);
    exit;
   end;
end;
end;



function fd_in : byte ;
var msr,time:byte;
begin

for time := 0 to FDC_TIMEOUT do
 begin
 msr := Leer_byte(PORT_ESTADO);
 if ((msr and $D0)=$D0) then exit(Leer_byte(PORT_DATA));
 end;

end;


procedure fd_on_motor(Unidad:dword);inline;
begin
enviar_byte((1 shl (unidad+4)) or ENABLED_INT  or UNIDAD,PORT_MOTOR);
end;


procedure fd_off_motor(Unidad:dword);
begin
enviar_byte( ENABLED_INT  or UNIDAD ,PORT_MOTOR);
fd_state_motor[unidad] := false ;
end;

procedure fd_recalibrate(Unidad:byte);inline;
begin
fd_on_motor(unidad);
delay_io;
fd_out(FDC_RECALIBRATE);
fd_out(unidad);
end;


procedure fd_seek(Unidad:byte);
begin
fd_out(FDC_SEEK);
fd_out((head shl 2) or unidad);
fd_out(Cyl);
end;


procedure fd_config;
begin
fd_out(FDC_SPECIFY);
fd_out($df);
fd_out(SPEC2);
end;


function fd_command_status:byte;
begin
exit(fd_in);
end;


function fd_sense_int:boolean;
var st0:byte;
begin
fd_out(FDC_SENSE);
delay_io;
st0 := Fd_Command_Status;
cyl := Fd_Command_Status;
if (st0 shr 6)=0 then FD_Sense_int := true ;                                      
end;


procedure fd_transfer ( Operacion,Unidad:byte);
var flags : dword ;
begin

cerrar;

fd_out(Operacion);
fd_out((head shl 2 ) or unidad );
fd_out(cyl);
fd_out(head);
fd_out(sector);
fd_out(2);
fd_out(0);
fd_out(0);
fd_out($ff);

abrir;
end;

function fd_transfer_result:byte;
var ret:byte;
begin

ret :=Fd_In; // st0
ret :=Fd_In; // st1
If Bit_Test(@ret,1 ) then  Fd_Transfer_Result := FDC_WRITE_PROTEC;
If Bit_Test(@ret,2)  then Fd_Transfer_Result := FDC_BAD_SECTOR;

ret:=Fd_In; // st2
If Bit_Test(@ret,1) then Fd_Transfer_Result := FDC_BAD_CYL;
ret := Fd_In;
ret := Fd_In;
ret := Fd_In;
ret := Fd_In;

Exit(0);
end;


function fd_do_seek(logpos : dword;menor : byte):dword;
label 1;
begin

fd_log_to_chs ( logpos );

1: Fd_Seek(Menor);

 Wait_Long_Irq(6);

 If not(FD_Sense_Int) then
  begin
  Fd_Recalibrate(menor);

  Wait_Long_Irq(6);

   If not(Fd_Sense_Int) then exit(-1);

  goto 1;
  end;

exit (0);
end;

function fd_write (Fichero : p_file_t ; count : dword ; buff : pointer ) : dword ;
var offset , cont : dword ;
    menor  , ret: byte ;
    buffer : pointer ;
    err : boolean ;
    label 1 , 2;
begin

Fd_Lock;

err := false ;
buffer := buff ;
cont := 0 ;

menor := fichero^.inodo^.rmenor;

if not(fls[menor]) then
 begin
  Fd_Unlock;
  exit(0);
 end;

dma_lock(@dma_wait[2]);

if fd_state_motor[menor] then del_timer (@fd_timers_motor[menor])
 else
  begin
   fd_on_motor (menor);

   delay_io;
   fd_state_motor[menor] := true ;

  end;


if fd_do_seek (fichero^.f_pos , Menor) = -1 then goto 1;

if dma_set_channel (2 , 512 , MODE_READ , pgbuffer) = -1 then goto 1 ;

repeat

memcopy (buffer , pgbuffer , 512);

2 :

Fd_Transfer (FDC_WRITE , menor );

Wait_Long_Irq(6);

ret := Fd_Transfer_Result ;

If (ret = FDC_WRITE_PROTEC) or (ret = FDC_BAD_SECTOR) or (ret = FDC_BAD_CYL) then
   if err then break
    else
     begin
      err := true ;

      fd_recalibrate (menor);

      wait_long_irq (6) ;

      goto 2 ;
     end;


cont += 1;
Buffer += 512 ;
Fichero^.f_pos += 1;

fd_log_to_chs (fichero^.f_pos);

until ( cont = count ) ;

1 :

dma_unlock (@dma_wait[2]);

fd_timers_motor[menor].timer.interval := fd_motor_timeout ;
add_timer (@fd_timers_motor[menor]);

Fd_Unlock;

exit(cont);
end;

function fd_read (Fichero : p_file_t ; count : dword ; buff : pointer ) : dword ;
var cont : dword ;
    menor  , ret: byte ;
    buffer : pointer ;
    err : boolean;
    label 1 , 2 ;

    begin

Fd_Lock;

err := false ;

buffer := buff ;
cont := 0 ;
ret := 0 ;

menor := Fichero^.Inodo^.rmenor;

if (menor > 1) or not(fls[menor]) then
 begin
 Fd_Unlock;
 exit(0);
 end;

dma_lock (@dma_wait[2]);

if fd_state_motor[menor] then del_timer (@fd_timers_motor[menor])
 else
  begin
   fd_on_motor (menor);

     delay_io;

   fd_state_motor[menor] := true ;

  end;

if fd_do_seek (Fichero^.f_pos,Menor) = -1 then goto 1;

if dma_set_channel (2 , 512 , MODE_WRITE , pgbuffer) = -1 then goto 1;

repeat

2 :

Fd_Transfer (FDC_READ , menor );

Wait_Long_Irq(6);

ret := Fd_Transfer_Result ;

If (ret = FDC_WRITE_PROTEC) or (ret = FDC_BAD_SECTOR) or (ret = FDC_BAD_CYL) then
    if err then break
    else
     begin

      err := true ;

      fd_recalibrate(menor);

      wait_long_irq (6);

      goto 2 ;
     end;
memcopy (pgbuffer , buffer , 512);

cont += 1;
Buffer += 512 ;
Fichero^.f_pos += 1;

fd_log_to_chs (fichero^.f_pos);

until ( cont = count );

1 :

fd_timers_motor[menor].timer.interval := fd_motor_timeout ;
add_timer (@fd_timers_motor[menor]);

dma_unlock (@dma_wait[2]);

Fd_Unlock;

exit(cont);
end;

procedure Fd_Init;
var tmp,a,b,disk:byte;
begin


fd_ops.seek := nil ;
fd_ops.open := nil ;
fd_ops.read := @fd_read ;
fd_ops.write := @fd_write;
fd_ops.ioctl := nil;


enviar_byte($10,PORT_CMOS_E);
tmp := Leer_byte(PORT_CMOS_L) ;

a:= tmp shr 4;
b:= tmp and $f;
disk := 0;

If a=4 then
 begin
 printkf('/nInitializing fd0 ... /VOk\n',[]);
 disk += 1;
 fls[0] := true;
 end
 else printkf('/nInitializing fd0 ... /Rfault\n',[]);


If b=4 then
 begin
 printkf('/nInitializing fd1 ... /VOk\n',[]);
 disk += 1 ;
 fls[1] := true;
 end
 else printkf('/nInitializing fd1 ... /Rfault\n',[]);

 pgbuffer := get_dma_page ;

If disk <> 0 then
 Register_BlkDev (Fdc_Mayor , 'fd' , @fd_ops );

fd_wait.lock := false;
fd_wait.lock_wait := nil;

fd_timers_motor[0].handler := @fd_off_motor ;
fd_timers_motor[0].param := 0 ;
fd_timers_motor[1].handler := @fd_off_motor ;
fd_timers_motor[1].param := 1 ;

end;



end.
