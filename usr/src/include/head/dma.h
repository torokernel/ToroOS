function dma_set_channel (iChan:dword;uSize:Word;bMode:Byte;buffer:pointer):dword;external name 'DMA_SET_CHANNEL';
procedure dma_init;external name 'DMA_INIT';

{$define dma_lock := lock }
{$define dma_unlock := unlock }


var dma_wait : array [0..7] of wait_queue;external name 'U_DMA_DMA_WAIT';
