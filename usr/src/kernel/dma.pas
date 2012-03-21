Unit Dma;

{ * Dma :                                                       *
  *                                                             *
  * Unidad q se encarga del manejo de del controlador de dma ,  *
  * por ahora se realiza una utilizacion simple , y solo        *
  * trabaja sobre el buffer de dma , en el futuro utilizara     *
  * paginas dma solicitadas al modulo de memoria                *
  *                                                             *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>  *
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

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/asm.h}
{$I ../Include/Toro/drivers/dma.inc}
{$I ../Include/Head/paging.h}
{$I ../Include/Head/printk_.h}


var dma_flags : word ;
    dma_wait : array[0..7] of wait_queue;

Implementation


{$I ../Include/Head/lock.h}
{$I ../Include/Head/ioport.h}



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

Function dma_ReadCount( iChan : Integer ) : Word; [PUBLIC , ALIAS :'DMA_READCOUNT'];

var l, h : Byte;

Begin
  iChan := iChan and $0007;

  dma_ClrFlipFlop( iChan );
  l := leer_byte(dma_count[iChan]);
  h := leer_byte(dma_count[iChan]);
  dma_ReadCount := h * 256 + l;
End;




{ * Preparar canal DMA para la transferencia * }

function dma_set_channel(ichan:dword;uSize:Word;bMode:byte;buffer:pointer):dword;[public , alias :'DMA_SET_CHANNEL'];
var  uAdress : Word;
     bPage   : Byte;
     lpMem:pointer;
begin

 if buffer > pointer (dma_memory)  then
  begin
   printk('/Vdma/n : Buffer invalido\n',[],[]);
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

  enviar_byte( bMode or ( iChan and MODE_CHANNELMSK ),dma_mode[iChan div 4]);

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

procedure dma_init;[public , alias : 'DMA_INIT'];
var ret : dword ;
begin
dma_flags := 0 ;

{ se limpia las colas de espera }
for ret := 0 to 7 do
  begin
   dma_wait[ret].lock := false ;
   dma_wait[ret].lock_wait := nil;
  end;

printk('/nIniciando dma ... /VOk \n',[],[]);
end;

end.
