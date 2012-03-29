function sys_seek(File_desc:dword;offset,whence:dword):dword;cdecl;external name 'SYS_SEEK';
function sys_read(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;external name 'SYS_READ';
function sys_write(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl; external name 'SYS_WRITE';

