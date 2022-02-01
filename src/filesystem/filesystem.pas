Unit filesystem;




interface

uses arch, printk, memory;

const

{Maxima cantidad de archivos abiertos}
Nr_Open = 32;


{Valores Whence}
seek_set = 0;
seek_cur = 1;
seek_eof = 2;


{sb flags bits }
Sb_Rdonly = 1;
Sb_Rw = 2 ;


{inode state bits }
I_Dirty = 1 ;

{inode flags bits }
I_RO = 4 ;
I_WO = 2 ;
I_XO = 1 ;


{inode mode }
dt_chr = 2;
dt_dir = 4;
dt_blk = 6;
dt_reg = 8;

{open flags}
O_CREAT = 1;
O_TRUNC = 2;


{open mode}
O_WRONLY = 2;
O_RDONLY = 4;
O_RDWR = 6 ;


{Numero Maximo de dispositivos soportados}
Nr_Blk = 30 ;
Nr_Chr = 50 ;
Max_Spblk = 5 ;
Max_Path = 4096 ;

{ dispositivo de caracteres para acceso a las variables del kernel }
kdev_mayor = 49 ;


Nr_Menor : array[0..5] of char =('0','1','2','3','4','5');

Type

p_file_ops  = ^file_operations ;
p_file_system_type = ^file_system_type ;
p_super_block_t = ^super_block_t ;
p_super_operations = ^super_operations;
p_inode_operations = ^inode_operations ;
p_inode_t = ^inode_t ;
p_dentry = ^dentry ;
p_file_t = ^file_t;



{ **************** Metodos principales del vfs ************************** }

file_operations = record
 open :function (Inodo : p_inode_t ; Fichero : p_file_t): dword;
 read :function (Fichero : p_file_t ; count : dword ; buff : pointer): dword;
 readdir : function (fichero : p_file_t ; buff : pointer) : dword ;
 write :function (Fichero : p_file_t ; count : dword ; buff : pointer): dword;
 seek :function (Fichero : p_file_t ; whence , offset : dword): dword;
 ioctl :function (Fichero : p_file_t ; req : dword ; argp : pointer): dword;
end;


super_operations = record
 read_inode : procedure(ino : P_inode_t);
 write_inode : procedure (ino : p_inode_t);
 put_inode : procedure (ino : p_inode_t);
 delete_inode : procedure (ino : p_inode_t);
 put_super : procedure (sb : p_super_block_t) ;
 write_super : procedure (sb : p_super_block_t) ;
 clear_inode : procedure (ino : p_inode_t);
 umount_begin : procedure (sb : p_super_block_t);
end;


inode_operations = record
default_file_ops : p_file_ops ;
create : function (ino : p_inode_t ; dentry : p_dentry ; tm : dword ) : dword ;
lookup : function (ino : p_inode_t ; dentry : p_dentry ) : p_dentry ;
mkdir : function (ino : p_inode_t ; dentry : p_dentry ; mode : dword ) : dword ;
rmdir : function (ino : p_inode_t ; dentry : p_dentry) : dword ;
mknod : function (ino : p_inode_t ; dentry : p_dentry ; int , mayor , menor : dword ) : dword ;
rename : function (dentry , ndentry : p_dentry ) : dword ;
truncate : procedure (ino : p_inode_t) ;
end;



{ ****************** estructuras principales del vfs ********************* }


{ estructura de un sistema de archivo }

file_system_type = record

 {numero identificador del fs}
 fs_id      : dword ;
 {por ahora no es utilizado este campo }
 fs_flag    : dword;
 read_super : function (sb : P_super_block_t) : P_super_block_t;
 next_fs    : p_file_system_type;
 prev_fs    : p_file_system_type ;
end;


{ Estructura de un Dispositivo }

device = record
name : string[20] ;
fops : p_file_ops;
end;


{  estructura de un sp en el vfs}

super_block_t = record
mayor : dword;
menor : dword;
ino_root : dword;
pino_root : p_inode_t;
dirty     : boolean;
flags     : byte;
blocksize : dword;
fs_type   : P_file_system_type;
op        : P_super_operations;
driver_space : pointer ;
wait_on_sb : wait_queue;
next_spblk : p_super_block_t;
prev_spblk : p_super_block_t;
ino_hash : p_inode_t;
end;


{ estructura de un inodo }

inode_t = record
ino      : dword;
mayor    : byte;
menor    : byte;
rmayor   : byte;
rmenor   : byte;
count    : byte;
state    : byte;
mode     : dword;
atime    : dword;
ctime    : dword;
mtime    : dword;
dtime    : dword;
nlink    : word;
flags     : dword;
size     : dword;
blksize  : dword;
blocks   : dword;
wait_on_inode : wait_queue;
sb       : P_super_block_t;
op       : P_inode_operations;
i_dentry : p_dentry ;
ino_next : p_inode_t ;
ino_prev : p_inode_t ;
ino_dirty_next : p_inode_t;
end;

p_inode_tmp = ^inode_tmp;

inode_tmp = packed record
ino      : dword;
mayor    : byte;
menor    : byte;
rmayor   : byte;
rmenor   : byte;
count    : byte;
state    : byte;
mode     : dword;
atime    : dword;
ctime    : dword;
mtime    : dword;
dtime    : dword;
nlink    : word;
flags     : dword;
size     : dword;
blksize  : dword;
blocks   : dword;
end;



file_t = record
f_op : p_file_ops ;
f_flags : dword ;
f_mode : dword;
f_pos : dword ;
Inodo:p_inode_t;
end;


{estructura devuelta por readdir }
preaddir_entry = ^readdir_entry ;

readdir_entry = record
name : string ;
ino : dword ;
end;

{entrada dentro del cache de nombre }
dentry = record
ino : p_inode_t ;
state : dword ;
len : dword;
flags : dword ;
count : dword;
l_count : dword;
name : string ;
parent : p_dentry ;
down_tree : p_dentry ;
down_mount_tree : p_dentry;
next_dentry : p_dentry ;
prev_dentry : p_dentry ;
end;

t_fsid = record
  id : dword ;
  name : string[20];
end;

const
st_vacio = 2;
st_incache = 3;

fsid : array [1..2] of t_fsid = ((id : 1 ; name : 'torofs'),
                                (id : 2 ; name : 'fatfs'));

{ Maximo tama¤ode bloque manejable }
Max_blk_size = 4096 ;

{Porcentage de utilizacion del buffer-cache de la memoria}
Buffer_Use_Mem  = 1 ;

{ valores del mapa de bits de state }
Bh_Dirty = 2 ;

type
p_buffer_Head = ^buffer_head;

buffer_head=record
bloque : dword ;
size : dword ;
Mayor : dword ;
Menor : dword ;
count:dword;
state : dword ;
data:pointer;
wait_on_buffer:wait_queue;
next_buffer:p_buffer_head;
prev_buffer:p_buffer_head;
next_bh_dirty : p_buffer_head;
end;


var Blk_Dev:array[1..Nr_Blk] of device ;
    Chr_Dev:array[Nr_Blk..Nr_Chr] of device ;
    Fs_type : p_file_system_type;

procedure Devices_Init ;
procedure clone_filedesc (pfile_p , pfile_c : p_file_t ) ;
procedure sys_close (File_desc:dword) ; cdecl ;
procedure Put_dentry (dt : p_dentry ) ;
procedure sys_mountroot ; cdecl ;
procedure Register_Blkdev (nb : byte ; name : pchar ; fops : p_file_ops);
procedure Register_Chrdev(nb : byte ; name : pchar ; fops : p_file_ops);
procedure buffer_init;
function get_block(Mayor,Menor,Bloque,size:dword):p_buffer_head;
function Put_Block(buffer:p_buffer_head):dword;
function Get_Inode(sb : p_super_block_t ; ino : dword ):p_inode_t;
function Register_Filesystem (fs : p_file_system_type) : dword ;
function SysExec(path, args : pchar): dword; cdecl;
function sys_open (path : pchar ; mode , flags : dword) : dword ; cdecl;
function sys_read( File_Desc : dword ; buffer : pointer ; nbytes : dword ) : dword;cdecl;
function sys_write ( file_desc : dword ; buffer : pointer ; nbytes : dword) : dword;cdecl;
function sys_seek ( File_desc : dword ; offset , whence : dword ) : dword ; cdecl;
function sys_ioctl (Fichero , req : dword ; argp : pointer) : dword ;cdecl;
function sys_chdir(path : pchar) : dword ; cdecl ;
function sys_stat ( path : pchar ; buffer : pointer ) : dword ; cdecl;

implementation

uses process;

{$DEFINE set_errno := Tarea_Actual^.errno  }
{$DEFINE clear_errno := Tarea_Actual^.errno := 0 }
{$define inode_lock := lock }
{$define inode_unlock := unlock }


function name_i (path : pchar ) : p_inode_t ; forward;
function last_dir (path : pchar ) : p_inode_t ; forward;

{Tabla con los inodos en memoria}
const Inodes_Lru : p_inode_t = nil ;
      Inodes_Free : p_inode_t = nil ;
      Inodes_Dirty : p_inode_t = nil;

var Max_Inodes : dword ;
    Buffer_Dirty : p_buffer_head;
    dentry_root : p_dentry ;
    Max_dentrys : dword ;


const  Super_Tail:p_super_block_t = nil;
       Nr_Spblk : dword = 0 ;

{$I ../arch/macros.inc}

function chararraycmp (ar1 , ar2 : pchar ; len :dword ): boolean ; forward;
function Alloc_Entry ( ino_p : p_inode_t ; const name : string ) : p_dentry ; forward;
function Alloc_dentry (const name : string ) : p_dentry ; forward;
procedure Sys_Sync ;forward;

{ * pcharlen : funcion simple que devuelve la longitud de un pchar * }

function pcharlen ( pc : pchar ) : dword ; inline;
var cont : dword ;
begin

cont := 0 ;

