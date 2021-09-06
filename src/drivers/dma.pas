Unit Dma;

{ * Dma :                                                       *
  *                                                             *
  * Unidad q se encarga del manejo de del controlador de dma ,  *
  * por ahora se realiza una utilizacion simple , y solo        *
  * trabaja sobre el buffer de dma , en el futuro utilizara     *
  * paginas dma solicitadas al modulo de memoria                *
  *                                                             *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>  *
  * All Rights Reserved                                         *
  *                                                             *
  * Versiones :                                                 *
  *                                                             *
  * 31 / 07 / 2005 : Ahora utiliza paginas dma                  *
  *                  solicitadas al modulo de memoria           *
  * 11 / 05 / 2005 : Ultima Revision                            *
  *                                                             *
  ***************************************************************
}

Interface

uses arch, printk, process, memory;

const
MODE_WRITE      = $04;                         { Escribir en memoria }
MODE_READ       = $08;                             { Leer de memoria }

var dma_flags : word ;
    dma_wait : array[0..7] of wait_queue;

procedure dma_init;
function dma_set_channel(ichan:dword;uSize:Word;bMode:byte;buffer:pointer):dword;

Implementation

{$I ../arch/macros.inc}
Const

{- Leer bits del registro de estado ($08, $D0) ----------------------}
STATUS_REQ3 = $80;           { Bit activo: canal DMA correspondiente }
STATUS_REQ2 = $40;               { obtuvo peticion DMA.              }
STATUS_REQ1 = $20;               { Request                           }
STATUS_REQ0 = $10;
STATUS_TC3  = $08;             { Bit activo: desde la última lectura }
STATUS_TC2  = $04;             { del registro de estado se terminó   }
STATUS_TC1  = $02;             { una transferencia DMA.              }
STATUS_TC0  = $01;             { Terminal Count                      }

{= Escribir bit del registro de comandos ($08, $D0) =================}

COMMAND_DACKLEVEL = $80; { Bit 7 activo: Línea DMA Acknowledge    }
                         { HIGH activo                            }
COMMAND_DREQLEVEL = $40; { Bit 6 activo: línea REQ Acknowledge    }
                         { LOW activo                             }
COMMAND_EXTWRITE = $20; { Bit 5 activo:  EXTENDED Write, }
                        { sino LATE Write                }
COMMAND_FIXEDPRI = $10; { Bit 4 activo: prioridad fija }
COMMAND_COMPRESS = $08; { Bit 3 activo: ciclo comprimido }
COMMAND_INACTIVE = $04; { Bit 2 activo: controlador desactivado }
COMMAND_ADH0     = $02; { Bit 1 activo: Adress Hold para canal  }
                        { 0/4 desactivados                      }
COMMAND_MEM2MEM  = $01; {- Bit 0 activo: memoria/memoria,    }
                        { sino memoria/periferia             }

{= Escribir bits del Request-Register ( $09, $D2 ) ==================}
REQUEST_RESERVED = $F8;                 { Bits reservados siempre =0 }
REQUEST_SET      = $04;                        { Activar DMA Request }
REQUEST_CLR      = $00;                        { Borrar DMA-Request  }
REQUEST_MSK      = $03;        { Indicar canal en los dos bits bajos }

{= Escribir bits del registro de máscara del canal ( $0A, $D4 ) =====}
CHANNEL_RESERVED = $F8;                 { Bits reservados siempre =0 }
CHANNEL_SET      = $04;              { Enmascarar/bloquear canal DMA }
CHANNEL_CLR      = $00;                          { Liberar canal DMA }
CHANNEL_MSK      = $03;        { Indicar canal en los dos bits bajos }

{= Escribir bits del rregistro de modo ($0B, $D6) ===================}
MODE_DEMAND     = $00;                  { Transferir "a petición" }
MODE_SINGLE     = $40;                   { Transferir valores individuales }
MODE_BLOCK      = $80;                               { Blocktransfer }
MODE_CASCADE    = $C0;                    { Transferir en cascada }
MODE_DECREMENT  = $20;                                 { Decrementar }
MODE_AUTOINIT   = $10;               { Auto inicialización al final }
MODE_VERIFY     = $00;                                   { Verificar }
MODE_INVALID    = $0C;                                    { No válido}
MODE_CHANNELMSK = $03;         { Indicar canal en los dos bits bajos }

 dma_adress    : array[0..7] of Byte=($00,$02,$04,$06,$C0,$C4,$C8,$CC);
 dma_count     : array[0..7] of Byte=($01,$03,$05,$07,$C2,$C6,$CA,$CE);
 dma_page      : array[0..7] of Byte=($87,$83,$81,$82,$88,$8B,$89,$8A);

 {-- Register-Offsets para Master y Slave ----------------------------}
 dma_status    : array[0..1] of Byte=($08,$D0);     { Registro de estado [Leer] }
 dma_command   : array[0..1] of Byte=($08,$D0);{ Registro de comandos [Escribir] }
 dma_request   : array[0..1] of Byte=($09,$D2);       { Disparar DMA-Request }
 dma_chmask    : array[0..1] of Byte=($0A,$D4);   { Enmascarar canales individualmente }
 dma_mode      : array[0..1] of Byte=($0B,$D6);              { Modo de transferencia }
 dma_flipflop  : array[0..1] of Byte=($0C,$D8);    { Flipflop direcc./contador }
 dma_masterclr : array[0..1] of Byte=($0D,$DA);        { Resetear controlador}
 dma_temp      : array[0..1] of Byte=($0D,$DA);        { Registro temporal }
 dma_maskclr   : array[0..1] of Byte=($0E,$DC);      { Liberar todos los canales }
 dma_mask      : array[0..1] of Byte=($0F,$DE);    { Enmascarar todos los canales }
{ * resetear el controlador correspondiente al canal * }

