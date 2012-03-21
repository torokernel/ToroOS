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
MODE_WRITE      = $04;                         { Escribir en memoria }
MODE_READ       = $08;                             { Leer de memoria }
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
