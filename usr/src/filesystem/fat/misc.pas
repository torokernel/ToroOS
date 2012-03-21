Unit misc ;

{ * Misc :                                                      *
  *                                                             *
  * Posee procedimientos y funciones para el tratamiento de ca  *
  * denas y sectores sobre fat                                  *
  *                                                             *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>  *
  * All Rights Reserved                                         *
  *                                                             *
  * Versiones :                                                 *
  *                                                             *
  * 10 / 10 / 2005 : Corregido bug en unix_name() y fat_name()  *
  *                                                             *
  * 28 / 07 / 2005 : Primera version                            *
  *                                                             *
  ***************************************************************
}

interface


{$I ../../include/toro/procesos.inc}
{$I ../../include/toro/buffer.inc}
{$I ../../include/toro/mount.inc}
{$I ../../include/head/buffer.h}
{$I ../../include/head/asm.h}
{$I ../../include/head/inodes.h}
{$I ../../include/head/dcache.h}
{$I ../../include/head/open.h}
{$I ../../include/head/procesos.h}
{$I ../../include/head/scheduler.h}
{$I ../../include/head/read_write.h}
{$I ../../include/head/devices.h}
{$I ../../include/head/printk_.h}
{$I ../../include/head/malloc.h}
{$I ../../include/toro/fat12fs/fat12.inc}
{$I ../../include/head/fat12fs/inodes.h}
{$I ../../include/head/fat12fs/super.h}


procedure unicode_to_unix ( longname : pvfatdirectory_entry ; var destino : string) ;
procedure unix_name ( fatname : pchar  ; var destino : string ) ;

implementation

{$I ../../include/head/string.h}
{$I ../../include/head/lock.h}

{ * realiza la busqueda de un sector dentro de la fat * }

function get_sector_fat (sb : p_super_block_t ; sector : dword) : word ;[public , alias :'GET_SECTOR_FAT'];
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



{ * put_sector_fat :                                                    *
  *                                                                     *
  * guarda un valor de                                                  *
  *                                                                     *
  ***********************************************************************
}
procedure put_sector_fat (sb : p_super_block_t ; sector : dword ; val : word ) ; [public , alias : 'PUT_SECTOR_FAT'];
var lfat : word ;
    lsb ,msb : byte ;
    offset : dword ;
    sb_fat : psb_fat ;
begin

sb_fat := sb^.driver_space ;

sector -= 31 ;

offset := (sector * 3) shr 1;

lsb := sb_fat^.pfat[offset] ;
msb := sb_fat^.pfat[offset+1];

lfat := ((msb shl 8) or lsb) ;

if (sector mod 2) <> 0  then
 begin
 val := (val shl 4) ;
 lfat := lfat and $f ;
 lfat := lfat or val  ;
 end
  else
   begin
   val := val and $0fff ;
   lfat := lfat and $f000;
   lfat := lfat or val ;
   end;

sb_fat^.pfat[offset] := lfat and $ff ;
sb_fat^.pfat[offset+1] := lfat shr 8 ;
end;


{ * realiza la busqueda dentro de la fat de clusters libres * }

function get_free_cluster( sb : p_super_block_t)  : word ;[public , alias :'GET_FREE_CLUSTER'];
var ret : dword ;
begin
for ret := 31 to (fat12_Maxsector + 31) do
 begin

 if (get_sector_fat (sb,ret) - 31) = 0 then
  begin
  put_sector_fat (sb,ret,last_sector);
  mark_fat_dirty (sb , ret);
  exit(ret);
  end;

end;
exit(0);
end;


{ * free_cluster : libera un cluster de un sb dado * }

procedure free_cluster ( sb : p_super_block_t ; cluster : dword) ;[public , alias : 'FREE_CLUSTER'];
begin
put_sector_fat (sb,cluster,0);
mark_fat_dirty (sb,cluster);
end;


