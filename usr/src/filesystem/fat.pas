Unit fat;

interface
uses printk, filesystem, arch, memory, process;

const mounted : boolean = false ;

var fat_fstype : file_system_type ;
    fat_super_op : super_operations;
    fat_file_op : file_operations ;

    {estructura temporal }
    fattmp : array[0..4608] of byte;
    fat_inode_op : inode_operations;

{$DEFINE set_errno := Tarea_Actual^.errno  }
{$DEFINE clear_errno := Tarea_Actual^.errno := 0 }


procedure fatfs_init ;

implementation
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
function find_in_cache ( ino : dword ; sb : p_super_block_t ) : pfat_inode_cache ;forward;

function chararraycmp (ar1 , ar2 : pchar ; len :dword ): boolean ;inline;
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


{ * alloc_super_fat : crea la estrcutura de un superbloque para fat * }

function alloc_super_fat  : psb_fat ;inline;
var tmp : psb_fat ;
    ret : dword ;
begin

tmp := kmalloc (sizeof(super_fat));

if tmp = nil then exit(nil);

tmp^.hash_ino := kmalloc (4096) ;

if tmp^.hash_ino = nil then
 begin
  kfree_s (tmp,sizeof(super_fat));
  exit(nil);
 end;


{es limpiada la cola hash}
for ret := 1 to Max_Inode_Hash do tmp^.hash_ino^[ret] := nil ;

exit(tmp);
end;

{ * remove_super_fat : libera todo la memoria dentro de un descriptor de sb * }

procedure remove_super_fat ( sb : psb_fat) ;inline;
begin
kfree_s (sb^.hash_ino,4096);
kfree_s (sb,sizeof(super_fat));
end;


{ * carga toda la fat en el cache del sistema suelen ser 9 bloques * }

function cargar_fat ( sb : p_super_block_t ) : boolean ;
var cont : dword ;
    sb_fat : psb_fat ;
    bh : p_buffer_head ;
    pfat : pointer ;
label _exit ;
begin

{estructura de la super de fat}
sb_fat := sb^.driver_space ;

pfat := @fattmp;

{son cargados en cache los bloques pertenecientes a la fat}
{y copiados a un buffer para tenerlos de forma continua}
for cont := 1 to sb_fat^.pbpb^.bpb_fatsz16 do
 begin
 bh := get_block (sb^.mayor,sb^.menor,cont,sb_fat^.pbpb^.bpb_bytspersec) ;

 if bh = nil then goto _exit ;

 memcopy (bh^.data,pfat,sb_fat^.pbpb^.bpb_bytspersec);
 pfat += sb_fat^.pbpb^.bpb_bytspersec;
 end;

sb_fat^.pfat := @fattmp;
exit(true);

_exit :
printkf('/Vfat12fs/n : Error al Cargar FAT12\n',[]);
exit(false);
end;

{ * realiza la busqueda de un sector dentro de la fat * }

function get_sector_fat (sb : p_super_block_t ; sector : dword) : word ;
var lsb , msb  : byte ;
    offset: dword ;
    retorno : word ;
    sb_fat : psb_fat ;
begin

sb_fat := sb^.driver_space ;

sector -= 31 ;

offset := (sector * 3 ) shr 1 ;

lsb := sb_fat^.pfat[offset] ;
msb := sb_fat^.pfat[offset+1] ;

if (sector mod 2 ) <>  0  then retorno := ((msb shl 8 ) or lsb ) shr 4
else retorno := ((msb shl 8) or lsb ) and $FFF ;

if (retorno = $FFF) then exit(last_sector) else exit(retorno + 31) ;

end;
{$ASMMODE ATT}
function strupper(p : pchar) : pchar;assembler;
asm
        movl    p,%esi
        orl     %esi,%esi
        jz      .LStrUpperNil
        movl    %esi,%edi
.LSTRUPPER1:
        lodsb
        cmpb    $97,%al
        jb      .LSTRUPPER3
        cmpb    $122,%al
        ja      .LSTRUPPER3
        subb    $0x20,%al
.LSTRUPPER3:
        stosb
        orb     %al,%al
        jnz     .LSTRUPPER1
.LStrUpperNil:
        movl    p,%eax
end ['EAX','ESI','EDI'];

