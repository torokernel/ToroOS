//
// dma.pas
//
// This unit contains the functions to manipulate the dma.
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
Unit Dma;

Interface

uses arch, printk, process, memory;

const
MODE_WRITE      = $04;                     
MODE_READ       = $08;                        

var dma_flags : word ;
    dma_wait : array[0..7] of wait_queue;

procedure dma_init;
function dma_set_channel(ichan:dword;uSize:Word;bMode:byte;buffer:pointer):dword;

Implementation

{$I ../arch/macros.inc}
Const

STATUS_REQ3 = $80;          
STATUS_REQ2 = $40;               
STATUS_REQ1 = $20;              
STATUS_REQ0 = $10;
STATUS_TC3  = $08;            
STATUS_TC2  = $04;            
STATUS_TC1  = $02;             
STATUS_TC0  = $01;          

COMMAND_DACKLEVEL = $80; 
                        
COMMAND_DREQLEVEL = $40; 
                         
COMMAND_EXTWRITE = $20; 
                        
COMMAND_FIXEDPRI = $10; 
COMMAND_COMPRESS = $08; 
COMMAND_INACTIVE = $04; 
COMMAND_ADH0     = $02; 
                        
COMMAND_MEM2MEM  = $01; 

REQUEST_RESERVED = $F8;                
REQUEST_SET      = $04;                    
REQUEST_CLR      = $00;                       
REQUEST_MSK      = $03;      

CHANNEL_RESERVED = $F8;               
CHANNEL_SET      = $04;              
CHANNEL_CLR      = $00;               
CHANNEL_MSK      = $03;        

MODE_DEMAND     = $00;                 
MODE_SINGLE     = $40;                 
MODE_BLOCK      = $80;                              
MODE_CASCADE    = $C0;                  
MODE_DECREMENT  = $20;                                 
MODE_AUTOINIT   = $10;             
MODE_VERIFY     = $00;                                  
MODE_INVALID    = $0C;                                    
MODE_CHANNELMSK = $03;         

 dma_adress    : array[0..7] of Byte=($00,$02,$04,$06,$C0,$C4,$C8,$CC);
 dma_count     : array[0..7] of Byte=($01,$03,$05,$07,$C2,$C6,$CA,$CE);
 dma_page      : array[0..7] of Byte=($87,$83,$81,$82,$88,$8B,$89,$8A);

 dma_status    : array[0..1] of Byte=($08,$D0);
 dma_command   : array[0..1] of Byte=($08,$D0);
 dma_request   : array[0..1] of Byte=($09,$D2);   
 dma_chmask    : array[0..1] of Byte=($0A,$D4);   
 dma_mode      : array[0..1] of Byte=($0B,$D6);    
 dma_flipflop  : array[0..1] of Byte=($0C,$D8);    
 dma_masterclr : array[0..1] of Byte=($0D,$DA);       
 dma_temp      : array[0..1] of Byte=($0D,$DA);       
 dma_maskclr   : array[0..1] of Byte=($0E,$DC);     
 dma_mask      : array[0..1] of Byte=($0F,$DE);

Procedure dma_MasterClear( iChan : Integer );
begin
  iChan := iChan and $0007;
  enviar_byte(0,dma_masterclr[iChan div 4]);
End;


Procedure dma_SetRequest( iChan : Integer );
Begin
  iChan :=iChan and $0007;
  enviar_byte( REQUEST_SET or ( iChan and $03) ,dma_request[iChan div 4]);
End;


Procedure dma_ClrRequest( iChan : Integer );
Begin
  iChan := iChan and $0007;
  enviar_byte(REQUEST_CLR or ( iChan and $03 ),dma_request[iChan div 4]);
End;

Procedure dma_SetMask( iChan : Integer );

Begin
  iChan :=iChan and $0007;
  enviar_byte(CHANNEL_SET or ( iChan and $03 ),dma_chmask[iChan div 4]);
End;


Procedure dma_ClrMask( iChan : Integer );
Begin
  iChan :=iChan and $0007;
  enviar_byte(CHANNEL_CLR or ( iChan and $03 ),dma_chmask[iChan div 4]);
End;

Function dma_ReadStatus( iChan : Integer ) : Byte;

Begin
  iChan :=iChan and $0007;
  dma_ReadStatus := leer_byte(dma_status[iChan div 4]);
End;

Procedure dma_ClrFlipFlop( iChan : Integer );

Begin
  iChan :=iChan and $0007;
  enviar_byte(0,dma_flipflop[iChan div 4]);
End;


Function dma_ReadCount( iChan : Integer ) : Word;

var l, h : Byte;

Begin
  iChan := iChan and $0007;

  dma_ClrFlipFlop( iChan );
  l := leer_byte(dma_count[iChan]);
  h := leer_byte(dma_count[iChan]);
  dma_ReadCount := h * 256 + l;
End;



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
  iChan := iChan and $0007;                

  dma_SetMask( iChan );                            
  if uSize <> 0 then usize := usize - 1;

  if iChan <= 3 then                                     
    Begin            
      uAdress := Word ( ( Longint ( lpMem ) and $FFFF0000 ) shr 12 )
                 + ( Longint ( lpMem ) and $FFFF );
      bPage := Byte ( ( ( ( ( Longint ( lpMem ) ) and $FFFF0000 ) shr 12 )
               + ( Longint ( lpMem ) and $FFFF ) ) shr 16 );
    End
  else                                                 
    Begin               
      uAdress := Word ( ( Longint ( lpMem ) and $FFFF0000 ) shr 13 )
                 + ( ( Longint ( lpMem ) and $FFFF ) shr 1 );
                           
      bPage := Byte ( ( ( ( Longint ( lpMem ) and $FFFF0000 ) shr 12 )
             + ( Longint ( lpMem ) and $FFFF ) ) shr 16 );
      bPage := bpage and $FE;
      uSize := usize div 2;
    End;

  enviar_byte( $40 or bMode or ( iChan and MODE_CHANNELMSK ),dma_mode[iChan div 4]);

  dma_ClrFlipFlop( iChan );
  enviar_byte(LO( uAdress ),dma_adress[iChan]);
  enviar_byte(HI( uAdress ),dma_adress[iChan]);
  enviar_byte(bPage,dma_page[iChan]);       

  dma_ClrFlipFlop( iChan );
  enviar_byte(LO( uSize ),dma_count[iChan]);
  enviar_byte(HI( uSize ),dma_count[iChan]);

  dma_ClrMask( iChan );               
  exit (0);

end;


procedure dma_init;
var ret : dword ;
begin
dma_flags := 0 ;

for ret := 0 to 7 do
  begin
   dma_wait[ret].lock := false ;
   dma_wait[ret].lock_wait := nil;
  end;

printkf('/nInitializing dma ... /VOk \n',[]);
end;

end.