{ * add_free_cluster :                                                   *
  *                                                                      *
  * Agrega un cluster a un archivo tanto directorio como archivo regular *
  *                                                                      *
  ************************************************************************
}
function add_free_cluster (ino : p_inode_t) : dword ;[public , alias : 'ADD_FREE_CLUSTER'];
var next_sector,end_sector ,free_cluster: dword ;
    tmp : pfat_inode_cache ;
    bh : p_buffer_head ;
begin

{entrada en cache de inodos-fat}
tmp := find_in_cache (ino^.ino,ino^.sb);

next_sector := tmp^.dir_entry^.entradafat + 31;

{voy al ultimo}
while next_sector <> last_sector do
 begin
  end_sector := next_sector ;
  next_sector := get_sector_fat (ino^.sb,next_sector);
 end;

{es solicitado el cache}
free_cluster := get_free_cluster (ino^.sb);

if free_cluster = 0 then exit(0);

{se sigue la cola ligada}
put_sector_fat(ino^.sb, end_sector,free_cluster);

{se marcara como sucia la fat}
mark_fat_dirty (ino^.sb,end_Sector);

bh := get_block (ino^.mayor,ino^.menor,free_cluster,ino^.blksize);

{aca no se verifica el bh = nil!!!}
{es llenado de 0 }
fillbyte (bh^.data,ino^.blksize,0);

mark_buffer_dirty (bh);

put_block (bh);

exit(free_cluster);
end;

{ * sencillo func. que rastrea un bloque de un dir en busca de un name * }

function find_dir ( bh : p_buffer_head ; name : pchar  ; var res : pdirectory_entry ) : dword ;[public , alias :'FIND_DIR'];
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

function find_rootdir ( bh : p_buffer_head ; name : pchar  ; var res : pdirectory_entry ) : dword ;[public , alias :'FIND_ROOTDIR'];
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




{ * fat_name : convierte un nombre en una entrada valida para la fat *
  *  , hay que modificar la llamada continua a strupper !!           *
}

function fat_name ( const name : string ; destino : pointer ) : dword ; [public , alias :'FAT_NAME'];
var ret ,cont:dword ;
    p : pchar ;
    pname : string ;
label _exit , _name_long ;
begin

p := destino  ;
pname := name  ;


for ret := 1 to (byte(pname[0])) do
 begin
  if (pname[ret] = '.')  then goto _exit
   else if pname[ret] = #32 then exit(-1);
  p[ret-1] := strupper (@pname[ret])^;
 end;


exit(0) ;

_exit :

ret += 1;
cont := 8 ;


{se deven poner los caracteres de extension}
   while (ret <= byte(pname[0])) and (cont <= 11) do
    begin
     if pname[ret] = #32 then exit(-1);

     p[cont] := strupper (@pname[ret])^;
     ret += 1;
     cont += 1;
    end;

   exit(0);

end;


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
begin

{ se lee la primera parte del nombre }
for count := 0 to 4 do
 if longname^.name1[(count*2)+1] = #0 then exit else destino += longname^.name1[(count*2)+1] ;

{ se lee la segunda parte del nombre }
for count := 0 to 5 do
  if longname^.name2[(count*2)+1] = #0 then exit else destino += longname^.name2[(count*2)+1] ;

{ se lee la tercera parte }
for count := 0 to 1 do
  if longname^.name3[(count*2)+1] = #0 then exit else destino += longname^.name3[(count*2)+1] ;

end;


{ * convierte un nombre de una entrada fat a una de toro * }

procedure unix_name ( fatname : pchar  ; var destino : string ) ; [public , alias : 'UNIX_NAME'];
var tmp : array[0..11] of char ;
    count ,ret: dword ;

label _ext , _exit ;
begin

fillbyte (@tmp,11,32);

for count := 0 to 7 do
 begin
  if fatname[count] = #32 then goto _ext ;
  tmp[count] := fatname[count];
 end;

 count += 1 ;

