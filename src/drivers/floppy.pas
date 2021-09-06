Unit Floppy;

{  * Floppy :                                                              *
   *                                                                       *
   * Esta unidad se encarga del manejo de la controladora de disket , que  *
   * es un circuito muy primitivo y dificil de manejar no tanto por la com *
   * plejidad sino los detalles que hay que tener                          *
   *                                                                       *
   * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>            *
   * All Rights Reserved                                                   *
   *                                                                       *
   * Versiones :                                                           *
   *                                                                       *
   * 04 / 01 / 2006 : Se Optimiza el acceso con la implementacion de timer *
   * del kernel para el apagado de motores                                 *
   *                                                                       *
   * 15 / 10 / 2005 : Se soluciona el bug para reintentar operaciones      *
   * fallidas                                                              *
   *                                                                       *
   * 19 / 01 / 2005 : Se modifican las estructuras de los drivers dando    *
   * soporte al VFS                                                        *
   *                                                                       *
   * 10 / 01 / 2004 : Primera Version                                      *
   *                                                                       *
   *************************************************************************

}


interface

uses filesystem, arch, process, dma, printk, memory; 

{ macros para entender mas los procedimientos }
{$DEFINE fd_lock := lock (@fd_wait) }
{$DEFINE fd_unlock := unlock (@fd_wait) }
{$define dma_lock := lock }
{$define dma_unlock := unlock }

const fls : array[0..1] of boolean = (false,false);

      { estado de los motores }
      fd_state_motor : array[0..1] of boolean = ( false , false) ;


const head  : byte = 0 ;
      cyl   : byte = 0 ;
      sector : byte = 0 ;


var
    Fd_ops : file_operations ;

    { cola de procesos esperando por el recurso }
    fd_wait : wait_queue ;

    { pagina DMA }
    pgbuffer : pointer ;


    { timers que controlan el apagado de motores }
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

{ se esperan 3 seg para apagar los motores }
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




{ * fd_on_motor : prende el motor de la unidad dada * }

procedure fd_on_motor(Unidad:dword);inline;
begin
enviar_byte((1 shl (unidad+4)) or ENABLED_INT  or UNIDAD,PORT_MOTOR);
end;


{ * fd_off_motor : apaga el motor de la unidad dada * }

procedure fd_off_motor(Unidad:dword);
begin
enviar_byte( ENABLED_INT  or UNIDAD ,PORT_MOTOR);
fd_state_motor[unidad] := false ;
end;



{ * fd_recalibrate : Recalibra la unidad dada , es llamada luego de un *
  * seek erroneo                                                       *
  *                                                                    *
}
procedure fd_recalibrate(Unidad:byte);inline;
begin
fd_on_motor(unidad);
delay_io;
fd_out(FDC_RECALIBRATE);
fd_out(unidad);
end;


{ * fd_seek : realiza el posicionamiento del cabezal sobre el cyl * }

procedure fd_seek(Unidad:byte);
begin
fd_out(FDC_SEEK);
fd_out((head shl 2) or unidad);
fd_out(Cyl);
end;



{ * fd_config : configura la unidad * }

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
if (st0 shr 6)=0 then FD_Sense_int := true ;                                        {operacion se realizo correctamente}
end;



{ * fd_transfer : inicializa la tranferencia de la controladora * }

procedure fd_transfer ( Operacion,Unidad:byte);
var flags : dword ;
begin

{ Una Int aqui podria afectar al sistema }
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

{ Salgo de la zona critica }
abrir;

end;

{ * fd_transfer_result : lee la fase de resultados luego de una operacion * }

function fd_transfer_result:byte;
var ret:byte;
begin

{ Deveran ser leidos obligatoriamente }
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


{ * coloca el cabezal sobre el sector * }

function fd_do_seek(logpos : dword;menor : byte):dword;
label 1;
begin

{ Lugar donde devo empezar!! }
fd_log_to_chs ( logpos );

{ Se realiza el seek sobre el sector }
1: Fd_Seek(Menor);

 Wait_Long_Irq(6);

 { El seek produjo un error }
 If not(FD_Sense_Int) then
  begin
  Fd_Recalibrate(menor);

  Wait_Long_Irq(6);

   { No se pudo recalibrar salgo con error }
   If not(Fd_Sense_Int) then exit(-1);

  { Se recalibro , vuelvo a hacer un seek }
  goto 1;
  end;

exit (0);
end;



{ * fd_write :                                                          *
  *                                                                     *
  * Fichero : puntero a un descriptor de archivo                        *
  * count : contador                                                    *
  * buff : puntero a un buffer de usuario                               *
  *                                                                     *
  * Handler que realiza la escritura de un sector                       *
  *                                                                     *
  ***********************************************************************
}
function fd_write (Fichero : p_file_t ; count : dword ; buff : pointer ) : dword ;
var offset , cont : dword ;
    menor  , ret: byte ;
    buffer : pointer ;
    err : boolean ;
    label 1 , 2;
begin

{ protejo de posibles accesos }
Fd_Lock;

err := false ;
buffer := buff ;
cont := 0 ;


{ Calculo el dispostivo logico }
menor := fichero^.inodo^.rmenor;

{ Numero menor invalido }
if not(fls[menor]) then
 begin
  Fd_Unlock;
  exit(0);
 end;

{ se protege el recurso }
dma_lock(@dma_wait[2]);


{ si el motor esta prendido se quita el kernel que lo apaga!! }
if fd_state_motor[menor] then del_timer (@fd_timers_motor[menor])
 else
  begin
   fd_on_motor (menor);

   { Retardo para que se prendan los motores }
   delay_io;
   fd_state_motor[menor] := true ;

  end;


