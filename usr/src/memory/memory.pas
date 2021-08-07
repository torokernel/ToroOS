
{ * MM:
  * Esta unidad se encarga de la administracion de memoria a traves de un *
  * modelo paginado , la asignacion de memoria al kernel se realiza a tra *
  * ves del kmalloc  , que limita el tama¤o a 4096 bytes , y la asignacio *
  * n para el usuario se realiza a traves de vmm_alloc                    *
  *                                                                       *
  *                                                                       *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>            *
  * All Rights Reserved                                                   *
  *                                                                       *
  * Versiones :                                                           *
  * 10 / 06 / 2004 : Se aplica el model paginado de memoria               *
  *                                                                       *
  * 29 / 10 / 2003 : Primera Version                                      *
  *************************************************************************
 }

Unit memory;

interface

uses arch, printk;

const
 {Comienzo del Area de Memoria Fisica}
 Mem_Ini=$300000;


 VMM_READ=1;
 VMM_WRITE=2;
 Brk_Limit = 16384 ;

{fin del area de paginas de dma}
dma_Memory = $10000;

{direcion logica del area de usuario}
High_Memory = $40000000;

Page_Size = 4096;

User_Mode = 4;
Write_Page = 2;
Present_Page = 1;

PG_Reserver=1;
PG_Null=0;

{maxima cantidad de paginas asignadas para descriptores por objeto}
Max_Malloc_Page_Desc=4;


 Type

 {Esto marca un area dentro del espacio mapeado de una tarea}
 p_vmm_area= ^vmm_area_struc;

 vmm_area_struc=record
 size:dword;
 add_l_comienzo:pointer;
 add_l_fin:pointer;
 flags:word;
 end;

{esta estructura se encuentra dentro de mem_map}
P_page=^T_page;

T_page=record
count:word;
flags:word;
end;


{pila de paginas libre}
p_page_free =^Page_Free;

Page_Free=record
next_page:p_page_free;
end;

Indice=record
Dir_I:word;
Page_I:word;
end;


{descriptor de memoria de malloc}
p_alloc_desc = ^Alloc_desc;

Alloc_desc = record
mem_alloc : pointer;
next_alloc : p_alloc_desc;
end;

{entrada de un directorio de objetos}
dir_alloc_entry=record
size:dword;
nr_page_desc:dword;
Free_list:p_alloc_desc;
Busy_list:p_alloc_desc;
Unassign_list:p_alloc_desc;
end;

var mm_totalmem , mm_memfree:dword;
    Kernel_PDT:pointer;
    nr_free_page:dword;

procedure MMInit;
function get_free_kpage:pointer;
procedure free_page(Add_f:pointer);
function get_free_page:pointer;
function get_phys_add(add_l,Pdt:pointer):pointer;
function get_page_index(Add_l:pointer):Indice;
function unload_page_table(add_l,add_dir:pointer):dword;
function dup_page_table(add_tp:pointer):dword;
function umapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;
function kmalloc(Size:dword):pointer;
function kfree_s(addr:pointer;size:dword):dword;
function get_dma_page : pointer ;
function sys_brk(Size:dword):pointer;cdecl;

implementation
uses process;

var mem_map:P_page;
    mem_map_size:dword;
    dma_Page_free:p_page_free;
    Low_Page_Free:p_Page_free;
    High_Page_Free:p_page_free;
    start_mem:pointer;
    start_page:dword;
    nr_page:dword;
    size_dir:array[1..9] of dir_alloc_entry;
    Mem_wait : wait_queue ;
    Mem_Alloc: dword;

{$I ../arch/macros.inc}

{ * Clear_Page :                                        *
  *                                                     *
  * Llena de 0 la pagina punteada en Add_f              *
  *                                                     *
  *******************************************************
  }
procedure clear_page(Add_f:pointer);inline;
begin
asm
mov edi , add_f
mov eax , 0
mov ecx ,1024
rep stosd
end;
end;

{ * Devuelve el indice de una dir logica * }
function get_page_index(Add_l:pointer):Indice;
var tmp:dword;
begin
tmp:=longint(Add_l);
Get_Page_Index.Dir_i:= tmp div (Page_Size * 1024);
Get_Page_Index.Page_i := (tmp mod (Page_Size * 1024)) div Page_Size;
end;

{ * quita un pagina dma de la pila * }