{ * Aclaracion !!! : los procedimientos de fechas estas mall!!! * }

{ * date_dos2unix : Convierte una fecha de MSDOS a una de unix , codigo  *
  * extraido de : linux/fs/fat/misc.c                                    *
  *                                                                      *
  *                                                                      *
  ************************************************************************
}

function date_dos2unix ( time  , date : word ) : dword ;[public , alias :'DATE_DOS2UNIX'];
var sec , min , hour , day , mon , year  : dword ;
begin

sec:= time and %11111 ;
min := (time shr 5 ) and %111111 ;
hour := (time shr 11) ;

day := date and %11111 ;
mon := (date shr 5) and %1111 ;
year := (date shr 9) ;

mon -= 2 ;

If (0 >= mon) then
 begin
 mon += 12 ;
 year -= 1;
end;


exit(   (( ((year div 4 - year div 100 + year div 400 + 367 * mon div 12 + day)  +(year * 365)  -(719499))
   *24 +hour )
   *60 +min  )
   *60 +sec);

end;


{ * date_unix2dos : realiza la conversion del formato horario de unix   *
  * a el de msdos , codigo extraido de : linux/fs/fat/misc.c            *
  *                                                                     *
  ***********************************************************************
}
procedure date_unix2dos ( unix_date : dword ; var time  : word ;  var date : word) ;[public , alias :'DATE_UNIX2DOS'];
var day,year,mon,nl_day : dword ;
begin

time := (unix_date mod 60 ) div 2 + (((unix_date div 60) mod 60) shl 5) +
(((unix_date  div 3600) mod 24) shl 11);

day := unix_date div 86400 - 3652 ;

if ((year+3) div 4+365*year > day) then year -= 1;

day -= (year + 3) div 4 + 365 * year ;

if (day = 59) and not(year and 3 = 0) then
 begin
 nl_day := day ;
 mon := 2
 end else
  begin
  if  day <= 59 then nl_day := (year and 3) or  (day-1)
   else nl_day := (year and 3) or  day;

  for mon := 0 to 12 do
   if (day_n[mon] > nl_day) then  break;
  end;

  date := nl_day - day_n[mon -1] +1+(mon shl 5)+ (year shl 9);

end;


{ * unicode_to_unix : el nombre en unicode de los nombres largos a ascii  * }

procedure unicode_to_unix ( longname : pvfatdirectory_entry ; var destino : string) ; [public , alias : 'UNICODE_TO_UNIX'];
var count : dword ;
    i: dword;
begin

i := 1;

{ se lee la primera parte del nombre }
for count := 0 to 4 do
 if longname^.name1[(count*2)+1] = #0 then exit 
 else 
 begin
 	destino[i] := longname^.name1[(count*2)+1] ;
        i+=1;
 end;

{ se lee la segunda parte del nombre }
for count := 0 to 5 do
  if longname^.name2[(count*2)+1] = #0 then exit 
  else 
  begin
	destino[i] := longname^.name2[(count*2)+1] ;
	i+=1;
  end;

{ se lee la tercera parte }
for count := 0 to 1 do
  if longname^.name3[(count*2)+1] = #0 then exit 
  else 
  begin
  	destino[i] :=  longname^.name3[(count*2)+1] ;
        i+=1;
  end;

destino[0] := char(i-1);
end;


{ * convierte un nombre de una entrada fat a una de toro * }

procedure unix_name ( fatname : pchar  ; var destino : string ) ; [public , alias : 'UNIX_NAME'];
var tmp : array[0..11] of char ;
    count ,ret: dword ;

label _ext , _exit ;
begin

fillbyte (tmp,11,32);

for count := 0 to 7 do
 begin
  if fatname[count] = #32 then goto _ext ;
  tmp[count] := fatname[count];
 end;

 count += 1 ;

_ext :

 if fatname[8] = #32 then goto _exit;

 tmp[count] := #46 ;
 count += 1;

 for ret := 8 to 11 do
  begin

  if fatname[ret]= #32 then break
   else tmp[count] := fatname[ret];
   count += 1;
  end;

_exit :

 memcopy(@tmp,@destino[1],count); //destino := tmp ;
 destino[0] := chr(count);

end;



{ * sencillo func. que rastrea un bloque de un dir en busca de un name * }

