function sys_getpid:dword;cdecl;external name 'SYS_GETPID';
function sys_getppid:dword;cdecl;external name 'SYS_GETPPID';
function sys_detener(Pid:dword):dword;cdecl;external name 'SYS_DETENER';
function sys_fork:dword;cdecl;external name 'SYS_FORK';
function sys_waitpid(var status:dword):dword;cdecl;external name 'SYS_WAITPID';
procedure sys_exit(status:word);cdecl;external name 'SYS_EXIT';
function sys_kill(Pid:dword;Signal:word):dword;cdecl;external name 'SYS_KILL';
function sys_signal(Handler:pointer;Signal:word):dword;cdecl;external name 'SYS_SIGNAL';
function sys_readerrno : dword ; cdecl ; external name 'SYS_READERRNO';