function dma_pop_free_page  : pointer ;
begin
If Dma_page_free = nil then exit(nil);
dma_pop_free_page := Dma_page_free ;
dma_page_free := Dma_Page_free^.next_page ;
end;

{ * Get_Dma_Page :                                                      *
  *                                                                     *
  * Retorno : puntero a una pagina dma                                  *
  *                                                                     *
  * Funcion q devuelve un pagina dma libre                              *
  *                                                                     *
  ***********************************************************************
}
function get_dma_page : pointer ;
var tmp : pointer;
begin

tmp := dma_pop_free_page ;

if tmp = nil then exit(nil);

mem_map[longint(tmp) shr 12].count:=1;
mem_map[longint(tmp) shr 12].flags:=PG_Null;
nr_free_page -= 1;
MM_MemFree -= Page_Size;

clear_page(tmp);
exit(tmp);
end;


{ * Kpop_Free_Page                                                      *
  *                                                                     *
  * Quita una pagina libre de la cola de paginas de la memoria baja     *
  *                                                                     *
  ***********************************************************************
}
function kpop_free_page:pointer;
begin
If Low_Page_Free=nil then exit(nil);
KPop_Free_Page := Low_Page_Free;
Low_Page_Free := Low_Page_Free^.next_page;
end;


{ * Get_Free_Kpage :                                                    *
  *                                                                     *
  * retorno : puntero a una pagina libre                                *
  *                                                                     *
  * Esta funcion no es igual a Get_Free_Page , puesto que devuelve una  *
  * pagina libre de la memoria baja  , utilizada por el kernel para las *
  * pilas 0 , sino el kernel utiliza Get_Free_Page                      *
  *                                                                     *
  ***********************************************************************
}
function get_free_kpage:pointer;
var tmp:pointer;
begin

tmp := KPop_Free_Page;

if tmp = nil then
 begin
  tmp := dma_pop_free_page ;
  if tmp = nil then exit(nil);
 end;

If tmp = nil then exit(nil);

{ Se aumenta el contador y se establece el tipo de pagina }

mem_map[longint(tmp) shr 12].count:=1;
mem_map[longint(tmp) shr 12].flags:=PG_Null;
nr_free_page -= 1;
MM_MemFree -= Page_Size;
clear_page(tmp);
exit(tmp);
end;

{ * Kmapmem :                                                           *
  *                                                                     *
  * add_f : Direccion fisica de la pagina a mapear                      *
  * add_l : Direccion logica donde sera mapeada                         *
  * add_dir : Puntero al PDT                                            *
  * Atributos : !!!                                                     *
  *                                                                     *
  * Esta funcion mapea dentro de un PDT dado una dir pagina en la dir   *
  * logica dada . En caso de no haber un PT la crea . Esta funcion solo *
  * es llamada por el kernel                                            *
  *                                                                     *
  ***********************************************************************
}
function kmapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;
var i:indice;
    dp,tp:^dword;
    tmp:pointer;
begin

{ Las direcciones deven estar alineadas con los 4 kb }
  If ((longint(add_f) and $FFF) =0) or ((longint(add_l) and $FFF)=0)  then
   else exit(-1);


{ Se calcula el indice dentro de la tabla de directorio y }
{ dentro de la tabla de paginas }
i := Get_Page_Index(add_l);
dp := add_dir;

{ Si el directorio no estubiese presente se crea uno }
If (dp[i.dir_i] and Present_Page) = 0    then
 begin
 tmp := get_free_kpage;

 If tmp=nil then exit(-1);
 dp[I.dir_i]:=longint(tmp) or Write_Page or Present_page;
end;

tp:=pointer(dp[I.dir_i] and $FFFFF000);

{ Si la pagina estubiese presente }
  If (tp[i.page_i] and Present_Page) = Present_Page then exit(-1);

tp[I.page_i]:=longint(add_f) or atributos ;

exit(0);
end;

{ * Coloca una pagina libre en la pila de paginas libres * }
procedure push_free_page(Dir_F:pointer);
var tmp:p_page_free;
begin
tmp:=Dir_f;

{Si pertenece a la memoria de kernel}
If Dir_F < pointer(High_Memory) then
 begin

 if (dir_f < pointer (dma_memory)) then
  begin
   tmp := dir_f ;
   tmp^.next_page := dma_page_free ;
   dma_page_free := tmp ;
  exit;
  end;

tmp := dir_f ;
tmp^.next_page := Low_Page_Free ;
Low_Page_Free := tmp ;

