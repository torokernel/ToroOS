{$I errno.inc}


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

{$I dcache.inc}