_ext :

 if fatname[8] = #32 then goto _exit;

 tmp[count] := '.' ;
 count += 1;

 for ret := 8 to 11 do
  begin

  if fatname[ret]= #32 then break
   else tmp[count] := fatname[ret];
   count += 1;
  end;

_exit :

 destino := tmp ;
 destino[0] := chr(count);

end;


{ * Add_direntry :                                                      *
  *                                                                     *
  * Agrega una entrada del tipo directory_entry a dir. root             *
  *                                                                     *
  ***********************************************************************
}
function add_rootentry (ino : p_inode_t ; entry : pdirectory_entry ) : dword ; [public , alias :'ADD_ROOTENTRY'];
var bh : p_buffer_head ;
    blk , count : dword ;
    tmp : pdirectory_entry ;

begin

 for blk := 19 to 32 do
  begin

    bh := get_block (ino^.mayor,ino^.menor,blk,ino^.blksize);

    if bh = nil then exit(-1);


    tmp := bh^.data ;

    {se busca una entrada libre}
    for count := 1 to (512 div sizeof (directory_entry)) do
     begin

      {entrada libre}
      if (tmp^.nombre[1] = #$E5) or (tmp^.nombre[1] = #0) then
         begin
          memcopy (entry,tmp,sizeof(directory_entry));
          mark_buffer_dirty (bh);
          put_block (bh);
          exit(0);
         end;

     tmp += 1;
     end;

   buffer_unlock (@bh^.wait_on_buffer);
   put_block (bh);
  end;

exit(-1);
end;



{ * Add_direntry :                                                      *
  *                                                                     *
  * Agrega una entrada del tipo directory_entry a un inodo directorio   *
  *                                                                     *
  ***********************************************************************
}
function add_direntry (ino : p_inode_t ; entry : pdirectory_entry ) : dword ;[public , alias :'ADD_DIRENTRY'];
var count ,last_cluster,free_clus:dword ;
    tmp : pfat_inode_cache ;
    bh : p_buffer_head;
    next_sector : dword ;
    pdir : pdirectory_entry ;

label _exit,_exit1;
begin

tmp := find_in_cache (ino^.ino , ino^.sb);

next_sector := tmp^.dir_entry^.entradafat + 31 ;


while (next_sector <> last_sector) do
 begin

  {es pedido el sector}
  bh := get_block (ino^.mayor,ino^.menor,next_sector,ino^.blksize);

  if bh = nil then exit(-1);


  pdir := bh^.data ;

  for count := 1 to (ino^.blksize div sizeof(directory_entry)) do
   begin
    if pdir^.nombre[1] = #$E5 then goto _exit
    else if pdir^.nombre[1] = #0 then goto _exit1 ;

   pdir += 1;
   end;

  buffer_unlock (@bh^.wait_on_buffer);
  put_block (bh);

  last_cluster := next_sector ;
  next_sector := get_sector_fat (ino^.sb,next_sector);
 end;

{devo agregar un bloque puesto que llegue al limite}
free_clus := get_free_cluster(ino^.sb);

if free_clus = 0 then exit(-1) ;

{nuevo sector en la cola ligada}
put_sector_fat (ino^.sb,last_cluster,free_clus);

bh := get_block (ino^.mayor,ino^.menor,free_clus,ino^.blksize);

if bh = nil then exit(-1);


pdir := bh^.data;
pdir^ := entry^;
pdir += 1;
pdir^.nombre[1] := #0;

mark_buffer_dirty (bh);

buffer_unlock (@bh^.wait_on_buffer);
put_block (bh);
exit(0);

_exit :
pdir^ := entry^;
mark_buffer_dirty (bh);
buffer_unlock (@bh^.wait_on_buffer);
put_block(bh);
exit(0);

_exit1 :
pdir^ := entry^ ;

{marco el final del directorio}
if count < 512 then
 begin
  pdir+= 1;
  pdir^.nombre[1] := #0;
  end;

mark_buffer_dirty (bh);
buffer_unlock (@bh^.wait_on_buffer);
put_block (bh);
exit(0);

end;


end.