end
else    {Si pertenece a las paginas del usuario}
 begin

 tmp := dir_f ;
 tmp^.next_page := High_Page_Free ;
 High_Page_Free := tmp;
 end;

end;


{ * Init_Lista_Page_Free  :                                         *
  *                                                                 *
  * Inicializa la cola de paginas libres                            *
  *                                                                 *
  *******************************************************************
}
procedure init_lista_page_free;
var last_page:dword;
    ret:dword;
begin
last_page := (MM_TOTALMEM div Page_Size)-1;
for ret := start_page to last_page do push_free_page(pointer(ret * Page_Size));

for ret := 8 to $f do push_free_page (pointer(ret*page_size));
end;

{ * Free_Page :                                                         *
  *                                                                     *
  * Add_f : Dir fisica de la pagina                                     *
  *                                                                     *
  * Dada una pagina  , decrementa su uso y en caso de no tener usuarios *
  * la agrega a la cola de libres                                       *
  *                                                                     *
  ***********************************************************************
  }
procedure free_page(Add_f:pointer);
begin

If mem_map[longint(add_f) shr 12].count=0 then exit ;

mem_map[longint(add_f) shr 12].count -= 1;

If mem_map[longint(add_f) shr 12].count = 0 then
 begin
  Push_Free_Page(Add_f);
  MM_memfree += Page_Size ;
  nr_free_page += 1;
 end;

end;

{ * Pop_Free_Page :                                                *
  *                                                                *
  * Devuelve un puntero  a una pagina libre y la quita de la cola  *
  * .La pila es quitada de la cola de paginas libres de la memoria *
  * alta                                                           *
  *                                                                *
  ******************************************************************
}
function pop_free_page:pointer;
begin
If High_Page_Free=nil then exit(nil);
Pop_Free_Page := High_Page_Free;
High_Page_Free:=High_Page_Free^.next_page;
end;

{ * Get_Free_Page :                                                *
  *                                                                *
  * Devuelve un puntero a un pagina libre                          *
  * Utiliza la cola de paginas libres de la memoria alta , en caso *
  * de no haber utiliza las de la baja                             *
  *                                                                *
  ******************************************************************
  }
function get_free_page:pointer;
var tmp:pointer;
begin

{ Se trata de buscar una pagina de la zona alta }
tmp := Pop_Free_Page;

{ Si no toma de la baja }
If tmp=nil then
 begin
  tmp := kpop_free_page ;

  {por ultimo es tomada una pagina de la zona dma}
  if tmp = nil then tmp := dma_pop_free_page ;
  if tmp = nil then exit(nil);
 end;

{ Se aumenta el contador y se establece el tipo de pagina }

mem_map[longint(tmp) shr 12].count := 1;
mem_map[longint(tmp) shr 12].flags := PG_Null;

nr_free_page-=1;

MM_MemFree -= Page_Size;
clear_page(tmp);

exit(tmp);
end;


{ * Devuelve la dir. fisica de una dir logica segun el pdt * }
function get_phys_add(add_l,Pdt:pointer):pointer;
var i:indice;
    pd,pt:^dword;
begin
i:=Get_Page_Index(add_l);
pd:=Pdt;

{ Deve estar presente la dp }
If (pd[I.dir_i] and Present_Page ) = 0 then exit(nil);
pt:=pointer(longint(pd[I.dir_i]) and $FFFFF000);

{ Deve estar presente la tp }
If (pt[I.page_i] and Present_Page) = 0 then exit(nil);
exit(pointer(longint(pt[I.page_i]) and $FFFFF000));
end;

{ * Unload_Page_Table :                                                   *
  *                                                                       *
  * add_l : Direccion logica de la tabla                                  *
  * add_dir : Puntero al PDT                                              *
  *                                                                       *
  * Esta funcion a diferencia de kunmapmem , si libera todas las paginas  *
  * pertenecientes a una TP  , la TP y la quita del PDT                   *
  *                                                                       *
  *************************************************************************
}

function unload_page_table(add_l,add_dir:pointer):dword;
var i:indice;
    dp,tp:^dword;
    ret:dword;
    pg:pointer;
begin
i:=Get_Page_index(add_l);
dp:=add_dir;

{ Si el directorio no estubiese presente }
If (dp[i.dir_i] and Present_Page) = 0 then exit(-1);

tp:=pointer(dp[i.dir_i] and $FFFFF000);
{ Punteo al comienzo de la tabla de paginas }

