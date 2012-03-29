
{$I ../Toro/utime.inc}

function sys_mkdir (path:pchar;Mode:dword) : dword ; cdecl ; external name 'SYS_MKDIR';
function sys_create (path:pchar;Mode:dword):dword;cdecl;external name 'SYS_CREATE';
function sys_mknod(path:pchar;flags,mayor,menor:dword):dword;cdecl;external name 'SYS_MKNOD';
procedure sys_close(File_desc:dword);cdecl;external name 'SYS_CLOSE';
function sys_open(path:pchar;mode,flags:dword):dword;cdecl;external name 'SYS_OPEN';
function sys_chmod(path:pchar;flags:dword):dword;cdecl;external name 'SYS_CHMOD';
function sys_stat(path:pchar;buffer:pointer):dword;cdecl;external name 'SYS_STAT';
function sys_rename(path,name:pchar):dword;cdecl;external name 'SYS_RENAME';
procedure clone_filedesc(pFile_p,pFile_c:p_file_t);external name 'CLONE_FILEDESC';
function sys_utime(Path : pchar ; times : p_utimbuf ) : dword ;external name 'SYS_UTIME';
function sys_chdir (path : pchar) : dword ; cdecl ; external name 'SYS_CHDIR';
function sys_rmdir (path : pchar ) : dword ; cdecl ; external name 'SYS_RMDIR';