function find_dir ( bh : p_buffer_head ; name : pchar  ; var res : pdirectory_entry ) : dword ;
var count  , cont : dword ;
    pdir : pdirectory_entry ;
    plgdir : pvfatdirectory_entry ;
    buff : string ;
    lgcount : dword ;
begin

pdir := bh^.data ;
count := 1 ;
lgcount := 0 ;

repeat

  case pdir^.nombre[1] of
  #0 : exit(-1);
  #$E5 : lgcount := 0 ;
  else
   begin

    { se encontro una entrada de nombre largo }
    if (pdir^.atributos = $0F) and (count <= (512 div sizeof (directory_entry))) then
     lgcount += 1
      else
       begin

        { tiene entrada de nombre largo ? }
        if (lgcount > 0 ) then
         begin
          plgdir := pointer (pdir);

          buff := '';

          { se trae todo el nombre }
          for cont := 0 to (lgcount-1) do
           begin
            plgdir -= 1 ;
            unicode_to_unix (plgdir,buff);
           end;

           { puede ocacionar problemas futuros !! }
           strupper (@buff[1]);

          { se compara y se sale }
          if chararraycmp (@buff[1],name,byte(buff[0])) then
           begin
            res := pdir ;
            exit(0);
           end;

         end
          else { no tiene entrada de nombre largo }
           begin

             unix_name (@pdir^.nombre,buff);

             { se compara solo con 11 caracteres }
             if chararraycmp (@buff[1],name,byte(buff[0])) then
              begin
               res := pdir ;
               exit(0);
              end;

           end;

        lgcount := 0 ;
       end;

   end;
 end; { case }

pdir += 1 ;
count += 1 ;

until (count > (512 div sizeof (directory_entry))) ;

res := nil ;
exit(0);
end;


{ * find_rootdir : realiza la busqueda de una entrada dentro del rootdir * }

function find_rootdir ( bh : p_buffer_head ; name : pchar  ; var res : pdirectory_entry ) : dword ;
var count  , cont : dword ;
    pdir : pdirectory_entry ;
    plgdir : pvfatdirectory_entry ;
    buff : string ;
    lgcount : dword ;
begin

pdir := bh^.data ;
count := 1 ;
lgcount := 0 ;

repeat

  case pdir^.nombre[1] of
  #0 : exit(-1);
  #$E5 : lgcount := 0 ;
  else
   begin

    { se encontro una entrada de nombre largo }
    if (pdir^.atributos = $0F) and (count <= (512 div sizeof (directory_entry))) then
     lgcount += 1
      else
       begin

        { tiene entrada de nombre largo ? }
        if (lgcount > 0 ) then
         begin
          plgdir := pointer (pdir);

          buff := '';

          { se trae todo el nombre }
          for cont := 0 to (lgcount-1) do
           begin
            plgdir -= 1 ;
            unicode_to_unix (plgdir,buff);
           end;

           { puede ocacionar problemas futuros !! }
           strupper (@buff[1]);

          { se compara y se sale }
          if chararraycmp (@buff[1],name,byte(buff[0])) then
           begin
            res := pdir ;
            exit(0);
           end;

         end
          else { no tiene entrada de nombre largo }
           begin

             unix_name (@pdir^.nombre,buff);

             { se compara solo con 11 caracteres }
             if chararraycmp (@buff[1],name,byte(buff[0])) then
              begin
               res := pdir ;
               exit(0);
              end;

           end;

        lgcount := 0 ;
       end;

   end;
 end; { case }

pdir += 1 ;
count += 1 ;

until (count > (512 div sizeof (directory_entry))) ;

res := nil ;
exit(0);
end;


const
 FAT12ID : pchar = 'FAT12';

{ * Fat12fs_Read_Super :                                                *
  *                                                                     *
  * sb : Puntero a un superbloque                                       *
  * Retorno : puntero al sp o nil si falla                              *
  *                                                                     *
  * Realiza la lectura de un superbloque de fat12 y carga toda la fat   *
  *                                                                     *
  ***********************************************************************
}
function fat_read_super (sb : p_super_block_t ) : p_super_block_t;
var bh , bh2 : p_buffer_head ;
    sb_fat : psb_fat ;
    ret  : dword ;
label _exit;
begin