{ Se busca en toda la tabla las paginas activas }
for ret:= 1 to (Page_Size div 4)  do
 begin
 pg:=pointer(tp[ret] and $FFFFF000);

 If (tp[ret] and Present_Page) = 0 then   { No deve tener el bit P bajo }
  else
   { La pagina deve estar alineada a los 4 kb }
    If (longint(pg) and $FFF) = 0 then free_page(pg)
    else Panic('Unload_Page_Table : Se quita una pagina no alineada');
end;

{ Se libera la PT }
free_page(pointer(dp[I.dir_i] and $FFFFF000));

{ Se borra la entrada en el PDT }
dp[I.dir_i]:=0;
end;


{ * Dup_Page_Table :                                                    *
  *                                                                     *
  * add_tp : puntero a la tabla de paginas                              *
  *                                                                     *
  * Esta funcion duplica una tp aumentando el contador de las paginas   *
  * que a las que apunta                                                *
  *                                                                     *
  ***********************************************************************
  }

function dup_page_table(add_tp:pointer):dword;[public , alias :'DUP_PAGE_TABLE'];
var tmp:dword;
    pg:^dword;
    p:pointer;
begin

pg:=add_tp;

for tmp:= 1 to (Page_Size div 4) do
 begin
 p:=pointer(pg[tmp] and $FFFFF000);

 { La pagina deve estar presente }
 If (pg[tmp] and Present_Page ) = 0  then
  else

   { La pagina deve estar alineada a los 4 kb }
   If (longint(p) and $FFF ) = 0 then mem_map[longint(p) shr 12].count += 1;
 end;
exit(0);
end;


{ * Umapmem :                                                              *
  *                                                                        *
  * add_f : Direccion fisica de la pagina                                  *
  * add_l : Direccion logica donde sera mapeada                            *
  * add_dir : PDT                                                          *
  * atributos : Atributos de la pagina                                     *
  *                                                                        *
  * Esta funcion mapea una direccion logica dentro de un PDT dado a difere *
  * ncia de kmapmem , utiliza las paginas de la memoria alta .             *
  * Aclaracion : Trabaja sobre Kernel_Pdt                                  *
  *
  **************************************************************************
}
function umapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;
var i:indice;
    dp,tp:^dword;
    tmp:pointer;
begin

{ Las direcciones deven estar alineadas con los 4 kb }
  If ((longint(add_f) and $FFF) =0) or ((longint(add_l) and $FFF)=0)  then
   else exit(-1);


{ Se calcula el indice dentro de la tabla de directorio y }
{ dentro de la tabla de paginas }
i:=Get_Page_Index(add_l);
dp:=add_dir;

{ Si el directorio no estubiese presente se crea uno }
If (dp[i.dir_i] and Present_Page) = 0    then
 begin

 tmp:=get_free_page;

 If tmp=nil then exit(-1);
 dp[I.dir_i]:= Longint(tmp)  or User_Mode or Write_Page or Present_page;

end;

tp:=pointer(dp[I.dir_i] and $FFFFF000);

{ Si la pagina estubiese presente }
  If (tp[i.page_i] and Present_Page) = Present_Page then exit(-1);

tp[I.page_i]:=longint(add_f) or atributos;

exit(0);
end;

procedure clean_free_list(i:dword;add_p:pointer);forward;

{ * Esta funcion declarada como inline para q sea mas rapida coloca en una *
  * ligada simple un puntero a un bloque de memoria                        *
}

procedure push_desc(var Cola,Desc:p_alloc_desc);inline;
begin
Desc^.next_alloc := Cola;
Cola := Desc;
end;


{ * Y esta funcion lo quita * }

function pop_desc(var Cola:p_alloc_desc):p_alloc_desc;inline;
begin
Pop_Desc:=Cola;
Cola:=Cola^.next_alloc;
end;


{ * Init_Unassign_List :                                                *
  *                                                                     *
  * I : Indice dentro de size_dir                                       *
  * ret :  0 si la operacion fue correcto o -1 de los contrario         *
  *                                                                     *
  * Esta funcion toma una pagina del kernel y crea sobre ella la lista  *
  * ligada de descriptores de huecos  . Puede ser llamada solo dos veces*
  * por entrada en size_dir . Y agrega cada nuevo descriptor a la cola  *
  * unassign_list , que seran utilizados por Init_free_list             *
  *                                                                     *
  ***********************************************************************
}
function init_unassign_list(I:word):dword;
var pdesc:p_alloc_desc;
    tmp:dword;
