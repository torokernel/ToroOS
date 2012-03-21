procedure sonar_parlante(Freq:word);external;
procedure parar_parlante;external;
function ktime:dword;external;
function sys_time(t:pointer):dword;cdecl;external;
function sys_stime( time : dword ) : dword ; cdecl ; external;

