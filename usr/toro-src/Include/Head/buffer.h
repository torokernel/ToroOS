procedure Buffer_Init;external;
procedure Sys_Sync;external;
function get_block(Mayor,Menor,Bloque,size:dword):p_buffer_head;external;
procedure Mark_Buffer_Dirty (Bh : p_buffer_head );external;
function Put_Block(buffer:p_buffer_head):dword;external;
procedure Invalid_Sb (sb : p_super_block_t) ;external;

{$define Buffer_Lock := Lock }
{$define Buffer_Unlock := Unlock }

var Max_Buffers : dword ; external name 'U_BUFFER_MAX_BUFFERS';