begin

{ Cada grupo de objetos posee este limite de descp }
If size_dir[i].nr_page_desc = MAX_MALLOC_PAGE_DESC then exit(-1);

pdesc := get_free_kpage;

If pdesc=nil then exit(-1);

size_dir[i].nr_page_desc += 1;

{ Son cargados 1024 descriptores de bloques por tipo de }
{ objeto cada vez que es llamada esta funcion           }

for tmp:= 1 to (Page_Size div sizeof(Alloc_desc)) do
 begin
 pdesc^.mem_alloc:=nil;
 Push_Desc(size_dir[I].Unassign_List,pdesc);
 pdesc+=1;
end;

exit(0);
end;




{ * Init_Free_List :                                                    *
  *                                                                     *
  * I : Indice dentro de size_dir                                       *
  * ret :  0 si fue correcta y -1 si no                                 *
  *                                                                     *
  * Esta iniciaa la cola de huecos libres . Toma una pagina del kernel  *
  * toma descriptores no asignados   y llena el campo mem_alloc , con   *
  * los huecos pertenecientes dentro de la nueva pagina                 *
  *                                                                     *
  ***********************************************************************
}
function init_free_list(I:dword):dword;
var tmp:dword;
    pg:pointer;
    pdesc:p_alloc_desc;
begin

{ Si no hay descriptores libres , son creados nuevos }
If size_dir[i].Unassign_List=nil then
 If Init_Unassign_List(I) <> 0 then exit(-1);

{ Pido un pagina donde estaran los huecos del tamano dado }
pg := get_free_kpage;

If pg=nil then exit(-1);

Mem_Alloc += Page_Size;

for tmp:= 0 to ((Page_Size div size_dir[i].size)-1) do
 begin

 { Quito un descriptor no asignado }
 pdesc := Pop_Desc(size_dir[i].Unassign_List);
 pdesc^.mem_alloc:=pg + (tmp * size_dir[i].size);

 { Meto el desc. en la cola de huecos libres }
 Push_Desc(size_dir[i].Free_List,pdesc);
end;

exit(0);
end;



procedure del_desc(Var Cola,Desc:p_alloc_desc);
var tmp:p_alloc_desc;
begin
tmp:=Cola;
If tmp=nil then exit;

If Cola=Desc then
 begin
 Cola:=Desc^.next_alloc;
 exit;
end;

repeat
If tmp^.next_alloc=Desc then
 begin
 tmp^.next_alloc:=Desc^.next_alloc;
 exit;
 end;
until (tmp=nil)
end;



function remove_desc(Var Cola:p_alloc_desc;Add_b:pointer):p_alloc_desc;
var tmp,ant:p_Alloc_desc;
begin

{ La cola puede estar vacia }
If Cola=nil then exit(nil);

{ Si fuera el primero de las lista }
If Cola^.mem_alloc=add_b then
 begin
 Remove_Desc:=Cola;
 Cola:=Cola^.next_alloc;
 exit;
end;

{ Si no se rastrea la lista hasta encontrar el elemento }
{ o hasta el final de la cola }
tmp:=Cola^.next_alloc;
ant:=Cola;

while (tmp <> nil) do
 begin
 if (tmp^.mem_alloc=Add_b )  then
  begin
  ant^.next_alloc:=tmp^.next_alloc;
  break;
 end;
tmp:=tmp^.next_alloc;
ant:=ant^.next_alloc;
end;

If tmp=nil then exit(tmp) else exit(tmp);
end;




{ * Kmalloc :                                                          *
  *                                                                    *
  * Size : Tamano necesario menor que 4096                             *
  * ret : puntero al hueco                                             *
  *                                                                    *
  * Esta funcion , una de las mas importantes de la memoria , busca    *
  * un hueco mayor o igual al pedido  y devuelve su puntero            *
  **********************************************************************
}
function kmalloc(Size:dword):pointer;
var i:dword;
    descp:p_alloc_desc;
    tmp:pointer;

    begin

{ Los huecos no pueden ser mayores que 4096 por ahora }
If size > Page_Size then
 begin
 {$IFDEF DEBUG}
  printk('/nKmalloc : Se pide mas de 4096 bytes !!!!\n',[],[]);
 {$ENDIF}
 exit(nil);
end;

