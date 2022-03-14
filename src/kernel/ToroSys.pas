Unit ToroSys;

interface



procedure mountroot;assembler;
procedure sync;assembler;
function mkdir(path:pchar;mode:dword):dword;cdecl;assembler;
function mknod(path:pchar;flags,mayor,menor:dword):dword;cdecl;assembler;
function creat(path:pchar;mode:dword):dword;cdecl;assembler;
function open(path:pchar;mode,flags:dword):dword;cdecl;assembler;
function seek(File_desc,offs,whence:dword):dword;cdecl;assembler;
function read(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;assembler;
function write(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;assembler;
procedure close(File_desc:dword);cdecl;assembler;
function chmod(path:pchar;flags:dword):dword;cdecl;assembler;
function stat(path:pchar;buffer:pointer):dword;cdecl;assembler;
function rename(path,name:pchar):dword;cdecl;assembler;
function mount(path,path_mount,name:pchar):dword;cdecl;assembler;
function unmount(path:pchar):dword;cdecl;assembler;
function sleep(miliseg:dword):dword;cdecl;assembler;
procedure setitimer(miliseg:dword);cdecl;assembler;
function getitimer :dword ;cdecl;assembler;
function getpid:dword;cdecl;assembler;
function getppid:dword;cdecl;assembler;
function detener(Pid:dword):dword;cdecl;assembler;
function fork:dword;cdecl;assembler;
function WaitPid(var status:dword):dword;cdecl;assembler;
procedure Exit_(status:word);cdecl;assembler;
function exec_(path,args:pchar):dword;cdecl;assembler;
function brk(Size:dword):pointer;cdecl;assembler;
function kill(Pid:dword;Signal:word):dword;assembler;
function signal(Handler:pointer;Sig:word):dword;cdecl;assembler;
function Time(t:pointer):dword;cdecl;assembler;
function Utime(path : pchar ; times : pointer) : dword ; cdecl ; assembler;
function Stime(time:dword):dword;cdecl;assembler;
function Ioctl(Fichero,req:dword;argp:pointer):dword;cdecl;assembler;
function Chdir (path : pchar ) : dword ; cdecl ;assembler;
function ReadErrno : dword ; cdecl ; assembler ;
function setscheduler ( pid , politica , prioridad : dword ): dword ; cdecl ; assembler;
function getscheduler (pid : dword ) : dword ; cdecl ; assembler ;
procedure Reboot ; assembler ;
function rmdir (path : pchar) : dword ; cdecl ; assembler ;

implementation

procedure mountroot;assembler;[nostackframe];
asm
xor eax , eax
int 50
end;


procedure sync;assembler;inline;
asm
mov eax , 36
Int 50
end;

function mkdir(path:pchar;mode:dword):dword;cdecl;assembler;inline;
asm
mov eax , 3
mov ebx , path
mov ecx , mode
int 50
end;

function mknod(path:pchar;flags,mayor,menor:dword):dword;cdecl;assembler;inline;
asm
mov eax , 4
mov ebx , path
mov ecx , flags
mov edx , Mayor
mov esi , Menor
int 50
end;

function creat(path:pchar;mode:dword):dword;cdecl;assembler;inline;
asm
mov eax , 5
mov ebx , path
mov ecx , mode
int 50
end;

function open(path:pchar;mode,flags:dword):dword;cdecl;assembler;inline;
asm
mov eax , 6
mov ebx , path
mov ecx , mode
mov edx , flags
int 50
end;


function seek(File_desc,offs,whence:dword):dword;cdecl;assembler;inline;
asm
mov eax , 30
mov ebx , File_desc
mov ecx , offs
mov edx , whence
int 50
end;



function read(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;assembler;inline;
asm
mov eax , 8
mov ebx , File_desc
mov ecx , buffer
mov edx , nbytes
int 50
end;


function write(File_Desc:dword;buffer:pointer;nbytes:dword):dword;cdecl;assembler;inline;
asm
mov eax , 9
mov ebx , file_desc
mov ecx , buffer
mov edx , nbytes
int 50
end;

procedure close(File_desc:dword);cdecl;assembler;inline;
asm
mov eax , 10
mov ebx , File_desc
int 50
end;


function chmod(path:pchar;flags:dword):dword;cdecl;assembler;inline;
asm
mov eax , 12
mov ebx , path
mov ecx , flags
int 50
end;


function stat(path:pchar;buffer:pointer):dword;cdecl;assembler;inline;
asm
mov eax , 22
mov ebx , path
mov ecx , buffer
int 50
end;

function rename(path,name:pchar):dword;cdecl;assembler;inline;
asm
mov eax , 14
mov ebx , path
mov ecx , name
int 50
end;

function mount(path,path_mount,name:pchar):dword;cdecl;assembler;inline;
asm
mov eax , 15
mov ebx , path
mov ecx , path_mount
mov edx , name
int 50
end;

function unmount(path:pchar):dword;cdecl;assembler;inline;
asm
mov eax , 16
mov ebx , path
int 50
end;

function sleep(miliseg:dword):dword;cdecl;assembler;inline;
asm
mov eax , 17
mov ebx , miliseg
int 50
end;

procedure setitimer(miliseg:dword);cdecl;assembler;inline;
asm
mov eax , 18
mov ebx , miliseg
int 50
end;


function getitimer :dword ;cdecl;assembler;inline;
asm
mov eax , 26
int 50
end;


function getpid:dword;cdecl;assembler;inline;
asm
mov eax , 19
int 50
end;


function getppid:dword;cdecl;assembler;inline;
asm
mov eax , 20
int 50
end;

function detener(Pid:dword):dword;cdecl;assembler;inline;
asm
mov eax , 21
mov ebx , pid
int 50
end;

function fork:dword;cdecl;assembler;inline;
asm
mov eax , 2
int 50
end;



function WaitPid(var status:dword):dword;cdecl;assembler;inline;
asm
mov eax , 7
mov ebx , status
int 50
mov status , ebx
end;


procedure Exit_(status:word);cdecl;assembler;inline;
asm
mov eax , 1
mov bx , status
int 50
mov status , bx
end;



function exec_(path,args:pchar):dword;cdecl;assembler;inline;
asm
mov eax , 25
mov ebx , path
mov ecx , args
int 50
end;


function brk(Size:dword):pointer;cdecl;assembler;inline;
asm
mov eax , 45
mov ebx , size
int 50
end;


function kill(Pid:dword;Signal:word):dword;assembler;inline;
asm
mov eax , 37
mov ebx , Pid
mov cx , signal
int 50
end;


function signal(Handler:pointer;Sig:word):dword;cdecl;assembler;inline;
asm
mov eax , 48
mov ebx , Handler
mov cx , sig
int 50
end;


function Time(t:pointer):dword;cdecl;assembler;inline;
asm
mov eax , 13
mov ebx , t
int 50
end;

function Utime(path : pchar ; times : pointer) : dword ; cdecl ; assembler;inline;
asm
mov eax , 23
mov ebx , path
mov ecx , times
int 50
end;


function Stime(time:dword):dword;cdecl;assembler;inline;
asm
mov eax , 24
mov ebx , time
int 50
end;


function Ioctl(Fichero,req:dword;argp:pointer):dword;cdecl;assembler;inline;
asm
mov eax , 33
mov ebx , Fichero
mov ecx , req
mov edx , argp
int 50
end;


function Chdir (path : pchar ) : dword ; cdecl ;assembler ; inline ;
asm
mov eax , 27
mov ebx , path
int 50
end;

function ReadErrno : dword ; cdecl ; assembler ; inline;
asm
mov eax , 28
int 50
end;


function setscheduler ( pid , politica , prioridad : dword ): dword ; cdecl ; assembler ; inline;
asm
mov eax , 29
mov ebx , pid
mov ecx , politica
mov edx , prioridad
int 50
end;


function getscheduler (pid : dword ) : dword ; cdecl ; assembler ; inline;
asm
mov eax , 31
mov ebx , pid
int 50
end;


procedure Reboot ; assembler ; inline;
asm
mov eax , 32
int 50
end;


function rmdir (path : pchar) : dword ; cdecl ; assembler ; inline ;
asm
mov eax , 34
mov ebx , path
int 50
end;

end.