if mounted then
 begin
  printkf('/Vfatfs/n : Solo se puede montar una unidad \n',[]);
  exit(nil)
 end;

sb_fat := alloc_super_fat ;


if sb_fat = nil then exit(nil);

bh := get_block (sb^.mayor,sb^.menor,0,512);

if bh = nil then goto _exit ;

sb_fat^.pbpb := bh^.data ;

{letras magicas , por ahora solo soporto Fat12}
if not(chararraycmp(@sb_fat^.pbpb^.bs_filsystype[1],FAT12ID,5)) then goto _exit ;

sb^.driver_space := sb_fat ;

{no utilizado por ahora !!!}
sb_fat^.tfat := 1 ;

sb^.blocksize := sb_fat^.pbpb^.bpb_bytspersec;

{se carga en memoria toda la fat}
if cargar_fat (sb) then else goto _exit ;

sb^.op := @fat_super_op;

sb^.ino_root := 1;

{ solo se limita a un montage }

mounted := true ;

exit(sb);

_exit :
 remove_super_fat (sb_fat);
 printkf('/VVFS/n : Error de lectura de Super FAT12\n',[]);
 exit(nil);
end;


procedure Pop_Inode(Nodo :pfat_inode_cache;var Nodo_tail : pfat_inode_cache);
begin