{ Busco la lista de huecos inmediatamente igual o mayor }
i:=0;
repeat
i+=1;
until (size_dir[i].size >= Size);

{ Esto no hace falta explicarlo }
If size_dir[i].Free_list = nil then
 If Init_Free_List(i) <> 0 then exit(nil);

Mem_Alloc-=size_dir[i].size;
descp:=Pop_Desc(size_dir[i].Free_List);

{ Es metido dentro de la cola de ocupados }
Push_Desc(Size_dir[i].busy_list,descp);

{ Salgo con el puntero al hueco del tamano pedido }
{$IFDEF DEBUG}
 printk('/nKmalloc : Hueco /V %d \n',[longint(descp^.mem_alloc)],[]);
{$ENDIF}

{ La pagina incrementa su uso }
tmp:=pointer(longint(descp^.mem_alloc) and $FFFFF000);
mem_map[longint(tmp) shr 12].count+=1;

exit(descp^.mem_alloc);

end;

{ * Kfree_S :                                                           *
  *                                                                     *
  * addr : puntero al hueco                                             *
  * size : tamano del hueco                                             *
  * ret : 0 si fue correcta y -1 si no                                  *
  *                                                                     *
  * Esta funcion libera una hueco dado de la cola de ocupados y el      *
  * hueco retorna a la lista de libres                                  *
  *                                                                     *
  ***********************************************************************
}
function kfree_s(addr:pointer;size:dword):dword;
var i:dword;
    descp:p_alloc_desc;
    tmp:pointer;
begin

If size > Page_Size then
 begin
 {$IFDEF DEBUG}
  printk('/nKfree_S : Size mayor que 4096 bytes!!!\n',[],[]);
 {$ENDIF}
 exit(-1);
end;

i:=0;
repeat
i+=1;
until (size_dir[i].size >= size);

{ Quito el descriptor de la cola ocupado }
descp:=Remove_Desc(size_dir[i].busy_list,addr);

If descp = nil then exit(-1);

descp^.next_alloc:=nil;

{ El uso de la pagina se decrementa }
tmp:=pointer(longint(descp^.mem_alloc) and $FFFFF000);
mem_map[longint(tmp) shr 12].count-=1;

{ Si solo la utiliza la lista de libres }
{ podra ser liberada }

if mem_map[longint(tmp) shr 12].count=1 then
 begin
 Push_Desc(size_dir[i].unassign_list,descp);

 { Antes devo mover todos los desc.que usan la pagina a la lista unassign }
 Clean_Free_List(i,tmp);

 { Libero la pagina }
 free_page(tmp);

 end
else  Push_Desc(size_dir[i].free_list,descp);

Mem_Alloc+=size_dir[i].size;
{$IFDEF DEBUG}
 printk('/nKfree_S : Hueco /V %d liberado\n',[longint(addr)],[]);
{$ENDIF}
exit(0);
end;

{ * Clean_Free_List :                                                   *
  *                                                                     *
  * I: Indice dentro size_dir                                           *
  * add_p : Pagina que sera removida                                    *
  *                                                                     *
  * Esta funcion toma todos los descriptores que apuntan a una misma    *
  * pagina y los pasa a la cola de sin asignar , para luego liberar la  *
  * pagina . Utilizado por k_free                                       *
  *                                                                     *
  ***********************************************************************

}
procedure clean_free_list(i:dword;add_p:pointer);
var tmp,l:p_alloc_desc;
begin
tmp:=size_dir[i].free_list;
if tmp=nil then exit;

while (tmp <> nil) do
 begin
 { Este descriptor pertenece a la pagina buscada }
If pointer(longint(tmp^.mem_alloc) And $FFFFF000)=add_p then
 begin

 { Se quita el desc. de la cola de libres }
 Del_Desc(size_dir[i].free_list,tmp);
 tmp^.mem_alloc:=nil;
 l:=tmp^.next_alloc;

 { Se mete en la cola de no asignados }
 Push_Desc(size_dir[i].unassign_list,tmp);
 tmp:=l;
 end
else tmp:=tmp^.next_alloc;

end;
end;

{$DEFINE mem_lock := lock (@mem_wait) ; }
{$DEFINE mem_unlock := unlock (@mem_wait) ;}


