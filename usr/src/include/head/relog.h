procedure sonar_parlante(Freq:word);external name 'SONAR_PARLANTE';
procedure parar_parlante;external name 'PARA_PARLANTE';
function ktime:dword;external name 'KTIME';
function sys_time(t:pointer):dword;cdecl;external name 'SYS_TIME';
function sys_stime( time : dword ) : dword ; cdecl ; external name 'SYS_STIME';

