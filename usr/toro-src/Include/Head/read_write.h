function sys_seek(File_desc:dword;offset,whence:dword):dword;cdecl;external;
function sys_read(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;external;
function sys_write(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;EXTERNAL;

