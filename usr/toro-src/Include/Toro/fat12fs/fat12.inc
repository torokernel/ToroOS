const


fat_start = 2;
sector_size = 512 ;

fat12_Maxsector = 2847;

attr_read_only = 1 ;
attr_hidden = 2 ;
attr_system = 4;
attr_volume_id = 8 ;
attr_directory = $10 ;
attr_archivo = $20;

{ estos los he creado para poder implementar mknod }
attr_blk = 64 ;
attr_chr = 128 ;

last_sector = $ffff ;

first_dir = '.          ';
second_dir = '..         ';

type

{bootsector de la fat}
pfat_boot_sector = ^fat_boot_sector ;

fat_boot_sector = packed record

BS_jmpBott: array[1..3] of byte;
BS_OEMName: array[1..8] of char;
BPB_BytsPerSec: word;
BPB_SecPerClus: byte;
BPB_RsvdSecCnt: word;
BPB_NumFATs: byte;
BPB_RootEntCnt: word;
BPB_TotSec16: word;
BPB_Media: byte;
BPB_FATSz16: word;
BPB_SecPerTrk: word;
BPB_NumHeads: word;
BPB_HiddSec: dword;
BPB_TotSec32: dword;
BS_DrvNum: byte;
BS_Reserved1: byte;
BS_BootSig: byte;
BS_VolID: dword;
BS_VolLab : array[1..11] of char;
BS_FilSysType : array[1..8] of char;
end;



pdirectory_entry = ^directory_entry ;

directory_entry = packed record
Nombre : array[1..11] of char ;
Atributos : byte ;
Reservado : array[1..10] of byte ;
mtime : word ;
mdate : word;
EntradaFAT  :word ;
size : dword ;
end;


{ entrada de directorio con nombre largo  }
pvfatdirectory_entry = ^vfatdirectory_entry  ;

vfatdirectory_entry = record
res : byte ;
name1 : array[1..10] of char ;
atributos : byte ;
tipe : byte ;
check : byte ;
name2 :array [1..12] of char ;
res1 : word ;
name3 : array[1..4] of char ;
end;

{tama¤o de la cola hash de inodos}
const Max_Inode_Hash = 1024 ;

type

{estructura de la tabla hash}
pfat_inode_cache = ^fat_inode_cache ;
psb_fat = ^super_fat;
pHash_Ino = ^tHash_ino;


{estructura de un sb de fat}
super_fat = record
tfat : dword ;
pfat : ^byte ;
pbpb : pfat_boot_sector ;
hash_ino : pHash_Ino ;
end;


{entrada en el cache de inodos}
fat_inode_cache = record

{ este puntea a la posicion dentro del bh donde se encuentra la entrada }
dir_entry : pdirectory_entry ;

{ este bh contiene al dir donde se encuentra la entrada del fichero }
bh : p_buffer_head ;

{ numero de inodo que es igual al numero de la entrada fat }
ino : dword ;

sb : psb_fat ;
next_ino_cache : pfat_inode_cache ;
prev_ino_cache : pfat_inode_cache ;
end;

tHash_Ino  = array[1..Max_Inode_Hash] of pfat_inode_cache ;


const day_n : array[0..15] of word = ( 0,31,59,90,120,151,181,212,243,273,304,334,0,0,0,0);