while (pc^ <> #0) do
 begin
  cont += 1 ;
  pc += 1;
end;

exit(cont);
end;

procedure pcharcopy (path  : pchar ; var name : string ) ;inline;
var len : dword ;
begin

len := pcharlen(path);

if len > 255 then len := 255 ;

memcopy(path, @name[1], len);

name[0] := chr(len) ;
end;


{ * Register_Chrdev :                                                   *
  *                                                                     *
  * nb : Numero mayor                                                   *
  * name : Nombre del Dispositivo                                       *
  * fops : Puntero a un array de manejadores del dispositivo            *
  *                                                                     *
  * Procedimiento que registra un dispositivo de caracteres             *
  *                                                                     *
  ***********************************************************************
}
procedure Register_Chrdev(nb : byte ; name : pchar ; fops : p_file_ops);
begin

If fops = nil then exit;
If (nb > Nr_Chr) or (nb < Nr_Blk) then exit;
If Chr_Dev[nb].fops <> nil then exit;

cerrar;

Chr_Dev[nb].fops := fops ;
chr_dev[nb].name[0] := char(pcharlen(name));

if byte(chr_dev[nb].name[0]) > 20 then exit ;

pcharcopy (name , Chr_Dev[nb].name);
chr_dev[nb].name[0] := char(pcharlen(name)) ;

abrir;

end;



{ * Register_Blkdev :                                                   *
  *                                                                     *
  * nb : Numero mayor                                                   *
  * name : Nombre del Dispositivo                                       *
  * fops : Puntero al array de manejadores                              *
  *                                                                     *
  * Procedimiento que registra un dispositivo de bloque                 *
  *                                                                     *
  ***********************************************************************
}
procedure Register_Blkdev (nb : byte ; name : pchar ; fops : p_file_ops);
begin

If fops = nil then exit ;
if nb > Nr_Blk then exit ;
If Blk_Dev[nb].fops <> nil then exit ;


cerrar;
Blk_Dev[nb].fops := fops ;
blk_dev[nb].name[0] := char(pcharlen(name)) ;

if byte(blk_dev[nb].name[0]) > 20 then exit ;

pcharcopy (name , Blk_Dev[nb].name);
blk_dev[nb].name[0] := char(pcharlen(name)) ;

abrir;

end;

procedure Devices_Init ;
var cont : dword ;
begin
cont := 0 ;
for cont := 1 to Nr_Blk do Blk_Dev[cont].fops := nil ;
for cont := Nr_Blk to Nr_Chr do Chr_Dev[cont].fops := nil ;

fs_type := nil ;

end;


{ * funcion que quita de la cola simple un inodo sucio * }

procedure remove_ino_dirty ( ino : p_inode_t);inline;
var tmp : p_inode_t ;
begin

if inodes_dirty = ino then
 inodes_dirty^.ino_dirty_next := ino^.ino_dirty_next
  else
   begin

   {se busca por toda la cola }
   while (tmp^.ino_dirty_next <> ino)   do tmp := tmp^.ino_dirty_next ;

   tmp^.ino_dirty_next := ino^.ino_dirty_next ;
   end;

end;

{ * Inode_Update :                                                      *
  *                                                                     *
  * Ino : Puntero a un inodo                                            *
  * Retorno : 0 si ok o -1 si falla                                     *
  *                                                                     *
  * Funcion que actualiza la version en el dev dado                     *
  *                                                                     *
  ***********************************************************************
}
function Inode_Update (Ino : p_inode_t ) : dword ;inline;
begin
if (ino^.state and I_Dirty ) <> I_Dirty then exit(0)
 else
  begin
   ino^.sb^.op^.write_inode (ino) ;

    if (ino^.state and I_Dirty ) <> I_Dirty then exit(0)
     else exit(-1);
  end;
end;




{ * Inode_Uptodate :                                                    *
  *                                                                     *
  * Ino : Puntero a un inodo                                            *
  *                                                                     *
  * Funcion que trae un inodo al cache                                  *
  *                                                                     *
  ***********************************************************************
}
function Inode_Uptodate (Ino : p_inode_t ) : dword ;inline;
begin
ino^.sb^.op^.read_inode (ino) ;

if (ino^.state and I_Dirty) = I_dirty  then exit(-1) else exit(0);
end;

procedure Pop_Inode(Nodo : p_inode_t;var Nodo_tail : p_inode_t);
begin

If (nodo_tail= nodo) and (nodo_tail^.ino_next = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.ino_prev := nil;
 nodo^.ino_next := nil;
 exit;
end;

if (Nodo_tail = nodo) then Nodo_tail := Nodo^.ino_next ;

nodo^.ino_prev^.ino_next := nodo^.ino_next ;
nodo^.ino_next^.ino_prev := nodo^.ino_prev ;
nodo^.ino_next := nil ;
nodo^.ino_prev := nil;
end;

procedure Push_Inode(Nodo: p_inode_t; var nodo_tail: p_inode_t);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.ino_next := Nodo ;
 nodo^.ino_prev := Nodo ;
 exit;
end;

nodo^.ino_prev := nodo_tail^.ino_prev ;
nodo^.ino_next := nodo_tail ;
nodo_tail^.ino_prev^.ino_next := Nodo ;
nodo_tail^.ino_prev := Nodo ;
end;


{ * devuelve un inodo libre de la cola de inodos invalidados * }

function alloc_from_free : p_inode_t ; inline ;
var tmp : p_inode_t ;
begin

if Inodes_Free = nil then exit(nil)
 else
  begin
   tmp := Inodes_Free^.ino_prev;
   Pop_Inode (Inodes_Free,tmp);
   exit(tmp);
  end;
end;

procedure Free_Dentry ( dt : p_dentry ) ;forward;


{ * devuelve un inodo libre de la cola de inodos no utilizados * }

function alloc_from_lru : p_inode_t ; inline ;
var tmp : p_inode_t ;
begin

if Inodes_Lru = nil then exit(nil);

tmp := Inodes_Lru^.ino_prev;

{por si esta sucio , esto es un grave error}
if Inode_Update (tmp) <> 0 then
    printkf('/VVFS/n : Error de escritura del Inodo : %d dev : %d \n',[tmp^.ino,tmp^.mayor,tmp^.menor]);

{fue quitado de la cola de sucios}
remove_ino_dirty (tmp);

{si actualmente no posee enlaces en el arbol puede liberarse sino
permanecera como vacio}
if tmp^.i_dentry^.l_count = 0 then Free_dentry (tmp^.i_dentry)
 else tmp^.state := st_vacio;

{se informa al driver que el inodo fue totalmente quitado del sistema}
tmp^.sb^.op^.delete_inode (tmp);

Pop_Inode (Inodes_Lru,tmp);
end;





{ * Alloc_Inode :                                                        *
  *                                                                      *
  * Funcion que devuelve un inodo libre y llena los campos mayor , menor *
  * y ino                                                                *
  *                                                                      *
  ************************************************************************
}

function Alloc_Inode (mayor , menor , inode : dword ) : p_inode_t ;
var tmp : p_inode_t ;
label _exit;
begin


if Max_Inodes = 0 then
  begin

    {se trata de alocar de los inodos invalidos}
    tmp := alloc_from_free ;

    if tmp <> nil then goto _exit ;

    {se alocara tomando de la cola lru}
    tmp := alloc_from_lru ;

    if tmp = nil then exit (nil) else goto _exit ;
  end;

{hay memoria como para seguir alocando}

tmp := alloc_from_free;

if (tmp <> nil) then goto _exit
 else
   begin
    tmp := kmalloc (sizeof(inode_t));
    if tmp = nil then exit(nil);
   end;

Max_Inodes -= 1;

_exit :

tmp^.mayor := mayor ;
tmp^.menor := menor ;
tmp^.ino := inode ;
tmp^.wait_on_inode.lock := false ;
tmp^.state := 0 ;
tmp^.count := 0 ;

exit(tmp);
end;




{ *  se encarga de buscar un ino en la cola en uso de un sb * }

function Find_in_Hash (sb : p_super_block_t ; ino : dword ) : p_inode_t ;inline;
var tmp  : p_inode_t ;
begin

if  sb^.ino_hash = nil then exit(nil);

tmp := sb^.ino_hash ;

repeat
if (tmp^.ino = ino) then exit(tmp);
tmp := tmp^.ino_next;
until (tmp = sb^.ino_hash) ;

exit(nil);
end;


{ * busca un inodo en la cola lru * }

function Find_in_Lru (mayor,menor,ino : dword) : p_inode_t ;inline;
var tmp : p_inode_t ;
begin
tmp := inodes_lru ;

if tmp = nil then exit(nil);

repeat

if (tmp^.mayor =mayor ) and ( tmp^.menor = menor) and (tmp^.ino = ino) then exit(tmp);

until (tmp = inodes_lru) ;


exit(nil);
end;




{ * Get_Inode :                                                         *
  *                                                                     *
  * Dev_blk : Dispostivo logico de donde sera leido el inodo            *
  * Inode : Numero de Inodo                                             *
  * Devuelve : Puntero al inodo o nil si falla                          *
  *                                                                     *
  * Carga un Inodo en memoria y devuelve su puntero                     *
  *                                                                     *
  ***********************************************************************
}
function Get_Inode(sb : p_super_block_t ; ino : dword ):p_inode_t;
var tmp : p_inode_t ;
begin

if sb = nil then exit(nil);

{puede estar en uso}
tmp := Find_in_Hash (sb,ino);

if tmp <> nil then
 begin
  tmp^.count += 1;
  exit(tmp);
 end;

tmp := Find_in_Lru (sb^.mayor,sb^.menor,ino);

{estaba en la cola de libres}
if tmp <> nil then
 begin
  Pop_Inode (inodes_lru,tmp);
  Push_Inode (sb^.ino_hash,tmp);
  tmp^.count := 1 ;
  exit(tmp);
 end;

{se crea o reutiliza una estructura}
tmp := Alloc_Inode (sb^.mayor,sb^.menor,ino);

if tmp = nil then exit(nil);


{sp del inodo}
tmp^.sb := sb ;
tmp^.blksize := sb^.blocksize;
tmp^.count := 1 ;

if Inode_Uptodate (tmp) = -1 then
 begin
  printkf('/VVFS/n : Error de lectura de Inodo : %d Dev %d %d \n',[tmp^.ino,tmp^.mayor,tmp^.menor]);
  Push_Inode (Inodes_Free,tmp);
 exit(nil);
 end;

{se coloca en la cola en uso}
Push_Inode (sb^.ino_hash,tmp);

exit(tmp);
end;




{ * Put_Inode :                                                          *
  *                                                                      *
  * Inode : Puntero a un inodo                                           *
  * Devuelve : 0 si fue correcto o -1 sino                               *
  *                                                                      *
  ************************************************************************
}

function Put_Inode ( ino:p_inode_t ):dword;[public , alias :'PUT_INODE'];
begin

if (ino^.count = 0) then Panic ('/nSe devuelve un inodo con count =  0\n');

ino^.count -= 1;

 {el dentry del inodo permanece en la cache de dentrys hasta que el inodo}
 {sea quitado totalmente del sistema}
 if (ino^.count = 0) then
  begin

    Pop_Inode (ino^.sb^.ino_hash,ino);
    Push_Inode (Inodes_lru,ino);

    {se le informa al driver que el inodo paso a la cola de desuso}
    ino^.sb^.op^.put_inode(ino)

 end;

exit(0);
end;


function Nr_Filp (filp : p_file_t) : dword ;inline;
begin
exit((longint(filp) - longint (@Tarea_Actual^.Archivos[0])) div sizeof(file_t)) ;
end;


procedure free_filp (filp : p_file_t) ;inline;
begin
filp^.f_op := nil ;
end;


{ * Clone_Filedesc :                                            *
  *                                                             *
  * pfile_p  : descriptor de origen                             *
  * pfile_c  : descriptor de destino                            *
  *                                                             *
  * procedimiento que duplica un descriptor de archivo          *
  *                                                             *
  ***************************************************************
}
procedure clone_filedesc (pfile_p , pfile_c : p_file_t ) ;
begin
pfile_c^ := pfile_p^;

if (nr_filp(pfile_c) = 2 )  or (nr_filp(pfile_c)= 1) then else
pfile_p^.inodo^.i_dentry^.count += 1;

end;


{ * Sys_Close :                                                           *
  *                                                                       *
  * File_desc : Descriptor del archivo                                    *
  *                                                                       *
  * Este proc. se encarga de cerrar una archivo , liberando de la memoria *
  * su INODE y liberando la entrada en la tabla de archivos               *
  *                                                                       *
  *************************************************************************
  }
procedure sys_close (File_desc:dword) ; cdecl ;
begin

If (file_desc > 32) or (file_desc = 0 ) then exit;

If Tarea_Actual^.Archivos[File_desc].f_op = nil then exit;

Tarea_Actual^.Archivos[file_desc].f_op := nil ;
Put_dentry (Tarea_Actual^.Archivos[file_desc].inodo^.i_dentry);
end;


function Is_Dir (ino : p_inode_t ) : boolean;
begin
if ino^.mode and dt_dir = dt_dir then exit(true) else exit(false);
end;



function Is_Blk (ino : p_inode_t ) : boolean ;
begin
if ino^.mode and dt_blk = dt_blk then exit(true) else exit(false);
end;



function Is_chr (ino : p_inode_t) : boolean;
begin
if ino^.mode and dt_chr = dt_chr then exit(true) else exit(false);
end;

function strlen(p: pchar): DWORD;
var
i: DWORD;
begin
  i := 0;
  while (p[i] <> #0) do
    Inc(i);
  Exit(i);
end;

function validate_path (path : pchar) : boolean ;
begin
if strlen(path) > Max_Path then exit(false) else exit(true);
end;

function get_free_filp : p_file_t ;
var cont : dword ;
    tmp : p_file_t ;
begin

for cont := 1 to 32 do
 if Tarea_Actual^.Archivos[cont].f_op = nil then exit(@Tarea_Actual^.Archivos[cont]);
 exit(nil);
end;

function validate_blkmayor (Mayor : dword ) : boolean ; inline;
begin
if (Mayor > Nr_blk ) or (blk_dev[mayor].fops = nil) then exit(false)
 else exit(true);
end;

function validate_chrmayor (mayor : dword ) : boolean ; inline;
begin
if ((mayor > Nr_Chr) or (mayor < Nr_Blk)) or (chr_dev[mayor].fops = nil) then exit(false)
 else exit(true);
end;

function file_create (ino : p_inode_t ; dt : p_dentry ) : boolean ;inline;
begin

{la llamada create del driver se limita a crear el archivo}
if ino^.op^.create (ino,dt,0) = -1 then  exit(false)
 else exit(true);

end;


function filp_open (filp : p_file_t)  : dword ;inline;
begin
if filp^.f_op =  nil then exit(-1)
 else
  begin
   {la estructura de esta funcion no esta definida}
   if filp^.f_op^.open = nil then exit(0)
    else exit(filp^.f_op^.open (filp^.inodo,filp))
   end;
end;

function pathcopy (path :pchar ; var  name : string ) : boolean ;
var len , tm:dword;
    tmp : pchar ;
begin

len :=  longint(strlen(path));

tmp := path;

while (tmp^ <> '/') and (tmp^ <> #0) do
  Inc(tmp);
//tmp := strrscan (path,'/');

if (tmp <> nil) then
 begin
 tm := longint(tmp) - longint(path)  ;
 len -= tm ;
 end;

//if (tmp = nil)  then   else path := ((strrscan (path,'/') +1) );
if (tmp <> nil) then
begin
  path := tmp + 1;
end;

memcopy (path,@name[1],len);

name[0] := char(len);

exit(true);
end;


{ * Sys_Seek :                                                             *
  *                                                                        *
  * File_Desc : Descriptor del archivo                                     *
  * offset : Posicion donde se quiere posicionar el archivo                *
  * whence : Algoritmo que se utilizara                                    *
  * Devuelve : La nueva posicion del archivo o 0 si falla                  *
  *                                                                        *
  * Se encarga de posicionar un archivo en un byte dado , segun el         *
  * algoritmo en whence  , si la llamada fue correcta devuelve la          *
  * nueva posicion sino devuelve 0                                         *
  *                                                                        *
  **************************************************************************
}
function sys_seek ( File_desc : dword ; offset , whence : dword ) : dword ; cdecl;
var ret : dword ;
    p_file : p_file_t ;
begin

{Se chequea el descriptor}
If File_desc > 32 then exit(0);

{Puntero al descriptor}
p_file := @Tarea_Actual^.Archivos[File_desc];

If p_file^.f_op = nil then exit(0);

if p_file^.f_op^.seek = nil then exit(0);

{no se puede hacer un seek sobre un inodo dir}
if p_file^.inodo^.mode = dt_dir then exit(0);

Inode_lock (@p_file^.inodo^.wait_on_inode);

{se llama al driver para que haga el trabajo}
if p_file^.f_op^.seek (p_file,whence,offset) = -1 then ret := 0 else ret := (p_file^.f_pos);
Inode_unlock (@p_file^.inodo^.wait_on_inode);

exit(ret);
end;



{ * Sys_Open :                                                          *
  *                                                                     *
  * path : Ruta del archivo                                             *
  * Modo : Modo de acceso                                               *
  * flags : Modo de la llamada                                          *
  * Devuelve :El descriptor del archivo                                 *
  *                                                                     *
  * Realiza la apertura de un archivo a traves del VFS no importa       *
  * el tipo de archivo  , devuelve el descriptor de archivo o -1 si     *
  * falla y el error queda en errno                                     *
  *                                                                     *
  ***********************************************************************
}
function sys_open (path : pchar ; mode , flags : dword) : dword ; cdecl;
var tmp : p_inode_t ;
    filp : p_file_t ;
    dt : dentry ;
    p_dt : p_dentry ;

label _exit,_filp;
begin

clear_errno;

if validate_path (path) then else exit(0);

if pathcopy (path,dt.name) then  else exit(0);

dt.len := dword(dt.name[0]);

{se trae el inodo}
tmp := name_i (path);

set_errno := -ENOTDIR;

{ruta invalida!!!!}
if (tmp = nil) then
 begin

  {bandera de crear archivo !!!!}
  if (flags and O_CREAT) = O_CREAT  then
   begin

    {lugar donde creare el archivo}
     tmp := last_dir (path) ;

     if tmp = nil then exit(0) ;

     {se tratara de crear el archivo regular }
     if file_create (tmp,@dt) then
      begin

       {aloja la entrada en el cache}
       p_dt := alloc_entry (tmp,dt.name) ;

       {que kilombo!!! paso algo en el cache!!!!}
       if p_dt = nil then goto _exit;

       {se devuelve el ultimo directorio}
       put_dentry (tmp^.i_dentry);

       tmp := p_dt^.ino ;

       {ya esta metido en el cache toda la direccion!! se creara el descr.}
       goto _filp

        end
       else exit(0);

    end else exit(0);

 end;

{si existe bandera de truncar tu tamao a 0 !!!}
if (flags and O_TRUNC) = O_TRUNC then tmp^.op^.truncate (tmp);

set_errno := -EACCES ;

{no se puede escribir el inodo!!}
if ((tmp^.flags and I_WO ) <> I_WO) and (mode and O_WRONLY = O_WRONLY) then goto _exit;

{no se puede leer!!!}
if ((tmp^.flags and I_RO ) <> I_RO) and (mode and O_RDONLY = O_RDONLY) then goto _exit;


_filp :

{hay lugar en la tabla de archivos??}
filp := get_free_filp;

set_errno := -EMFILE;

if filp = nil then goto _exit;

case tmp^.mode of
dt_chr : if validate_chrmayor(tmp^.rmayor) then filp^.f_op := chr_dev[tmp^.rmayor].fops
         else
           begin
            free_filp (filp);
            goto _Exit;
           end;
dt_blk : if validate_blkmayor (tmp^.rmayor) then filp^.f_op := blk_dev[tmp^.rmayor].fops
          else
           begin
            free_filp (filp);
            goto _exit;
           end;
else  filp^.f_op := tmp^.op^.default_file_ops ;
end;

filp^.f_flags := flags ;
filp^.f_mode := mode ;
filp^.f_pos := 0 ;
filp^.inodo := tmp ;

{se llamara al procedimiento del driver que lo abrira!!}
if filp_open (filp) = -1 then
 begin
  free_filp (filp);
  goto _exit;
  end else
      begin
       clear_errno ;
       exit(nr_filp (filp));
      end;

_exit :
put_dentry (tmp^.i_dentry);
exit(0);

end;


{ * Sys_Read:                                                           *
  *                                                                     *
  * File_Desc : Descriptor del archivo                                  *
  * buffer : Puntero donde sera almacemado el contenido                 *
  * nbytes : Numero de bytes leidos                                     *
  * Devuelve : El numero de bytes leidos                                *
  *                                                                     *
  * Se encarga de la lectura de un fichero cualquiera sea este          *
  *                                                                     *
  ***********************************************************************
  }
function sys_read( File_Desc : dword ; buffer : pointer ; nbytes : dword ) : dword;cdecl;
var pfile:p_file_t;
    ret : dword ;
label _exit ;
begin


{Aqui es protegida el area del kernel}
If Buffer < pointer(High_Memory) then
 begin
  set_errno := -EFAULT ;
  goto _exit ;
 end;

set_errno := -EBADF ;

If File_desc > 31 then goto _exit ;

{Se puntea al descriptor del archivo}
pfile:=@Tarea_Actual^.Archivos[File_Desc];

{estan definidos los handlers??}
if (pfile^.f_op = nil) then goto _exit ;

{no se abrio para lectura!!}
if (pfile^.f_mode and O_RDONLY = O_RDONLY) then
 else
  begin
   set_errno := -EACCES ;
   goto _exit ;
  end;

set_errno := -ENODEV;

if (pfile^.inodo^.mode = dt_dir ) and (pfile^.f_op^.readdir = nil) then exit(0)
 else if pfile^.f_op^.read = nil then exit(0);

clear_errno;

{esto me asegura la consistencia del archivo}
Inode_lock (@pfile^.inodo^.wait_on_inode);

case pfile^.inodo^.mode of
dt_reg : ret := pfile^.f_op^.read (pfile,nbytes,buffer);
dt_dir : ret := pfile^.f_op^.readdir (pfile,buffer);
//dt_blk : ret := Blk_Read (pfile, nbytes ,buffer );
dt_chr : ret := pfile^.f_op^.read(pfile,nbytes,buffer);
end;

Inode_unlock (@pfile^.inodo^.wait_on_inode);

exit(ret);

_exit :

exit(0);
end;



{ * Sys_Write :                                                         *
  *                                                                    *
  * File_desc : Descriptor del archivo                                 *
  * Buffer : Lugar de donde se extraeran los datos                     *
  * nbytes : Numero de bytes                                           *
  * Devuelve : Numero de bytes escritos                                *
  *                                                                    *
  * Se encarga de escribir cualquier tipo de fichero                   *
  *                                                                    *
  **********************************************************************
}
function sys_write ( file_desc : dword ; buffer : pointer ; nbytes : dword) : dword;cdecl;
var pfile : p_file_t;
    ret : dword ;
begin

{El buffer devera estar en el area del usuario}
If buffer < pointer(High_Memory) then
 begin
  set_errno := -EFAULT ;
  exit(0);
 end;

set_errno := -EBADF;

If File_Desc > 31 then exit(0);

{Se puntea al descriptor del archivo}
pfile:=@Tarea_Actual^.Archivos[File_Desc];

{estan definidos los handlers??}
if (pfile^.f_op = nil) then exit(0);

{no se abrio para escritura!!}
if (pfile^.f_mode and O_WRONLY = O_WRONLY) then
 else
  begin
   set_errno := -EACCES ;
   exit(0);
  end;

set_errno := -ENODEV;

if (pfile^.inodo^.mode = dt_dir ) then exit(0)
 else if pfile^.f_op^.write = nil then exit(0);

clear_errno;

{esta proteccion me asegura que dos procesos no escriban a la ves un mismo}
{archivo}
Inode_lock (@pfile^.inodo^.wait_on_inode);

{segun el tipo de archivo!!!}
case pfile^.inodo^.mode of
dt_reg : ret := (pfile^.f_op^.write (pfile,nbytes,buffer));
//dt_blk : ret := (Blk_write (pfile, nbytes ,buffer ));
dt_chr : ret := (pfile^.f_op^.write(pfile,nbytes,buffer));
end;

Inode_unlock (@pfile^.inodo^.wait_on_inode);

exit(ret);
end;


const Free_dentrys : p_dentry = nil ;

procedure Pop_Dentry(Nodo : p_dentry;var Nodo_tail : p_dentry);
begin

If (nodo_tail= nodo) and (nodo_tail^.next_dentry = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_dentry := nil;
 nodo^.next_dentry := nil;
 exit;
end;

if (Nodo_tail = nodo) then Nodo_tail := Nodo^.next_dentry ;

nodo^.prev_dentry^.next_dentry := nodo^.next_dentry ;
nodo^.next_dentry^.prev_dentry := nodo^.prev_dentry ;
nodo^.next_dentry := nil ;
nodo^.prev_dentry := nil;
end;

procedure Push_Dentry(Nodo: p_dentry; var nodo_tail: p_dentry);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_dentry := Nodo ;
 nodo^.prev_dentry := Nodo ;
 exit;
end;

nodo^.prev_dentry := nodo_tail^.prev_dentry ;
nodo^.next_dentry := nodo_tail ;
nodo_tail^.prev_dentry^.next_dentry := Nodo ;
nodo_tail^.prev_dentry := Nodo ;
end;


{ * Put_dentry :                                                         *
  *                                                                      *
  * dt : puntero al dentry                                               *
  *                                                                      *
  * Decrementa el uso de una dentry si no posee mas usuarios se devuelve *
  * el inodo al cache . Cuando un  inodo quitado totalmente del sistema  *
  * si no posee enlaces se libera la estructura , si posee se vuelve un  *
  * dentry vacio puesto que podra ser utilizada en una futura busqueda   *
  * Las que poseen enlaces son enlazadas ya que es muy posible que se    *
  * vuelven totalmente obsoletas , proc. sync rastrea esta cola en busca *
  * de dentrys obsoletas y las coloca en la cola de libres               *
  * (no implementado)                                                    *
  *                                                                      *
  ************************************************************************
}
procedure Put_dentry (dt : p_dentry ) ;
begin
dt^.count -= 1;
if dt^.count = 0 then put_inode (dt^.ino);
end;


{ * quita un dentry de su padre * }

procedure Remove_queue_dentry (dt :p_dentry );inline;
begin
Pop_dentry (dt,dt^.parent^.down_tree);
dt^.parent^.l_count -= 1;
end;


{ * Llamada que quita un dentry y la coloca como libre * }

procedure Free_Dentry ( dt : p_dentry ) ;
begin
Remove_queue_dentry (dt);
Push_Dentry (Free_dentrys,dt);
end;

function chararraycmp (ar1 , ar2 : pchar ; len :dword ): boolean ;
var ret :dword ;
begin
for ret := 1 to len do
 begin
  if (ar1^ <> ar2^) then exit(false);
  ar1 += 1;
  ar2 += 1;
 end;

exit(true);
end;


// here are the low level buffer API

{$define Buffer_Lock := lock }
{$define Buffer_Unlock := unlock }

const block_size = 512 ;

{ * Buffer_Write :                                                         *
  *                                                                        *
  * Buffer : Puntero a un buffer_head                                      *
  * Retorno : 0 si ok o -1 si falla                                        *
  *                                                                        *
  * Funcion q escribe sobre el disco un buffer dado                        *
  *                                                                        *
  **************************************************************************
}

function buffer_write(bh:p_buffer_head):dword;
var fd : file_t ;
    i : inode_t ;
    res: dword ;
begin

buffer_lock (@bh^.wait_on_buffer);

{ Es creado el inodo temporal }
fd.inodo := @i ;
fd.f_pos := bh^.bloque * ( bh^.size div block_size) ;

i.rmayor := bh^.menor ;
i.rmenor := bh^.menor ;


res := Blk_Dev[bh^.mayor].fops^.write (@fd ,(bh^.size div block_size) , bh^.data);

If res <> (bh^.size div block_size) then Buffer_Write := -1 else Buffer_Write := 0 ;


buffer_unlock (@bh^.wait_on_buffer);

end;

function buffer_read ( Bh : P_buffer_head):dword;
var fd : file_t ;
    i : inode_t ;
    res : dword ;
begin

buffer_lock (@bh^.wait_on_buffer);

{Es creado el inodo temporal}
fd.inodo := @i ;
fd.f_pos := bh^.bloque * ( bh^.size div block_size) ;

i.rmayor := bh^.mayor ;
i.rmenor := bh^.menor ;

res := Blk_Dev[bh^.mayor].fops^.read (@fd , (bh^.size div block_size) , bh^.data);

If res <> (bh^.size div block_size) then buffer_Read := -1  else Buffer_Read := 0;


buffer_unlock (@bh^.wait_on_buffer);

end;




// Buffer cache

var Buffer_Hash:array[1..Nr_blk] of p_buffer_head;
    Buffer_Lru : p_buffer_head ;
    Max_Buffers:dword;


procedure Init_Bh (bh : p_buffer_head ; mayor , menor , bloque : dword) ;inline;
begin
bh^.mayor := mayor ;
bh^.menor := menor ;
bh^.bloque := bloque ;
bh^.count := 1;
bh^.state := 0 ;
bh^.wait_on_buffer.lock := false;
bh^.wait_on_buffer.lock_wait := nil ;
bh^.prev_buffer := nil ;
bh^.next_buffer := nil ;
end;


{ * Lru_Find :                                                          *
  *                                                                     *
  * Dev_blk : Dispositivo de Bloque                                     *
  * Bloque : Numero de Bloque                                           *
  * Retorno : Puntero buffer_head o nil se falla                        *
  *                                                                     *
  * Esta funcion busca dentro de la cola Lru un bloque dado y si lo     *
  * encuentra devuelve un puntero a la estructura buffer_head o de lo   *
  * contrario nil                                                       *
  *                                                                     *
  ***********************************************************************
}
function lru_find(Mayor,Menor,Bloque,Size:dword):p_buffer_head;
var tmp:p_buffer_head;
begin

If Buffer_Lru = nil then exit (nil) ;

tmp:=Buffer_Lru;

repeat
if (tmp^.Mayor=Mayor)  and (tmp^.menor = Menor) and (tmp^.bloque=bloque) and (tmp^.size = size) then exit(tmp);

tmp := tmp^.next_buffer;
until ( tmp = Buffer_Lru);

exit(nil);
end;


procedure free_buffer (bh : p_buffer_head );inline;
begin
kfree_s (bh^.data,bh^.size);
kfree_s (bh,sizeof(buffer_head));
end;



function buffer_update (Buffer:p_buffer_head):dword;
begin
if ( buffer^.state and Bh_Dirty = Bh_Dirty) then
  begin

  if buffer_write (buffer) <> -1 then
   begin
   buffer^.state := buffer^.state xor Bh_dirty;
    exit(0)
    end
     else exit(-1);
    end
 else exit(0);
end;

procedure Pop_Buffer(Nodo : p_buffer_head;var Nodo_tail : p_buffer_head);
begin

If (nodo_tail= nodo) and (nodo_tail^.next_buffer = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_buffer := nil;
 nodo^.next_buffer := nil;
 exit;
end;

if (Nodo_tail = nodo) then Nodo_tail := Nodo^.next_buffer ;

nodo^.prev_buffer^.next_buffer := nodo^.next_buffer ;
nodo^.next_buffer^.prev_buffer := nodo^.prev_buffer ;
nodo^.next_buffer := nil ;
nodo^.prev_buffer := nil;
end;

procedure Push_Buffer(Nodo: p_buffer_head; var nodo_tail: p_buffer_head);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_buffer := Nodo ;
 nodo^.prev_buffer := Nodo ;
 exit;
end;

nodo^.prev_buffer := nodo_tail^.prev_buffer ;
nodo^.next_buffer := nodo_tail ;
nodo_tail^.prev_buffer^.next_buffer := Nodo ;
nodo_tail^.prev_buffer := Nodo ;
end;


{ * Push_Hash :                                                         *
  *                                                                     *
  * Procedimiento que coloca un buffer_head en la cola hash             *
  *                                                                     *
  ***********************************************************************
}
procedure push_hash(buffer:p_buffer_head);
begin
Push_Buffer (buffer , Buffer_Hash[buffer^.mayor]);
end;

{ * Pop_Hash :                                                          *
  *                                                                     *
  * Procedimiento que quita un buffer_head de la cola hash              *
  *                                                                     *
  ***********************************************************************
}

procedure pop_hash(Buffer:p_buffer_head);
begin
Pop_Buffer (buffer , Buffer_Hash[buffer^.mayor]);
end;

function hash_find(Mayor,Menor,Bloque,size:dword):p_buffer_head;
var tmp:p_buffer_head;
begin

tmp:=Buffer_Hash[Mayor];
if tmp=nil then exit(nil);

repeat
If (tmp^.menor = Menor) and (tmp^.bloque = Bloque) and (tmp^.size = size) then exit(tmp);
tmp:=tmp^.next_buffer;
until (tmp=Buffer_Hash[Mayor]);


exit(nil);
end;


{ * Alloc_Buffer :                                                      *
  *                                                                     *
  * size : Tama¤o del nuevo bloque a crear                              *
  *                                                                     *
  * crea un buffer utilizando la variable Max_Buffers como indicador    *
  *                                                                     *
  ***********************************************************************
}
function alloc_buffer (size : dword ) : p_buffer_head ;
var tmp :p_buffer_head ;
    tm : pointer ;
begin

{situacion critica}
if Max_Buffers = 0 then
 begin

 if buffer_lru = nil then  exit(nil);

 tmp := Buffer_Lru^.prev_buffer;

 {limpiar la cola de sucios}
 if (tmp^.state and BH_dirty ) = Bh_Dirty then sys_sync;

 {si el tama¤o del buffer no es igual habra que liberar y solicitar}
 if tmp^.size <> size then
  begin
   tm := kmalloc (size);
   if tm = nil then  exit (nil);
   kfree_s (tmp^.data,tmp^.size);
   tmp^.data := tm ;
   tmp^.size := size;
  end;

 Pop_Buffer(tmp,Buffer_Lru);

 exit(tmp);
 end;

{hay suficiente memoria como para seguir creando estructuras}

tmp := kmalloc (sizeof (buffer_head));

if tmp = nil then exit (nil) ;

tmp^.data := kmalloc (size) ;


if tmp^.data = nil then
 begin
  kfree_s (tmp,sizeof(buffer_head));
  exit(nil);
 end;

tmp^.size := size ;
Max_Buffers -= 1;

exit (tmp);
end;


{ * Get_Block :                                                         *
  *                                                                     *
  * Mayor : Dev Mayor                                                   *
  * Menor : Dev Menor                                                   *
  * Bloque  : Numero de bloque                                          *
  * Retorno : nil si fue incorrecta o puntero a los datos               *
  *                                                                     *
  * Esta funcion es el nucleo del buffer , por ahora solo trabaja con   *
  * bloques de dispostivos de bloque y con un tamano constante          *
  *                                                                     *
  ***********************************************************************
}
function get_block(Mayor,Menor,Bloque,size:dword):p_buffer_head;
var tmp:p_buffer_head;
begin

{Busco en la tabla hash}
tmp := Hash_Find(Mayor,Menor,Bloque,size);

{esta en uso}
If tmp <> nil then
 begin
 tmp^.count += 1;
 exit (tmp);
end;

{Es Buscado en la tabla Lru}
tmp := Lru_Find(Mayor,Menor,Bloque,size);

If tmp <> nil then
 begin

  { En la Lru se guardan los q no estan en uso}
   Pop_Buffer(tmp,Buffer_Lru);

   tmp^.count := 1;

   Push_Hash(tmp);
   exit(tmp);
end;

tmp := alloc_buffer (size);

{situacion poco querida}

if tmp = nil then
 begin
 printkf('/Vvfs/n : No hay mas buffer-heads libres\n',[]);
 exit(nil);
 end;

Init_Bh (tmp,mayor,menor,bloque);

{se trae la data del disco}
 If  Buffer_Read(tmp) = 0 then
  begin
  Push_Hash(tmp);
  Get_Block := tmp;
  end
  else
   begin
     {hubo un error se devuelve el buffer}
     printkf('/Vvfs/n : Error de Lectura : block %d dev %d %d \n',[tmp^.bloque,tmp^.mayor,tmp^.menor]);
     free_buffer (tmp);
     Max_Buffers += 1;
     exit(nil);
   end;

end;


{ * Put_Block :                                                                *
  *                                                                            *
  * Mayor   : Dispositivo de bloque                                            *
  * Menor   : Dispositvo Menor                                                 *
  * Bloque : Numero de bloque                                                  *
  *                                                                            *
  * Devuelve el uso de un bloque , y es llamado cada vez que se termina su uso *
  * y decrementa su uso                                                        *
  * Es importante , ya que luego de un GET_BLOCK deve venir un PUT_BLOCK , que *
  * devuelva a la reserva , y si el bloque es del sistema se actualizara la    *
  * version del disco , ademas se decrementara el uso , para que pueda salir de*
  * la cola hash                                                               *
  *                                                                            *
  ******************************************************************************
  }
function Put_Block(buffer:p_buffer_head):dword;
var tmp : p_buffer_head ;
begin

if buffer=nil then panic('VFS : Se quita un buffer no pedido');

buffer^.count -= 1;

{ya nadie lo esta utilizando}

If buffer^.count = 0 then
 begin
  Pop_Hash (buffer);
  Push_buffer (buffer,Buffer_Lru);
 end;
end;


{ * Buffer_Init :                                                          *
  *                                                                        *
  * Proceso q inicializa la unidad de Buffer Cache  , se inicializa la     *
  * cola Lru y la cola Hash  y se calcula el numero maximo de Bufferes     *
  *                                                                        *
  **************************************************************************
}
procedure buffer_init;
var tmp:dword;
begin
Buffer_Lru := nil;
Buffer_Dirty := nil;
for tmp:= 1 to Nr_blk do Buffer_Hash[tmp]:=nil;

{Este numero es muy grande aunque Buffer_Use_mem solo valga 1%}
Max_Buffers := ((Buffer_Use_Mem * MM_MemFree ) div 100) div sizeof(buffer_head);

{aqui son configuradas las variables }
Max_dentrys := Max_Buffers ;
Max_Inodes := Max_dentrys ;

printkf('/Vvfs/n ... Buffer - Cache /V%d /nBuffers\n',[Max_Buffers]);
printkf('/Vvfs/n ... Inode  - Cache /V%d /nBuffers\n',[Max_Buffers]);

end;



// Inodes

{ * Sync_Inode :                                                        *
  *                                                                     *
  * Marca los bufferes de los inodos como sucios para que luego una     *
  * llamada del sistema sync los envie a disco                          *
  *                                                                     *
  ***********************************************************************
}
procedure Sync_Inodes ;
var tmp : p_inode_t ;
begin

tmp := inodes_dirty ;

while (tmp <> nil) do
 begin
 if Inode_Update (tmp) = -1 then printkf('/VVFS/n : Error de escritura de inodo\n',[]);
 tmp := tmp^.ino_dirty_next ;
end;

inodes_dirty := nil ;
end;


{ * Sys_Sync  :                                                         *
  *                                                                     *
  * Implementacion de la llamada al sistema Sync() que actualiza todos  *
  * bloques no utilizados al disco                                      *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 20 / 06 / 2005 : Rescritura con el nuevo modelo de FS               *
  * 26 / 12 / 2004 : Son escritos tambien los bloques en la cola Hash   *
  *                                                                     *
  ***********************************************************************
}
procedure Sys_Sync ;
var tmp:p_buffer_head;
begin

sync_inodes ;

{es simple se rastrea toda la cola de sucios}
tmp := Buffer_Dirty ;

while (tmp <> nil) do
 begin
 if Buffer_Update (tmp) = -1 then printkf('/Vvfs/n : Error de escritura : block %d dev %d %d\n',[tmp^.bloque,tmp^.mayor,tmp^.menor]);
 tmp := tmp^.next_bh_dirty ;
end;

Buffer_Dirty := nil ;
end;

// SuperBlock
var i_root : p_inode_t ;

{ * Invalid_Sb                                                          *
  *                                                                     *
  * sb : Puntero a un superbloque                                       *
  *                                                                     *
  * Procedimiento que limpia todos los bloques y dado un sb manda los   *
  * bloques en uso de ese sb a la cola LRU                              *
  *                                                                     *
  ***********************************************************************
}
procedure Invalid_Sb ( sb : p_super_block_t) ;
var mayor,menor : dword ;
    bh , tbh : p_buffer_head ;
begin

mayor := sb^.mayor ;
menor := sb^.menor ;

{primero mando a todos al disco}
sys_sync ;

{ahora que estan todos limpios los quita de las de en uso}

{si no hay salgo!}
if Buffer_Hash[mayor] = nil then exit ;

{todos los bufferes en uso son movidos a la cola lru}
bh := Buffer_Hash [mayor]^.prev_buffer ;

repeat
  pop_hash (bh);
  push_buffer (bh , Buffer_Lru);

  bh := bh^.prev_buffer ;
until (bh <> nil);

end;

procedure Pop_Spblk(Nodo : p_super_block_t;var Nodo_tail : p_super_block_t);
begin

If (nodo_tail= nodo) and (nodo_tail^.next_spblk = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_spblk := nil;
 nodo^.next_spblk := nil;
 exit;
end;

if (Nodo_tail = nodo) then Nodo_tail := Nodo^.next_spblk ;

nodo^.prev_spblk^.next_spblk := nodo^.next_spblk ;
nodo^.next_spblk^.prev_spblk := nodo^.prev_spblk ;
nodo^.next_spblk := nil ;
nodo^.prev_spblk := nil;
end;

procedure Push_Spblk(Nodo: p_super_block_t; var nodo_tail: p_super_block_t);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_spblk := Nodo ;
 nodo^.prev_spblk := Nodo ;
 exit;
end;

nodo^.prev_spblk := nodo_tail^.prev_spblk ;
nodo^.next_spblk := nodo_tail ;
nodo_tail^.prev_spblk^.next_spblk := Nodo ;
nodo_tail^.prev_spblk := Nodo ;
end;

procedure Remove_Spb (sp : p_super_block_t ) ;
begin
Pop_spblk (sp, Super_Tail);
kfree_s(sp , sizeof (super_block_t));
end;


procedure Init_Super (Super : p_super_block_t);
begin
super^.mayor := 0 ;
super^.menor := 0 ;
super^.dirty := false ;
super^.flags := 0 ;
super^.blocksize := 0 ;
super^.driver_space := nil ;
super^.wait_on_sb.lock := false ;
super^.ino_hash := nil ;
end;

{ * Read_Super :                                                        *
  *                                                                     *
  * Mayor  , Menor : Dev                                                *
  * Flags : tipo de sb                                                  *
  * fs : Puntero al driver de fs                                        *
  *                                                                     *
  * Funcion que lee un superbloque y lo agrega a la cola de sp montados *
  *                                                                     *
  ***********************************************************************
  }
function read_super ( Mayor , Menor , flags : dword ; fs : p_file_system_type ) : p_super_block_t ;
var tmp : p_super_block_t;
    p : p_inode_t ;
begin

if Nr_Spblk = Max_Spblk then exit (nil);

tmp := kmalloc (sizeof(super_block_t));

if tmp = nil then exit (nil);

Init_Super (tmp);

tmp^.mayor := mayor ;
tmp^.menor := menor ;
tmp^.flags := flags ;
tmp^.fs_type := fs ;

if  fs^.read_super (tmp) = nil then
 begin
  Invalid_sb (tmp);
  kfree_s (tmp,sizeof(super_block_t));
  exit(nil);
 end;


{es metido en la cola de spb}
push_spblk (tmp, Super_Tail);

{este debera permanecer el memoria}
p := get_inode (tmp,tmp^.ino_root);

{no se pudo traer !!!}
if (p = nil) then
 begin
  Invalid_sb (tmp);
  Remove_spb (tmp);
  exit(nil);
 end;

{el driver nunca trabaja con el dcache , por eso el campo i_dentry debe }
{estar a nil!!!}
tmp^.pino_root := p;

{se puede crear un dentry para el cache??}
tmp^.pino_root^.i_dentry := alloc_dentry (' ');

{error al crear el la entrada}
if tmp^.pino_root^.i_dentry = nil then
 begin
  put_inode (tmp^.pino_root);
  Invalid_sb (tmp);
  remove_spb (tmp);
  exit(nil);
 end;

tmp^.pino_root^.i_dentry^.ino := tmp^.pino_root;

{siempre estara en memoria , prevego a que un put_dentry me saque el ino}
{root}
tmp^.pino_root^.i_dentry^.count := 1;

Nr_Spblk += 1;

exit(tmp);

end;

// Dentry cache

{$define inode_lock := lock }
{$define inode_unlock := unlock }


{ * encola un dentry en su padre * }

procedure Enqueue_dentry (dt : p_dentry );
begin
Push_dentry (dt,dt^.parent^.down_tree);
dt^.parent^.l_count += 1;
end;


{ * busca un nombre dentro de un dentry  y devuelve un puntero dentry * }

function Find_in_Dentry (const name : string ; dt : p_dentry ) : p_dentry ;
var tmp : p_dentry ;
begin

tmp := dt^.down_tree;

if tmp = nil then exit(nil);

repeat
if dword(name[0]) <> dword(tmp^.name[0]) then exit(nil);
if chararraycmp(@name[1], @tmp^.name[1],dword(tmp^.name[0])) Then exit(tmp);
tmp := tmp^.next_dentry;
until (tmp = dt^.down_tree) ;

exit(nil);
end;


procedure Init_dentry (dt : p_dentry);
begin
with dt^ do
 begin
 ino := nil ;
 flags := 0 ;
 count := 0 ;
 name[0] := char(0) ;
 down_tree := nil ;
 next_dentry := nil ;
 prev_dentry := nil ;
 down_mount_Tree := nil;
 down_tree := nil;
 parent := nil ;
 l_count := 0 ;
end;
end;

{ * Alloc_dentry  :                                                     *
  *                                                                     *
  * name : Nombre de la entrada                                         *
  *                                                                     *
  * Esta funcion devuelve un estructura dentry libre , primero tratara  *
  * de crear y si no hay memoria suficiente tomara una estrutura de la  *
  * cola de libres ,  y si en este caso no puede devuelve nil           *
  *                                                                     *
  ***********************************************************************
}
function Alloc_dentry (const name : string ) : p_dentry ;
var tmp : p_dentry ;

label _exit,_lru ;
begin

if Max_dentrys = 0 then
 begin

  _lru :

  if Free_dentrys = nil then exit(nil);

  {se toma el menos utilizado}
  tmp := free_dentrys^.prev_dentry ;

  goto _exit ;
 end;

 tmp := kmalloc (sizeof(dentry));

 if tmp = nil then goto _lru ;

 Max_dentrys -= 1;

 _exit :

 init_dentry (tmp);

 memcopy (@name[0],@tmp^.name[0],dword(name[0])+1);
 tmp^.len := byte(tmp^.name[0]);
 tmp^.name[0] := char(tmp^.len);
// printkf('%d %d\n', [DWORD(tmp^.name[0]), DWORD(tmp^.name[3])]);
 exit (tmp);
 end;


{ * Alloc_Entry :                                                       *
  *                                                                     *
  * ino_p : puntero al inodo directorio padre                           *
  * name : nombre de la entrada                                         *
  *                                                                     *
  * Esta funcion es bastante compleja , lo que hace primeramente es     *
  * buscar name en el arbol del padre , si la encuentra aumenta el      *
  * contador del dentry y devuelve la dentry  . Si fuese una entrada    *
  * vacia hace un lookup sobre el ino_p para traer el inodo a memoria   *
  *  . Llena la dentry con el inodo y el driver devera puntear el       *
  * campo i_dentry del inodo al dentry que se le pasa como parametro    *
  * Si no estubiese trata de crear la estruc. busca un dentry libre     *
  * y hace un lookup con name , es encolada y devera ser devuelta con   *
  * Put_dentry                                                          *
  *                                                                     *
  ***********************************************************************
}


const
	DIR :  pchar = '.';
	DIR_PREV  : pchar = '..';

function Alloc_Entry ( ino_p : p_inode_t ; const name : string ) : p_dentry ;
var tmp :p_dentry ;
label _1 ;
begin

Inode_Lock (@ino_p^.wait_on_inode);

{entradas estandart}
if (name[0]= #1) and (name[1]='.') then //chararraycmp(@name[1],@DIR[1],1) then
 begin
 tmp := ino_p^.i_dentry ;
 goto _1;
 end
  else if (name[0] = #2) and (name[1] = '.') and (name[2] = '.') then//if chararraycmp(@name[1],@DIR_PREV[1],2) then
   begin
    tmp := ino_p^.i_dentry^.parent ;
    goto _1 ;
    end;

tmp := find_in_dentry (name,ino_p^.i_dentry);

if tmp <> nil then
 begin

_1:

  {esta encache}
  if (tmp^.state = st_incache) then
   begin
    tmp^.count += 1;

    {esta en cache pero el inodo esta en lru}
    if tmp^.ino^.count = 0 then
     begin
     get_inode (tmp^.ino^.sb,tmp^.ino^.ino);
     tmp^.ino^.count := 1 ;
     end;

    {$IFDEF debug}
     printk('/Vdcache/n : entrada en cache %p\n',[name],[]);
    {$ENDIF}

    Inode_Unlock (@ino_p^.wait_on_inode);
    exit (tmp);
   end;

  {entrada zombie}
  if (tmp^.state = st_vacio) then
   begin

    {una parte del arbol esta invalidado por que fue eliminada una entrada fisica}
    if ino_p^.op^.lookup (ino_p , tmp) = nil then Panic ('VFS : Arbol invalido!!!!');

    {se trae el inodo al cache de inodos}
    {lookup deve llenar el campo ino del cache y poner al campo count en 1}
    tmp^.state := st_incache;
    tmp^.flags := tmp^.ino^.flags;
    tmp^.l_count := 0 ;
    tmp^.count := 1;
    Inode_Unlock (@ino_p^.wait_on_inode);
    exit(tmp );
   end;

end;

tmp := alloc_dentry (name) ;

{no se puede seguir la ruta!!!}
if tmp = nil then
 begin
  Inode_Unlock (@ino_p^.wait_on_inode);
  exit(nil);
 end;

{no existe la dentry!!!??}
if ino_p^.op^.lookup (ino_p,tmp) = nil then
 begin
  Push_dentry (free_dentrys,tmp);
  Inode_Unlock (@ino_p^.wait_on_inode);
  exit(nil);
 end;

tmp^.state := st_incache;
tmp^.parent := ino_p^.i_dentry ;
tmp^.flags := tmp^.ino^.flags ;
tmp^.count := 1 ;
tmp^.ino^.i_dentry := tmp;

{se pone en la cola del padre}
Enqueue_Dentry (tmp);

 {$IFDEF DEBUG}
  printk('/Vdcache/n : nueva entrada %p\n',[name],[]);
 {$ENDIF}

Inode_Unlock (@ino_p^.wait_on_inode);

exit(tmp);
end;

procedure Push_Fs(Nodo: p_file_system_type ; var nodo_tail: p_file_system_type);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_fs := Nodo ;
 nodo^.prev_fs := Nodo ;
 exit;
end;

nodo^.prev_fs := nodo_tail^.prev_fs ;
nodo^.next_fs := nodo_tail ;
nodo_tail^.prev_fs^.next_fs := Nodo ;
nodo_tail^.prev_fs := Nodo ;
end;


{ * Register_Filesystem :                                               *
  *                                                                     *
  * fs : Puntero a un driver de Sistema de archivo                      *
  *                                                                     *
  * Procedimiento que registra un driver de Fs                          *
  *                                                                     *
  ***********************************************************************
}
function Register_Filesystem (fs : p_file_system_type) : dword ;
var tmp : p_file_system_type ;
begin

tmp := Fs_Type ;

{fue agregado el driver??}
while (tmp <> nil) do
 begin
  if tmp^.fs_id = fs^.fs_id then exit (-1);
  tmp := tmp^.next_fs ;
 end;

if fs^.read_super = nil then exit(-1);

cerrar;
Push_Fs (fs, Fs_type);
abrir;

exit(0);
end;



{ * Get_Fstype :                                                        *
  *                                                                     *
  * name : Nombre del sistema de archivo                                *
  * retorno : a la estructura del driver                                *
  *                                                                     *
  * funcionque que devuelve un puntero al driver dado en name dentro de *
  * los drivers instalados                                              *
  *                                                                     *
  ***********************************************************************
}
function get_fstype ( const name : string ) : p_file_system_type ;
var tmp  , id : dword ;
    fs : p_file_system_type ;

begin

id := 0 ;

for tmp := 1 to High (fsid) do
 begin
	if chararraycmp(@fsid[tmp].name[1],@name[1],dword(name[0])) then
        begin
       	 id := fsid[tmp].id ;
         break;
	end;
 end;

if id = 0 then exit(nil);

if fs_type = nil then exit(nil);

{se buscara el id en la cola de driver instalados}
fs := fs_type ;

repeat
if fs^.fs_id = id then exit(fs) ;

fs := fs^.next_fs ;
until ( fs = fs_type) ;


exit(nil);
end;

{ * Sys_Mountroot :                                                     *
  *                                                                     *
  * Se encarga de montar la unidad que sera utilizada como root es      *
  * llamada por el proceso init                                         *
  *                                                                     *
  ***********************************************************************
}
procedure sys_mountroot ; cdecl ;
var fs_type : p_file_system_type ;
    spbmount : p_super_block_t ;

label _exit;
begin

{este campo sera modificado de acuerdo al fs del root}
fs_type := get_fstype ('fatfs');

if fs_type = nil then goto _exit ;

{aca es donde se especifica el dispositivo de montage}
spbmount := read_super (2 , 0 , sb_rdonly or sb_rw , fs_type);

if spbmount = nil then goto _exit ;

i_root := spbmount^.pino_root ;
dentry_root := i_root^.i_dentry ;

{importante!!}
dentry_root^.name := '/' ;
dentry_root^.len := 1 ;
dentry_root^.down_tree := nil ;
dentry_root^.flags := i_root^.flags ;
dentry_root^.state := st_incache ;


i_root^.count += 1;
i_root^.i_dentry^.count += 1;
Tarea_Actual^.cwd := i_root ;


printkf('/Vvfs/n ... root mounted\n',[]);

{ bienvenida al usuario }
//toro_msg;

exit;

_exit :

printkf('/Vvfs/n : Imposible to mount root\n',[]);
debug($1987);

end;

{ * name_i :                                                    *
  *                                                             *
  * path : puntero a una ruta                                   *
  * retorno : puntero a el ultimo inodo de ruta                 *
  *                                                             *
  * Funcion que realiza la busqueda de una ruta a traves del    *
  * cache del sistema                                           *
  *                                                             *
  ***************************************************************
}
function name_i (path : pchar ) : p_inode_t ;
var ini,act : p_dentry ;
    tmp : string ;
    cont : dword ;
begin

act := nil ;
cont := 1 ;

{posicion relativa de comienzo}
if path^ = '/' then
 begin
  ini := dentry_root;
  path += 1;
  end
  else ini := tarea_Actual^.cwd^.i_dentry ;

  ini^.count += 1;

while (path^ <> #0) do
 begin

   if path^ = '/' then
    begin

     {marco el final de cadena}
     tmp[0] := char(cont - 1 );

     if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

     {la busqueda solo se realiza sobre inodos dir!!}
     if (ini^.ino^.mode  <> dt_dir) then
      begin
       put_dentry (ini);
       exit (nil);
      end;

     {se pide la entrada al cache}
     act := Alloc_Entry (ini^.ino,tmp);

     put_dentry (ini);

     if act = nil then exit(nil);

     {los permisos me permiten leer??}
     if (act^.flags and I_RO <> I_RO ) then
      begin
       put_dentry(act);
       exit(nil);
      end;

     ini := act;
     path += 1;
     cont := 1 ;
     continue;
    end;

 tmp[cont] := path^;
 path += 1;
 cont += 1;

 end;


 if (path-1)^ = '/' then exit (ini^.ino)
  else
   begin

    tmp[0] := char(cont - 1);

    {es un dentry de montage??}
    if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

    if (ini^.ino^.mode <> dt_dir) then
     begin
      put_dentry (ini);
      exit(nil);
     end;


    act := Alloc_Entry (ini^.ino,tmp);

    put_dentry (ini);

    if act = nil then exit(nil);

    {se poseen permisos de lectura???}
    if (act^.flags and I_RO <> I_RO ) then
     begin
      Put_dentry (act);
      exit(nil);
    end;

    exit(act^.ino);
    end;

end;





{ * Last_dir                                                            *
  *                                                                     *
  * path : Puntero a una ruta                                           *
  * retorno : ultimo inodo accedido                                     *
  *                                                                     *
  * rastrea una ruta hasta el ultimo archivo y si este no existe devue  *
  * lve el directorio ultimo                                            *
  *                                                                     *
  ***********************************************************************
}

function last_dir (path : pchar ) : p_inode_t ;
var ini,act : p_dentry ;
    tmp : string ;
    cont : dword ;
begin

act := nil ;
cont := 1 ;

{posicion relativa de comienzo}
if path^ = '/' then
 begin
  ini := dentry_root;
  path += 1;
  end
  else ini := tarea_Actual^.cwd^.i_dentry ;

  ini^.count += 1;

while (path^ <> #0) do
 begin

   if path^ = '/' then
    begin

     {marco el final de cadena}
     tmp[0] := char(cont - 1 );

     if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

     {la busqueda solo se realiza sobre inodos dir!!}
     if (ini^.ino^.mode  <> dt_dir) then
      begin
       ini^.parent^.count += 1;
       last_dir := ini^.parent^.ino ;
       put_dentry (ini);
       exit;
      end;

     {se pide el dentry al cache}
     act := Alloc_Entry (ini^.ino,tmp);

     if act = nil then exit(ini^.ino);

     {los permisos me permiten leer??}
     if (act^.flags and I_RO <> I_RO ) then
      begin
       put_dentry(act);
       last_dir := ini^.ino ;
      end;

     put_dentry (ini );

     ini := act;
     path += 1;
     cont := 1 ;
     continue;
    end;

 tmp[cont] := path^;
 path += 1;
 cont += 1;

 end;


 if (path-1)^ = '/' then
  begin

   {siempre sale con un dir!!}
   if (ini^.ino^.mode = dt_dir) then exit(ini^.ino)
    else
     begin
      ini^.parent^.count += 1;
      last_dir := ini^.parent^.ino ;
      put_dentry (ini);
      exit;
     end;

  end
  else
   begin

    tmp[0] := char(cont - 1);

    {es un dentry de montage??}
    if ini^.down_mount_tree <> nil then
      begin
       put_dentry (ini);
       ini := ini^.down_mount_tree;
       ini^.count += 1;
      end;

    if (ini^.ino^.mode <> dt_dir) then
     begin
      ini^.parent^.count += 1;
      last_dir := ini^.parent^.ino;
      put_dentry (ini);
      exit;
     end;

    {aqui se realiza todo el lookup y devuelve una entrada en el cache de nombres}
    act := Alloc_Entry (ini^.ino,tmp);

    if act = nil then exit(ini^.ino);

    {se poseen permisos de lectura???}
    if (act^.flags and I_RO <> I_RO ) then
     begin
      last_dir := ini^.ino;
      Put_dentry (act);
    end;

    put_dentry (ini);

    exit(act^.ino);
    end;

end;



const
COFF_MAGIC=$14c;

COFF_TEXT=$0020;
COFF_BBS=$0080;
COFF_DATA=$0040;



Type
p_coff_header=^coff_header;
coff_header=record

 f_magic:word;	{/* magic number			*/}
 f_nscns:word;	{/* number of sections		*/}
 f_timdat:dword;	{/* time & date stamp		*/}
 f_symptr:dword;	{/* file pointer to symtab	*/	   }
 f_nsyms:dword;     {/* number of symtab entries	*/                }
 f_opthdr:word;	{/* sizeof(optional hdr)		*/}
 f_flags:word;	{/* flags			*/	   }

end;

p_coff_sections=^coff_sections;
coff_sections=record

	s_name:array[1..8] of char;	{/* section name			*/}
	s_paddr:dword;	                {/* physical address, aliased s_nlib */	   }
	s_vaddr:dword;	                {/* virtual address		*/	   }
	s_size:dword;		{/* section size			*/}
	s_scnptr:dword;	{/* file ptr to raw data for section */}
	s_relptr:dword;	{/* file ptr to relocation	*/}
	s_lnnoptr:dword;	{/* file ptr to line numbers	*/}
	s_nreloc:word;	{/* number of relocation entries	*/}
	s_nlnno:word;	{/* number of line number entries*/}
	s_flags:dword;	{/* flags			*/}
end;


Type
p_coff_opheader=^coff_optheader;
coff_optheader=record
  magic:word;          {/* type of file                         */}
  vstamp:word;         {/* version stamp                        */}
  tsize:dword;         {/* text size in bytes, padded to FW bdry*/}
  dsize:dword;         {/* initialized data    "  "             */}
  bsize:dword;         {/* uninitialized data  "  "             */}
  entry:pointer;         {/* entry pt.                            */}
  text_start:dword;    {/* base of text used for this file      */}
  data_start:dword;    {/* base of data used for this file      */}

end;

  PELFHeader = ^TELFHeader;
  TELFHeader = packed record
    e_ident: array [0..15] of byte;
    e_type: word;   { Object file type }
    e_machine: word;
    e_version: dword;
    e_entry: pointer;
    e_phoff: pointer;
    e_shoff: pointer;
    e_flags: dword;
    e_ehsize: word;
    e_phentsize: word;
    e_phnum: word;
    e_shentsize: word;
    e_shnum: word;
    e_shstrndx: word;
  end;

  PELFProgramHeader = ^TELFProgramHeader;
  TELFProgramHeader = packed record
    p_type   : dword;
    p_offset : dword;
    p_vaddr  : dword;
    p_paddr  : dword;
    p_filesz : dword;
    p_memsz  : dword;
    p_flags  : dword;
    p_align  : dword;
  end;

{$DEFINE set_errno := Tarea_Actual^.errno  }
{$DEFINE clear_errno := Tarea_Actual^.errno := 0 }

const MAX_ARG_PAGES = 10 ;

{ * get_args_size : simple funcion que devuelve el tama¤o de los argumentos *
}
function get_args_size (args : pchar) : dword;
var cont : dword ;
begin

cont := 0 ;
If args = nil then exit(1);

while (args^ <> #0) do
 begin
 args += 1;
 If (cont div Page_Size) = Max_Arg_Pages then break
 else cont += 1;
end;
exit(cont + 1);
end;


{ * get_argc : devuelve la cantidad de argumentos pasados * }

function get_argc ( args : pchar) : dword ;
var tmp : dword ;
begin

if args = nil then exit(0);

tmp := 0 ;

{ esto puede seguir hasta el infinito!!! }
while (args^ <> #0) do
 begin
  if args^ = #32 then tmp += 1;
  args += 1;
 end;

tmp += 1 ;

if (args-1)^ = #32 then tmp -= 1 ;

exit(tmp);
end;


{ * Sys_Ioctl :                                                         *
  *                                                                     *
  * Fichero : Descriptor de Archivo                                     *
  * req : Numero de procedimiento                                       *
  * argp : Puntero a los argumentos                                     *
  * Retorno : -1 si fallo                                               *
  *                                                                     *
  *                                                                     *
  * Implementacion de la llamada al sistema IOCTL donde se llama a un   *
  * procedimiento de control de un  driver dado                         *
  *                                                                     *
  ***********************************************************************
}


function sys_ioctl (Fichero , req : dword ; argp : pointer) : dword ;cdecl;
var fd : p_file_t ;
begin

If (Fichero > 32) then
 begin
  set_errno := -EBADF ;
  exit(-1);
 end;

fd := @Tarea_Actual^.Archivos[Fichero];

If fd^.f_op = nil then
 begin
  set_Errno := -EBADF ;
  exit(-1);
 end;

If fd^.f_op^.ioctl = nil then
 begin
  set_errno := -EPERM ;
  exit(-1);
 end;

exit(fd^.f_op^.ioctl(fd,req,argp));

end;


{ * Sys_chdir :                                                         *
  *                                                                     *
  * path : Puntero a ruta del nuevo dir                                 *
  * retorno : 0 si ok o -1 si falla                                     *
  *                                                                     *
  * Implementacion de la llamada al sistema que cambia el directorio    *
  * actual de  trabajo                                                  *
  *                                                                     *
  ***********************************************************************
}
function sys_chdir(path : pchar) : dword ; cdecl ;
var tmp : p_inode_t ;
begin
tmp := name_i (path);

if (tmp = nil) then
 begin
  set_Errno := -ENOENT ;
  exit(-1);
 end;
 
{si o si deve ser un dir}
if not(Is_Dir (tmp)) then
 begin
  put_dentry (tmp^.i_dentry);
  set_errno := -ENOTDIR ;
  exit(-1);
 end;

{se devuelve el q estaba antes}
put_dentry (Tarea_Actual^.cwd^.i_dentry);

Tarea_Actual^.cwd := tmp ;

clear_errno;
exit(0);
end;



{ * Sys_Stat :                                                         *
  *                                                                    *
  * path : Ruta al archivo                                             *
  * buffer : Lugar donde sera copiado el inodo                         *
  * Devuelve : 0 si fue correcto o <> 0 sino                           *
  *                                                                    *
  * Esta llamada al sistema devuelve la informacion guardada dentro de *
  * un inodo de un archivo dado                                        *
  *                                                                    *
  **********************************************************************
}

function sys_stat ( path : pchar ; buffer : pointer ) : dword ; cdecl;
var tmp : p_inode_t;
    s: p_inode_tmp;
begin
tmp := name_i(path);

{Esto es importante puesto que puede ocacionar la escritura}
{de areas de codigo del sistema}


If buffer < pointer(High_Memory) then
 begin
  set_errno := -EFAULT ;
  exit(-1);
 end;

If (tmp = nil) then
 begin
  set_errno := -ENOENT ;
  exit(-1);
 end;

Inode_lock (@tmp^.wait_on_inode);
s := buffer;

s^.ino := tmp^.ino;
s^.mode := tmp^.mode;
s^.size := tmp^.size;
//memcopy(tmp,buffer,sizeof(inode_t));
Inode_unlock (@tmp^.wait_on_inode);

put_dentry(tmp^.i_dentry);

clear_errno ;

exit(0);

end;

// SysExec:
//
// Path: path to a file
// Args: pointer to an array of arguments. It is not used yet
// Return: 0 if fails, or the PID of the new process if sucesses
//
// This function creates a new process from a ELF32 binary. It is based on the function implemented at
// routix.sourceforge.net.
//
function SysExec(Path, Args : pchar): DWORD; cdecl;
var tmp: p_inode_t;
    elf_hd: TELFHeader;
    argccount, count, startaddr, ret, count_pg, nr_page, ppid, argc: dword;
    text_sec, data_sec: TELFProgramHeader;
    tmp_fp: file_t;
    new_tarea: p_tarea_struc;
    cr3_save, page, page_args, pagearg_us: pointer;
    nd: pchar ;
begin
  Result := 0;
  ppid:= Tarea_Actual^.pid;
  tmp:= name_i(path);

  set_errno := -ENOENT ;
  If tmp = nil then
  begin
    Result := 0;
    Exit;
  end;

  set_errno := -EACCES ;

  if (tmp^.flags and I_XO <> I_XO) and (tmp^.flags and I_RO <> I_RO) then
  begin
    put_dentry (tmp^.i_dentry);
    Exit;
  end;

  set_errno := -ENOEXEC ;

  if tmp^.mode <> dt_Reg then
  begin
    put_dentry (tmp^.i_dentry);
    Exit;
  end;

  // create a temporal descriptor
  tmp_fp.inodo := tmp;
  tmp_fp.f_pos := 0;
  tmp_fp.f_op := tmp^.op^.default_file_ops ;

  // get elf header
  ret := tmp_fp.f_op^.read(@tmp_fp, sizeof(TELFHeader), @elf_hd);

  set_errno := -EIO ;

  If ret = 0 then
  begin
    put_dentry(tmp^.i_dentry);
    Exit;
  end;

  set_errno := -ENOEXEC;

  // check magic number
  If (elf_hd.e_ident[1] <> Byte('E')) or (elf_hd.e_ident[2] <> Byte('L')) then
  begin
    put_dentry(tmp^.i_dentry);
    Exit;
  end;

  set_errno := -ENOEXEC;
  startaddr := DWORD(elf_hd.e_entry);

  // seek on the starting position of the program headers
  tmp_fp.f_pos := DWORD(elf_hd.e_phoff);
  set_errno := -EIO;

  // The first programs-header must be the .text and the second one must be the .data + .bbs.
  // These sections must be 4k-aligned and stored in the file one after the other.
  ret := tmp_fp.f_op^.read(@tmp_fp, sizeof(TELFProgramHeader), @text_sec);

  If ret = 0 then
  begin
    put_dentry(tmp^.i_dentry);
    Exit;
  end;

  ret := tmp_fp.f_op^.read(@tmp_fp, sizeof(TELFProgramHeader), @data_sec);

  If ret = 0 then
  begin
    put_dentry(tmp^.i_dentry);
    Exit;
  end;

  set_errno := -ENOEXEC;

  new_tarea := Proceso_Crear(ppid, Sched_RR);
  If new_tarea = nil then
  begin
    put_dentry(tmp^.i_dentry);
    Exit;
  end;

  lock(@mem_wait);

  If (text_sec.p_memsz + data_sec.p_memsz) >=  MM_MEMFREE then
  begin
    unlock(@mem_wait);
    Proceso_Eliminar (new_tarea);
    put_dentry(tmp^.i_dentry);
    Exit;
  end;

  // create two memory regions
  // one for .text and .data
  // and one for stack
  with new_tarea^.text_area do
  begin
    size := 0 ;
    flags := VMM_WRITE;
    add_l_comienzo := pointer(HIGH_MEMORY);
    add_l_fin := pointer(HIGH_MEMORY - 1);
  end;

  with new_tarea^.stack_area do
  begin
    size := 0;
    flags := VMM_WRITE;
    add_l_comienzo := pointer(STACK_PAGE);
    add_l_fin := pointer(STACK_PAGE - 1);
  end;

  argc := get_args_size (args);
  argccount := get_argc(args);
  page_Args := get_free_kpage ;

  If argc > 1 then
  begin
    If argc > Page_Size then
      argc := Page_Size;
    memcopy(args, page_Args + (Page_size - argc)-1 , argc);
  end else
  begin
    nd := Page_args;
    Inc(nd, Page_size - 2);
    nd^ := #0 ;
  end;

  Save_Cr3;
  Load_Kernel_Pdt;

  // read .text and then .data
  // this reads all the sections as multiples of of the PAGE_SIZE
  count := 0;
  count_pg := 0;

  // the binary must have at least two pages: one for data and one for text
  nr_page := text_sec.p_memsz div Page_Size;
  if text_sec.p_memsz mod Page_Size <> 0 then Inc(nr_page);
  nr_page += data_sec.p_memsz div Page_Size;
  If data_sec.p_memsz mod Page_Size <> 0 then Inc(nr_page);

  tmp_fp.f_pos := text_sec.p_offset;

  repeat
    page := get_free_page;
    If page = nil then
    begin
      vmm_free(new_tarea,@new_tarea^.text_area);
      Proceso_Eliminar(new_tarea);
      unlock(@mem_wait);
      put_dentry(tmp^.i_dentry);
      Exit;
    end;
    Inc(count, tmp_fp.f_op^.read(@tmp_fp, Page_Size, page));
    vmm_map(page,new_tarea,@new_tarea^.text_area);
    Inc(count_pg);
  until (nr_page = count_pg);

  vmm_alloc(new_tarea, @new_tarea^.stack_area, Page_Size);

  clone_filedesc(@Tarea_Actual^.Archivos[1],@new_tarea^.Archivos[1]);
  clone_filedesc(@Tarea_Actual^.Archivos[2],@new_tarea^.Archivos[2]);

  // map args
  pagearg_us := get_free_page ;
  memcopy(page_args , pagearg_us , Page_Size);
  free_page (page_args);
  vmm_map(pagearg_us,new_tarea,@new_tarea^.stack_area);

  unlock(@mem_wait);

  new_tarea^.reg.esp := pointer(new_tarea^.stack_area.add_l_fin - argc)  ;
  new_tarea^.reg.eip := pointer(startaddr);
  new_tarea^.reg.eax := argccount ;
  new_tarea^.reg.ebx := LongInt(new_tarea^.reg.esp) ;
  new_tarea^.reg.ecx := 0 ;

  Inc(Tarea_actual^.cwd^.count);
  Inc(Tarea_Actual^.cwd^.i_dentry^.count);
  new_tarea^.cwd := Tarea_Actual^.cwd ;

  Restore_Cr3;
  add_task (new_tarea);
  put_dentry(tmp^.i_dentry);

  clear_errno;
  Result := new_tarea^.pid;
end;
end.