If (nodo_tail= nodo) and (nodo_tail^.next_ino_cache = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_ino_cache := nil;
 nodo^.next_ino_cache := nil;
 exit;
end;

if (Nodo_tail = nodo) then Nodo_tail := Nodo^.next_ino_cache ;

nodo^.prev_ino_cache^.next_ino_cache := nodo^.next_ino_cache;
nodo^.next_ino_cache^.prev_ino_cache := nodo^.prev_ino_cache ;
nodo^.next_ino_cache := nil ;
nodo^.prev_ino_cache := nil;
end;

procedure Push_Inode(Nodo: pfat_inode_cache; var nodo_tail: pfat_inode_cache);
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_ino_cache := Nodo ;
 nodo^.prev_ino_cache := Nodo ;
 exit;
end;

nodo^.prev_ino_cache := nodo_tail^.prev_ino_cache ;
nodo^.next_ino_cache := nodo_tail ;
nodo_tail^.prev_ino_cache^.next_ino_cache := Nodo ;
nodo_tail^.prev_ino_cache := Nodo ;
end;



procedure Inode_Hash_Push ( ino : pfat_inode_cache ) ;inline;
var tmp : dword ;
begin
tmp := ino^.ino mod Max_Inode_Hash ;
push_inode (ino,ino^.sb^.hash_ino^[tmp]);
end;



procedure Inode_Hash_Pop ( ino : pfat_inode_cache) ; inline ;
var tmp : dword ;
begin
tmp := ino^.ino mod Max_Inode_hash ;
pop_inode (ino,ino^.sb^.hash_ino^[tmp]);
end;

{ * Alloc_Inode_Fat :                                                   *
  *                                                                     *
  * entry : Puntero a una estructura directorio fat                     *
  * bh : puntero al buffer head del dir                                 *
  *                                                                     *
  * Esta funcion crea la abstraccion entre el vfs y la fat , cada       *
  * inodo de fatfs posee una entrada aqui  , el campo nr_inodo es solo  *
  * un numero id. la cola ligada del cache de fat-inode                 *
  *                                                                     *
  ***********************************************************************
}
function alloc_inode_fat ( sb : psb_fat ; entry : pdirectory_entry ; bh : p_buffer_head ) :pfat_inode_cache;
var tmp : pfat_inode_cache ;
begin

tmp := kmalloc (sizeof(fat_inode_cache));

{no memoria}
if tmp = nil then exit(nil);

{se crea la estructura para el cache}
tmp^.dir_entry := entry ;
tmp^.bh := bh ;
tmp^.ino := entry^.entradafat ;    {identificador de inodo}
tmp^.sb := sb ;

inode_hash_push (tmp);

exit(tmp);
end;



{ * Fat_inode_Lookup :                                                  *
  *                                                                     *
  * ino : puntero a un inodo                                            *
  * dt : entrada buscada                                                *
  *                                                                     *
  * Realiza la busqueda de una entrada dentro de un inodo-fat dir       *
  *                                                                     *
  ***********************************************************************
}
function fat_inode_lookup (ino : p_inode_t ; dt : p_dentry ) : p_dentry ;
var blk , next_sector: dword ;
    bh : p_buffer_head ;
    pdir : pdirectory_entry ;
    fat_entry : array[1..255] of char;
    ino_fat , tmp: pfat_inode_cache;

label _load_ino , find_in_dir ;
begin
fillbyte(fat_entry,sizeof(fat_entry),32);
memcopy (@dt^.name[1],@fat_entry,byte(dt^.name[0]));

{ esto puede traer problemas }
strupper (@fat_entry[1]);

{se busca en root???}
if ino^.ino = 1 then else goto  find_in_dir ;

{se buscara por todo el root}
for blk := 19 to 32  do
 begin

   {este acceso es rapido puesto que estan en cache}
   bh := get_block (ino^.mayor,ino^.menor,blk,512);

   if bh = nil then exit(nil);

   {se busca dentro del dir}
   find_rootdir (bh,@fat_entry,pdir);

   {se encontro la entrada??}
   if pdir <> nil then goto _load_ino;

   put_block (bh);
  end;

exit (nil);

{la entrada se encuentra dentro de un dir}
find_in_dir :

tmp := find_in_cache (ino^.ino,ino^.sb) ;

{primer sector en el area de data}
next_sector := tmp^.dir_entry^.entradafat + 31 ;

while (next_sector <> last_sector) do
 begin
  bh := get_block (ino^.mayor,ino^.menor,next_sector,ino^.blksize);

  if bh = nil then exit(nil);


  {se realiza la busqueda dentro del dir}
  if  find_dir (bh,@fat_entry,pdir) = -1 then
   begin
   {el -1 indica fin de dir y 0 que no se encontro pero no se llego al fin}
   {del dir}
   put_block (bh);
   exit(nil)
   end else if pdir <> nil then goto _load_ino;

  put_block (bh);

  next_sector := get_sector_fat (ino^.sb,next_sector);
 end;

exit(nil);

_load_ino :

 {se crea la entrada en el cache de inodos-fat}
 ino_fat := alloc_inode_fat (ino^.sb^.driver_space,pdir,bh);

 {seguro no hay memoria!!!}
 if ino_fat = nil then
  begin
   put_block (bh);
   exit(nil);
  end;

 {se llama al kernel y se devuelve una estructura de inodos que ya}
 {habia creado previamente}
 dt^.ino := get_inode (ino^.sb,ino_fat^.ino) ;

 exit(dt);
end;


{ * Realiza la busqueda de un inodo en el cache de inodos-fat * }

function find_in_cache ( ino : dword ; sb : p_super_block_t ) : pfat_inode_cache ;
var ino_cache : pfat_inode_cache ;
    tmp : dword ;
    sbfat : psb_fat ;
begin

{ubicacion en la tabla hash}
tmp := ino mod Max_Inode_hash ;

sbfat := sb^.driver_space ;

if sbfat^.hash_ino^[tmp]^.ino = ino then exit(sbfat^.hash_ino^[tmp]);

ino_cache := sbfat^.hash_ino^[tmp];

if ino_cache = nil then exit(nil);

{se buscara por toda la cola un inodo con ese id }
repeat

if ino_cache^.ino = ino then exit(ino_cache);
ino_cache := ino_cache^.next_ino_cache ;
until (ino_cache = sbfat^.hash_ino^[tmp]);

exit(nil);
end;




{ * Fat_Read_Inode :                                                     *
  *                                                                      *
  * ino : Puntero a un inodo                                             *
  *                                                                      *
  * Realiza la lectura de un inodo del cache de inodos-fat               *
  *                                                                      *
  ************************************************************************
}
procedure fat_read_inode (ino : p_inode_t) ;
var ino_cache : pfat_inode_cache ;
begin

{el inodo root es tratado de forma especial}
if ino^.ino = 1 then
 begin
 ino^.blocks := 14 ;
 ino^.size := 14 * 512 ;
 ino^.flags := I_RO or I_WO or I_XO;
 ino^.mode := dt_dir ;
 ino^.state := 0 ;
 ino^.op := @fat_inode_op;
 exit;
end;

{supuestamente un lookup ya cargo una entrada dir para ese inodo}
ino_cache := find_in_cache (ino^.ino , ino^.sb);

if ino_cache = nil then
 begin
  ino^.state := i_dirty ;
  exit;
 end;

{los archivos de sistema son especiales}
if (ino_cache^.dir_entry^.atributos and attr_system = attr_system ) then
   begin

    { implementacion de los inodos de dispositivos }

     { dev de caracteres }
    if (ino_cache^.dir_entry^.atributos and attr_chr = attr_chr) then
     ino^.mode := dt_chr
      { dev de bloque }
      else if (ino_cache^.dir_entry^.atributos and attr_blk = attr_blk) then
       ino^.mode := dt_blk
       else
        begin
         printkf('/VVFS/n : inode desconocido \n',[]);
         ino^.state := i_dirty ;
         exit;
        end;

     ino^.rmenor := ino_cache^.dir_entry^.size and $ff ;
     ino^.rmayor := (ino_cache^.dir_entry^.size shr 16 ) ;
     ino^.size := 0 ;
     ino^.blocks := 0 ;
     ino^.op := nil;
     ino^.state := 0 ;
     ino^.atime := 0 ;
     ino^.ctime := 0  ;
     ino^.mtime := date_dos2unix (ino_cache^.dir_entry^.mtime , ino_cache^.dir_entry^.mdate);
     ino^.dtime := 0 ;

    { proteccion al nodo de dev }
    if (ino_cache^.dir_entry^.atributos and attr_read_only = attr_read_only ) then
    ino^.flags := I_RO else ino^.flags := I_RO or I_WO or I_XO ;

    exit
   end
  else
    begin

    {si hay es un archivo regular }
    if (ino_cache^.dir_entry^.atributos and attr_read_only = attr_read_only ) then
    ino^.flags := I_RO else ino^.flags := I_RO or I_WO or I_XO ;


 {solo existen ficheros y directorio}
  if (ino_cache^.dir_entry^.atributos and attr_directory = attr_directory) then
   begin
    ino^.mode := dt_dir;
    ino^.size := 0 ;

    {los dir. no poseen tamano}
    ino^.blocks := 0 ;
    end
    else
     begin
      ino^.mode := dt_reg ;
      ino^.size := ino_cache^.dir_entry^.size ;
      ino^.blocks := ino^.size div ino^.blksize ;
     end;

ino^.op := @fat_inode_op;
ino^.state := 0 ;

ino^.atime := 0 ;
ino^.ctime := 0  ;
ino^.mtime := date_dos2unix (ino_cache^.dir_entry^.mtime , ino_cache^.dir_entry^.mdate);
ino^.dtime := 0 ;

end;

end;

{ * fat_put_inode : funcion no utilizada por fat                * }

procedure fat_put_inode (ino : p_inode_t) ;
begin
{$IFDEF debug}
printk('/Vfat_put_inode/n : No implementado en fat12fs\n',[]);
{$ENDIF}
end;


{ * Fat_Read_File :                                                     *
  *                                                                     *
  * Fichero : Puntero al descriptor de archivo                          *
  * cont : contador                                                     *
  * buff : puntero donde sera copiado                                   *
  *                                                                     *
  * Realiza la lectura de  archivo en una particion fat                 *
  *                                                                     *
  ***********************************************************************
}
function fat_read_file ( fichero : p_file_t ; cont : dword ; buff : pointer ) : dword ;
var iniblk,inioff ,count,next_clus ,next_sector, ret ,cnt,blk: dword ;
    tmp : pfat_inode_cache ;
    bh : p_buffer_head ;
     k :dword ;
begin

{se busca la entrada en el cache de inodos -fat}
tmp := find_in_cache (fichero^.inodo^.ino , fichero^.inodo^.sb);

{comienzo de la lectura }
iniblk := fichero^.f_pos div fichero^.inodo^.blksize ;
inioff := fichero^.f_pos mod fichero^.inodo^.blksize;


{la lectura sobrepasara el limite}
if (fichero^.f_pos + cont ) > fichero^.inodo^.size then
 begin
  set_errno := -EEOF ;
  cont := fichero^.inodo^.size - fichero^.f_pos ;
 end;

{primer cluster}
next_clus := tmp^.dir_entry^.entradafat + 31 ;

if iniblk = 0 then next_sector := next_clus
else
 begin
  {me devo posicionar sobre el verdadero bloque}
  for ret := next_clus to (next_clus + iniblk - 1 ) do
   begin
   next_sector := get_sector_fat (fichero^.inodo^ .sb,ret);
   if (next_sector = last_sector) then
   {sector no presente}
    begin
     set_errno := -EEOF ;
     exit(0);
    end;
   end;
end;

 cnt := cont ;

 {comienza la transferencia}
 repeat
 bh := get_block (fichero^.inodo^.mayor,fichero^.inodo^.menor , next_sector , fichero^.inodo^.blksize);

 if bh =nil then break ;


 if (cnt > fichero^.inodo^.blksize) then
  begin
   memcopy (bh^.data+inioff,buff,fichero^.inodo^.blksize);
   fichero^.f_pos += fichero^.inodo^.blksize ;
   inioff := 0 ;
   cnt -= fichero^.inodo^.blksize ;
   buff += fichero^.inodo^.blksize ;
  end
   else
    begin
    memcopy (bh^.data+inioff,buff,cnt);
    inioff := 0 ;
    fichero^.f_pos += cnt;
    cnt := 0 ;
   end;

 put_block (bh);
 next_sector := get_sector_fat (fichero^.inodo^.sb,next_sector);

 {final del archivo}
 if next_sector = last_sector then
  begin
   set_errno := -EEOF ;
   break;
   end;

 until (cnt = 0 )  ;

 exit(cont - cnt);

 end;


{ * Fat_Readdir :                                                       *
  *                                                                     *
  * Fichero : puntero a un descriptor de file                           *
  * buffer : puntero a una estructura readdir                           *
  *                                                                     *
  * Esta funcion es la implementacion de readdir leyendo una estructura *
  * del tipo readdir  y se incrementa en 1 la posicion del file         *
  *                                                                     *
  ***********************************************************************
}
function fat_readdir (fichero : p_file_t ; buffer : pointer ) : dword ;
var next_sector, cont ,dircount,rootsec: dword ;
    tmp :pfat_inode_cache ;
    preaddir  , dreaddir: preaddir_entry ;
    dir : pdirectory_entry ;
    dir_long : pvfatdirectory_entry ;
    lgcount : dword ;
    bh : p_buffer_head ;

label _eof  , _readdir_root , _exit ;
begin

dircount := 0;
dir_long := nil ;
lgcount := 0 ;

{deve ser un dirrectorio!!!}
if fichero^.inodo^.mode <> dt_dir then exit(0);

{este deve ser tratado de forma especial}
if fichero^.inodo^.ino = 1 then
 begin
  if fichero^.f_pos = 208 then goto _eof ;
  next_sector := 19;
  goto _readdir_root;
 end;

 {la entrada se realizara sobre un directorio real}
 tmp := find_in_cache (fichero^.inodo^.ino,fichero^.inodo^.sb) ;

 next_sector := tmp^.dir_entry^.entradafat + 31 ;

 {buscare por todos los sectores}
 while (next_sector <> last_sector) do
  begin

  bh := get_block (fichero^.inodo^.mayor,fichero^.inodo^.menor,next_sector,fichero^.inodo^.blksize);

  if bh = nil then
   begin
    set_errno := -EIO ;
    exit(0);
   end;

  dir := bh^.data ;

  {se busca por todo el bloque}
   for cont := 1 to (512 div sizeof(directory_entry)) do
    begin

    case dir^.nombre[1] of
    #0 : begin
         put_block (bh);
         goto _eof ;
         end;
    #$E5 : lgcount := 0 ;
    else
      begin
        if dir^.atributos = $0F then lgcount += 1
         else
           begin
            if dircount = fichero^.f_pos then goto _exit;
            dircount += 1;
            lgcount := 0 ;
           end;
      end;
    end;

    dir += 1;
    end;

  lgcount := 0 ;
  put_block (bh);
  next_sector := get_sector_fat (fichero^.inodo^.sb,next_sector);
  end;

  {no hay nada???}
  goto _eof ;


  {la lectura se realiza sobre el inodo root}
 _readdir_root :

 {la lectura es sobre el dir root}
 for rootsec := 19 to 32 do
  begin

  bh := get_block (fichero^.inodo^.mayor , fichero^.inodo^.menor ,rootsec,fichero^.inodo^.blksize);

  {error del hard}
  if bh = nil then
   begin
    set_errno := -EIO ;
    exit(0);
   end;

   dir := bh^.data ;

   {se busca por todo el bloque}
   for cont := 1 to (512 div sizeof(directory_entry)) do
    begin

     { se evalua la entrada }
     case dir^.nombre[1] of
     #0 : begin
           put_block (bh);
           goto _eof ;
          end;
     #$E5 : lgcount := 0;
     else
      begin

        { es una entrada de nombre largo ?? }
        if dir^.atributos = $0F then lgcount += 1
         else
          begin
           { estoy sobre el dir ?? }
           if dircount = fichero^.f_pos then goto _exit;
           dircount += 1;
           lgcount := 0 ;
          end;
      end;
    end;

    dir += 1;
  end;

  lgcount := 0 ;
  put_block (bh);
  end;

  {final de archivo}
  goto _eof ;

 {chauchas}
 _exit :

 preaddir := buffer ;
 preaddir^.name := '' ;


 if lgcount > 0 then
  begin

  { se traen todas las entradas de nombre largo }
  dir_long := pointer(dir) ;

  for cont := 0 to (lgcount-1) do
   begin
    dir_long -= 1 ;
    unicode_to_unix (dir_long,preaddir^.name);
   end;

 end else  unix_name(@dir^.nombre[1],preaddir^.name);

 preaddir^.ino := dir^.entradafat ;

 fichero^.f_pos += 1;

 put_block (bh);
 exit(1);

 {salida por final}
 _eof :
 set_errno := -EEOF ;
 preaddir := buffer ;
 preaddir^.name[1] := #0 ;
 exit(0);
 end;



{ * Fat_file_seek :                                                     *
  *                                                                     *
  * fichero : Puntero a un descriptor de archivo                        *
  * whence : Algoritmo usado                                            *
  * offset : nueva posicion sobre el archivo                            *
  * Retorno : nueva posicion del archivo                                *
  *                                                                     *
  * Realiza la posicionamiento sobre un archivo regular sobre fat       *
  *                                                                     *
  ***********************************************************************
}
function fat_file_seek (fichero : p_file_t ; whence , offset : dword ) : dword ;
begin

case whence of
seek_set : if (offset > fichero^.inodo^.size) then exit(0) else fichero^.f_pos  := offset ;
seek_cur : if (offset + fichero^.f_pos) > (fichero^.inodo^.size) then exit(0) else fichero^.f_pos += offset ;
seek_eof : fichero^.f_pos := fichero^.inodo^.size ;
else exit(0);
end;

exit(fichero^.f_pos);
end;




{ * Fat12fs_init :                                                      *
  *                                                                     *
  * Inicia las estructuras para el manejo de el driver de fat12         *
  *                                                                     *
  *                                                                     *
  ***********************************************************************
}
procedure fatfs_init ;
begin

fat_fstype.fs_id := 2 ;
fat_fstype.fs_flag := 0 ;
fat_fstype.read_super := @fat_read_super ;

fat_super_op.read_inode := @fat_read_inode ;
//fat_super_op.write_inode := @fat_write_inode;
//fat_super_op.delete_inode := @fat_delete_inode;
fat_super_op.put_inode := @fat_put_inode;
fat_super_op.write_super := nil ;

fat_inode_op.lookup := @fat_inode_lookup;

fat_inode_op.default_file_ops := @fat_file_op;
{fat_inode_op.mkdir := @fat_mkdir ;
fat_inode_op.create := @fat_file_create ;
fat_inode_op.truncate := @fat_file_truncate;
fat_inode_op.mknod := @fat_mknod;
fat_inode_op.rename := @fat_rename;
fat_inode_op.rmdir := @fat_rmdir ;
}
fat_file_op.read := @fat_read_file ;
fat_file_op.readdir := @fat_readdir ;
fat_file_op.open := nil ;
fat_file_op.seek := @fat_file_seek;
//fat_file_op.write := @fat_file_write;
fat_file_op.ioctl := nil ;

register_filesystem (@fat_fstype);

printkf('/Vvfs/n ... registrando /Vfat\n',[]);
end;



end.
