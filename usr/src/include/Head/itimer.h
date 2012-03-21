function  sys_sleep(miliseg:dword):dword;cdecl;external;
procedure timer_inc;external;
procedure sys_setitimer(miliseg:dword);cdecl;external;
function sys_getitimer:dword;cdecl;external;

var contador : dword ; external name 'U_ITIMER_CONTADOR';