if fd_do_seek (fichero^.f_pos , Menor) = -1 then goto 1;

{coloco la pagina dma}
if dma_set_channel (2 , 512 , MODE_READ , pgbuffer) = -1 then goto 1 ;

repeat

memcopy (buffer , pgbuffer , 512);

2 :

Fd_Transfer (FDC_WRITE , menor );

{ Espero la Irq }
Wait_Long_Irq(6);

ret := Fd_Transfer_Result ;

{ Hubo un error  , si es el segundo sale con el error }
If (ret = FDC_WRITE_PROTEC) or (ret = FDC_BAD_SECTOR) or (ret = FDC_BAD_CYL) then
   if err then break
    { de lo contrario la operacion se realiza de nuevo }
    else
     begin
      err := true ;

      { luego del error recalibro }
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

{se libera el recurso}
dma_unlock (@dma_wait[2]);

{ se crea el timer que apaga el motor de la unidad en 3 seg }

fd_timers_motor[menor].timer.interval := fd_motor_timeout ;
add_timer (@fd_timers_motor[menor]);


{ Libero el device }
Fd_Unlock;

{ Salgo con la cantidad de bloques transferidos }
exit(cont);
end;





{ * fd_read :                                                           *
  *                                                                     *
  * fichero : Puntero a un descriptor de archivo                        *
  * count : contador                                                    *
  * buff : buffer de usuario                                            *
  *                                                                     *
  * handler que realiza la lectura de un bloque                         *
  *                                                                     *
  ***********************************************************************
}
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

{ Calculo el dispostivo logico }
menor := Fichero^.Inodo^.rmenor;

{ Numero menor invalido }
if (menor > 1) or not(fls[menor]) then
 begin
 Fd_Unlock;
 exit(0);
 end;

dma_lock (@dma_wait[2]);

{ si el motor esta prendido se quita el timer del kernel que lo apaga!! }
if fd_state_motor[menor] then del_timer (@fd_timers_motor[menor])
 else
  begin
   fd_on_motor (menor);

   { Retardo para que se prendan los motores }
     delay_io;

   fd_state_motor[menor] := true ;

  end;

if fd_do_seek (Fichero^.f_pos,Menor) = -1 then goto 1;

{ Es preparado el canal Dma }
if dma_set_channel (2 , 512 , MODE_WRITE , pgbuffer) = -1 then goto 1;

repeat

2 :

Fd_Transfer (FDC_READ , menor );

 { Espero la Irq }
Wait_Long_Irq(6);

ret := Fd_Transfer_Result ;

{ Hubo un error }
If (ret = FDC_WRITE_PROTEC) or (ret = FDC_BAD_SECTOR) or (ret = FDC_BAD_CYL) then
    if err then break
    else
     begin

      err := true ;

      { si es el primer error se realiza de nuevo la operacion }
      fd_recalibrate(menor);

      wait_long_irq (6);

      goto 2 ;
     end;
memcopy (pgbuffer , buffer , 512);

{ Se aumentan los contadores }
cont += 1;
Buffer += 512 ;
Fichero^.f_pos += 1;

fd_log_to_chs (fichero^.f_pos);

until ( cont = count );

1 :

{ se crea el timer que apaga el motor de la unidad en 3 seg }
fd_timers_motor[menor].timer.interval := fd_motor_timeout ;
add_timer (@fd_timers_motor[menor]);

dma_unlock (@dma_wait[2]);

Fd_Unlock;

{ Salgo con la cantidad de bloques transferidos }
exit(cont);

end;


{ * Fd_Init:                                                       *
  *                                                                *
  * Proceso que se llama al inicio de TORO  y busca las disketeras *
  * existentes y las registra en el Registro de dispositivos       *
  *                                                                *
  ******************************************************************
}
procedure Fd_Init;
var tmp,a,b,disk:byte;
begin


{ Establesco los handlers del dispositivo }
fd_ops.seek := nil ;
fd_ops.open := nil ;
fd_ops.read := @fd_read ;
fd_ops.write := @fd_write;
fd_ops.ioctl := nil;


{ Se leera la cmos para saber la cantidad de disketeres }
enviar_byte($10,PORT_CMOS_E);
tmp := Leer_byte(PORT_CMOS_L) ;

a:= tmp shr 4;
b:= tmp and $f;
disk := 0;

If a=4 then
 begin
 printkf('/nIniciando fd0 ... /VOk\n',[]);
 disk += 1;
 fls[0] := true;
 end
 else printkf('/nIniciando fd0 ... /Rfault\n',[]);


If b=4 then
 begin
 printkf('/nIniciando fd1 ... /VOk\n',[]);
 disk += 1 ;
 fls[1] := true;
 end
 else printkf('/nIniciando fd1 ... /Rfault\n',[]);

 { unica pagina utilizada como buffer }
 pgbuffer := get_dma_page ;

 { Registro el numero mayor }
If disk <> 0 then
 Register_BlkDev (Fdc_Mayor , 'fd' , @fd_ops );

{ Se marca como devices libre }
fd_wait.lock := false;
fd_wait.lock_wait := nil;
{ timers para el apagado de los motores }

fd_timers_motor[0].handler := @fd_off_motor ;
fd_timers_motor[0].param := 0 ;
fd_timers_motor[1].handler := @fd_off_motor ;
fd_timers_motor[1].param := 1 ;

end;



end.