{ * Sys_Brk :                                                            *
  *                                                                      *
  * Size : Tamano en que aumentara el segmento de datos                  *
  *                                                                      *
  * Esta funcion aumenta de acuerdo size el tamano del segmento de datos *
  * que es el area vmm text_area . Se mantienen las especificaciones de  *
  * de la llamadas al sistema brk() de Unix , en que el deve haber un    *
  * espacio de 16kb entre STACK_AREA y el fin de text_area               *
  *                                                                      *
  * Modificaciones :                                                     *
  * 01 / 09 / 2004 : Version Inicial                                     *
  ************************************************************************
}
function sys_brk(Size:dword):pointer;cdecl;
var dif:dword;
    nrpage,err:dword;
    oldpos:pointer;
begin

Save_Cr3 ;
Load_Kernel_Pdt;

nrpage := Size div Page_Size ;

if (Size mod Page_Size ) = 0 then else nrpage+=1;

dif := longint(Tarea_Actual^.text_area.add_l_fin) + (nrpage * Page_Size);
dif := longint(Tarea_Actual^.stack_area.add_l_comienzo) - dif;
If (dif <= Brk_Limit) then exit(nil);
oldpos := Tarea_Actual^.text_area.add_l_fin;

{Se protege el recurso memoria}
Mem_Lock;

If vmm_alloc(Tarea_Actual,@Tarea_Actual^.text_area,size)=0 then printkf('/nSys_Brk : Ok\n',[])
else
 begin
 Mem_Unlock;
 exit(nil);
 end;

Mem_Unlock;

Restore_Cr3 ;

Exit(oldpos);
end;



{ * Proceso que inicializa la paginacion atraves de la MMU * }
procedure paging_start;
var tmp:pointer;
    ret:dword;
begin

{ Se mapea toda la memoria dentro del dir del kernel para que este }
{ la vea en el mismo espacio logico }

Kernel_PDT := get_free_kpage;

tmp:=nil;

for ret:= 0 to ((MM_TOTALMEM div Page_Size) -1) do
 begin
 tmp:=pointer(Page_Size * ret);
 kmapmem(tmp,tmp,kernel_PDT,Present_Page or Write_Page);
end;

asm
mov eax , Kernel_Pdt
mov cr3 , eax
mov eax , cr0
or eax , $80000000
mov cr0 , eax
end;

printkf('Kernel PDT: /V%d/n\n', [DWORD(Kernel_Pdt)]);
end;

procedure paging_init;
var  ret,size:dword;
     l,k:pointer;
begin

{ Se calcula el numero de paginas  y el tamano de mem_map }
nr_page:=(MM_MemFree div Page_Size);
mem_map_size:=nr_page * sizeof(T_page);
nr_page-=(mem_map_size div Page_Size);
nr_free_page:=nr_page;
start_page:=(MeM_Ini + mem_map_size) div Page_Size;
start_mem:=pointer(start_page * Page_Size);
Low_Page_Free:=nil;
High_Page_Free:=nil;
mem_map:= pointer (Mem_Ini) ;

{ Se inicializa la lista de paginas libres }
Init_Lista_Page_Free;

printkf('Number of available pages: /V%d/n\n',[nr_page]);
printkf('First Page: /V%d/n\n',[start_page]);
printkf('Pages in Mem_Map: /V%d/n\n',[mem_map_size div Page_Size]);

{ Se inicializa a la MMU }
paging_start;

{ Se iniciliza el directorio de Malloc }
printkf('Initializing malloc ... ',[]);
size:=16;
for ret:= 1 to 9 do
 begin
 size_dir[ret].size:=size;
 size_dir[ret].nr_page_desc:=0;
 size_dir[ret].free_list:=nil;
 size_dir[ret].busy_list:=nil;
 size_dir[ret].Unassign_list:=nil;
 size:=size * 2;
end;
printkf('/VOk/n\n',[]);

mem_wait.lock_wait := nil ;
end;

// TODO: This procedure should be replace
procedure mm_total_fisica ;
begin
asm
mov esi , MEM_INI
@mem:
 add esi , $100000
 mov dword [esi] , $1234567
 cmp dword [esi] , $1234567
 je @mem
 mov MM_TOTALMEM , esi
end;
end;

{ * Proceso que inicializa el modulo de memoria * }
procedure MMInit;
begin
mm_total_fisica;
mm_memfree := mm_totalmem - mem_ini;
printkf('Total Physical Memory ... /V%d/n\n',[MM_TotalMem]);
printkf('Free Physical Memory  ... /V%d/n\n',[MM_MEMFREE]);
Paging_Init;
end;

end.
