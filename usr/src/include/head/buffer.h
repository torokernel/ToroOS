procedure Buffer_Init;external name 'BUFFER_INIT';
procedure Sys_Sync;external name 'SYS_SYNC';
function get_block(Mayor,Menor,Bloque,size:dword):p_buffer_head;external name 'GET_BLOCK';
procedure Mark_Buffer_Dirty (Bh : p_buffer_head );external name 'MARK_BUFFER_DIRTY';
function Put_Block(buffer:p_buffer_head):dword;external name 'PUT_BLOCK';
procedure Invalid_Sb (sb : p_super_block_t) ;external name 'INVALID_SB';

{$define Buffer_Lock := Lock }
{$define Buffer_Unlock := Unlock }

var Max_Buffers : dword ; external name 'U_BUFFER_MAX_BUFFERS';
