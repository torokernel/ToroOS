function sys_getpid:dword;cdecl;external;
function sys_getppid:dword;cdecl;external;
function sys_detener(Pid:dword):dword;cdecl;EXTERNAL;
function sys_fork:dword;cdecl;external;
function sys_waitpid(var status:dword):dword;cdecl;EXTERNAL;
procedure sys_exit(status:word);cdecl;external;
function sys_kill(Pid:dword;Signal:word):dword;cdecl;external;
function sys_signal(Handler:pointer;Signal:word):dword;cdecl;external;
function sys_readerrno : dword ; cdecl ; external;

