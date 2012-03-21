
{$I ../Toro/utime.inc}

function sys_mkdir (path:pchar;Mode:dword) : dword ; cdecl ; external;
function sys_create (path:pchar;Mode:dword):dword;cdecl;external;
function sys_mknod(path:pchar;flags,mayor,menor:dword):dword;cdecl;external;
procedure sys_close(File_desc:dword);cdecl;external;
function sys_open(path:pchar;mode,flags:dword):dword;cdecl;external;
function sys_chmod(path:pchar;flags:dword):dword;cdecl;external;
function sys_stat(path:pchar;buffer:pointer):dword;cdecl;external;
function sys_rename(path,name:pchar):dword;cdecl;external;
procedure clone_filedesc(pFile_p,pFile_c:p_file_t);external;
function sys_utime(Path : pchar ; times : p_utimbuf ) : dword ;external;
function sys_chdir (path : pchar) : dword ; cdecl ; external;
function sys_rmdir (path : pchar ) : dword ; cdecl ; external ;
