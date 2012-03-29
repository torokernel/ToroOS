function  sys_sleep(miliseg:dword):dword;cdecl;external name 'SYS_SLEEP';
procedure timer_inc;external name 'TIMER_INC';
procedure sys_setitimer(miliseg:dword);cdecl;external name 'SYS_SETITIMER'; 
function sys_getitimer:dword;cdecl;external name 'SYS_GETITIMER';

var contador : dword ; external name 'U_ITIMER_CONTADOR';
