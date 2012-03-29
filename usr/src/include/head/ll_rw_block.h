function buffer_read ( Bh : P_buffer_head):dword;external name 'BUFFER_READ';
function buffer_write(bh:p_buffer_head):dword;external name 'BUFFER_WRITE';
function Read_Sync_Block (mayor,menor,bloque,size : dword ; buffer : pointer):dword;external name 'READ_SYNC_BLOCK';
function Write_Sync_Block (mayor,menor,bloque,size : dword ; buffer : pointer):dword;external name 'WRITE_SYNC_BLOCK';