Procedure dma_MasterClear( iChan : Integer );
begin
  iChan := iChan and $0007;
  enviar_byte(0,dma_masterclr[iChan div 4]);
End;



{ * Disparar transferencia en canal indicado * }

Procedure dma_SetRequest( iChan : Integer );
Begin
  iChan :=iChan and $0007;
  enviar_byte( REQUEST_SET or ( iChan and $03) ,dma_request[iChan div 4]);
End;


{ * Detener transferencia en canal indicado * }

Procedure dma_ClrRequest( iChan : Integer );
Begin
  iChan := iChan and $0007;
  enviar_byte(REQUEST_CLR or ( iChan and $03 ),dma_request[iChan div 4]);
End;




{ * Enmascarar canal indicado (bloquearlo) * }

Procedure dma_SetMask( iChan : Integer );

Begin
  iChan :=iChan and $0007;
  enviar_byte(CHANNEL_SET or ( iChan and $03 ),dma_chmask[iChan div 4]);
End;



{ * Liberar canal indicado * }

Procedure dma_ClrMask( iChan : Integer );

Begin
  iChan :=iChan and $0007;
  enviar_byte(CHANNEL_CLR or ( iChan and $03 ),dma_chmask[iChan div 4]);
End;



{ * Leer estado del canal indicado y del controlador correspondiente * }

Function dma_ReadStatus( iChan : Integer ) : Byte;

Begin
  iChan :=iChan and $0007;
  dma_ReadStatus := leer_byte(dma_status[iChan div 4]);
End;



{ * Reponer FlipFlop del controlador correspondiente al canal indicado * }

Procedure dma_ClrFlipFlop( iChan : Integer );

Begin
  iChan :=iChan and $0007;
  enviar_byte(0,dma_flipflop[iChan div 4]);
End;






{ * Leer contador de transferencia del canal indicado  * }

Function dma_ReadCount( iChan : Integer ) : Word;

var l, h : Byte;

Begin
  iChan := iChan and $0007;

  dma_ClrFlipFlop( iChan );
  l := leer_byte(dma_count[iChan]);
  h := leer_byte(dma_count[iChan]);
  dma_ReadCount := h * 256 + l;
End;




{ * Preparar canal DMA para la transferencia * }

function dma_set_channel(ichan:dword;uSize:Word;bMode:byte;buffer:pointer):dword;
var  uAdress : Word;
     bPage   : Byte;
     lpMem:pointer;
begin

 if buffer > pointer (dma_memory)  then
  begin
   printkf('/Vdma/n : Buffer invalido\n',[]);
   exit(-1);
  end;

  lpMem := buffer;
  iChan := iChan and $0007;                      { Máx. 8 canales DMA}

  dma_SetMask( iChan );                             {- Bloq. canal }
                       { DMA transfiere 1 byte más de lo indicado! }
                                    { mín. transferir 1 byte (0==1) }
  if uSize <> 0 then usize := usize - 1;

  {- Crear dirección lineal de 20 bits ------------------------------}
  if iChan <= 3 then                                      { 8Bit DMA }
    Begin                 { Adresse = 16 bits bajos de la direcc. de 20 bits.}
      uAdress := Word ( ( Longint ( lpMem ) and $FFFF0000 ) shr 12 )
                 + ( Longint ( lpMem ) and $FFFF );
                            { Seite = 4 bits superiores de la direcc. de 20 bits }
      bPage := Byte ( ( ( ( ( Longint ( lpMem ) ) and $FFFF0000 ) shr 12 )
               + ( Longint ( lpMem ) and $FFFF ) ) shr 16 );
    End
  else                                                  { 16-Bit DMA }
    Begin                 { Adresse = 16 bits bajos de la direcc. de 20 bits.}
      uAdress := Word ( ( Longint ( lpMem ) and $FFFF0000 ) shr 13 )
                 + ( ( Longint ( lpMem ) and $FFFF ) shr 1 );
                            { Seite = 4 bits superiores de la direcc. de 20 bits }
      bPage := Byte ( ( ( ( Longint ( lpMem ) and $FFFF0000 ) shr 12 )
             + ( Longint ( lpMem ) and $FFFF ) ) shr 16 );
      bPage := bpage and $FE;
      uSize := usize div 2; { Se cuentan Words, y no bytes! }
    End;

  enviar_byte( $40 or bMode or ( iChan and MODE_CHANNELMSK ),dma_mode[iChan div 4]);

  dma_ClrFlipFlop( iChan );   { Borrar flipflop de direcc./contador y...}
                { pasar dirección al controlador DMA (LO/HI-Byte) }
  enviar_byte(LO( uAdress ),dma_adress[iChan]);
  enviar_byte(HI( uAdress ),dma_adress[iChan]);
  enviar_byte(bPage,dma_page[iChan]);            { Fijar página de memoria}

  dma_ClrFlipFlop( iChan );  { Borrar flipflop de direcc./contador y...}
                 { pasar contador al controlador DMA (LO/HI-Byte) }
  enviar_byte(LO( uSize ),dma_count[iChan]);
  enviar_byte(HI( uSize ),dma_count[iChan]);

  dma_ClrMask( iChan );                 { Liberar canal DMA }
  exit (0);

end;


{ * este proceso inicializa el modulo dma * }

procedure dma_init;
var ret : dword ;
begin
dma_flags := 0 ;

{ se limpia las colas de espera }
for ret := 0 to 7 do
  begin
   dma_wait[ret].lock := false ;
   dma_wait[ret].lock_wait := nil;
  end;

printkf('/nIniciando dma ... /VOk \n',[]);
end;

end.
