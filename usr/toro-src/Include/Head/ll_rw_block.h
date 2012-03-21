function buffer_read ( Bh : P_buffer_head):dword;external;
function buffer_write(bh:p_buffer_head):dword;external;
function Read_Sync_Block (mayor,menor,bloque,size : dword ; buffer : pointer):dword;external;
function Write_Sync_Block (mayor,menor,bloque,size : dword ; buffer : pointer):dword;external;

