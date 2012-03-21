Unit Paging;

{ * Paging :                                                             *
  *                                                                      *
  * Esta unidad se encarga de administrar la  memoria paginada .Las      *
  * paginas se encuentran en dos listas una en mm_map , en que se guarda *
  * info sobre el estado de la pagina  y la cola de libres , que liga a  *
  * las paginas libre                                                    *
  *                                                                      *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>           *
  * All Rights Reserved                                                  *
  *                                                                      *
  * Versiones :                                                          *
  * 10 / 06 / 2004 : Primera Version                                     *
  *                                                                      *
  ************************************************************************

}


interface
{DEFINE DEBUG}

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/mm.h}
{$I ../Include/Head/printk_.h}



function kmapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;external name 'KMAPMEM';
function kmalloc(Size:dword):pointer;external name 'KMALLOC';
function kfree_s(addr:pointer;size:dword):dword;external name 'KFREE_S';

var mem_map:P_page;
    mem_map_size:dword;
    dma_Page_free:p_page_free;
    Low_Page_Free:p_Page_free;
    High_Page_Free:p_page_free;
    start_mem:pointer;
    start_page:dword;
    nr_page:dword;
    nr_free_page:dword;
    Kernel_PDT:pointer;
    size_dir:array[1..9] of dir_alloc_entry;external name 'U_MALLOC_SIZE_DIR';
    Mem_wait : wait_queue ;

implementation


{$I ../Include/Head/list.h}

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

function get_page_index(Add_l:pointer):Indice;[public , alias :'GET_PAGE_INDEX'];
var tmp:dword;
begin
tmp:=longint(Add_l);
Get_Page_Index.Dir_i:= tmp div (Page_Size * 1024);
Get_Page_Index.Page_i := (tmp mod (Page_Size * 1024)) div Page_Size;
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


{ * quita un pagina dma de la pila * }

function dma_pop_free_page  : pointer ;
begin
If Dma_page_free = nil then exit(nil);

dma_pop_free_page := Dma_page_free ;

dma_page_free := Dma_Page_free^.next_page ;
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


{ * Get_Free_Page :                                                *
  *                                                                *
  * Devuelve un puntero a un pagina libre                          *
  * Utiliza la cola de paginas libres de la memoria alta , en caso *
  * de no haber utiliza las de la baja                             *
  *                                                                *
  ******************************************************************
  }
function get_free_page:pointer;[public, alias : 'GET_FREE_PAGE'];
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
function get_free_kpage:pointer;[public , alias :'GET_FREE_KPAGE'];
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




{ * Get_Dma_Page :                                                      *
  *                                                                     *
  * Retorno : puntero a una pagina dma                                  *
  *                                                                     *
  * Funcion q devuelve un pagina dma libre                              *
  *                                                                     *
  ***********************************************************************
}
function get_dma_page : pointer ;[public , alias : 'GET_DMA_PAGE'];
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




{ * Free_Page :                                                         *
  *                                                                     *
  * Add_f : Dir fisica de la pagina                                     *
  *                                                                     *
  * Dada una pagina  , decrementa su uso y en caso de no tener usuarios *
  * la agrega a la cola de libres                                       *
  *                                                                     *
  ***********************************************************************
  }
procedure free_page(Add_f:pointer);[public, alias : 'FREE_PAGE'];
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





{ * Esta funcion coloca los atributos a una pagina * }

function set_page_rights(add_l,add_dir:pointer;atributos:word):dword;[public ,alias :'SET_PAGE_RIGHTS'];
var i:indice;
    dp,tp:^dword;
begin

i := Get_Page_Index(add_l);
dp := add_dir;

If (dp[i.dir_i] and Present_Page ) = 0 then exit(-1);

tp:=pointer(dp[I.dir_i] and $FFFFF000);

If (tp[i.page_i] and Present_Page ) = 0 then exit(-1);

atributos:=atributos and $FFF;
tp[i.page_i]:=tp[i.page_i] or atributos;
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

function unload_page_table(add_l,add_dir:pointer):dword;[public , alias :'UNLOAD_PAGE_TABLE'];
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





{ * Devuelve la dir. fisica de una dir logica segun el pdt * }

function get_phys_add(add_l,Pdt:pointer):pointer;[public , alias :'GET_PHYS_ADD'];
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


{ * Reserve_Page :                                                      *
  *                                                                     *
  * add_f : Direcion fisica de la pagina                                *
  * Retorno : 0  si ok i -1 si falla                                    *
  *                                                                     *
  * Funcion que reserva un pagina quitandola de la pila de disponibles  *
  * utilizada mas q nada para dispositivos hard que realizan io a traves*
  * de memoria mapeada                                                  *
  *                                                                     *
  ***********************************************************************
}
function reserve_page (add_f:pointer):dword;[public , alias : 'RESERVE_PAGE'];
var npage,ppage : p_page_free ;
begin

{la pagina se encuentra actualmente en uso}
If mem_map[longint(add_f) shr 12].count = 1 then exit(-1) ;

npage := Low_Page_Free ;
ppage := Low_Page_Free ;

{se recorre la cola de paginas bajas}
while (npage <> nil ) do
 begin

  {se encontro la pagina}
  if (npage = add_f)  then
   begin
    if (npage = Low_Page_Free) then Low_Page_Free := npage^.next_page
    else if (npage^.next_page = nil) then ppage^.next_page := nil
    else ppage^.next_page := npage^.next_page ;

    mem_map[longint(add_f) shr 12].flags := Pg_Reserver ;

    {operacion correcta!!!}
    exit(0);
   end;

  ppage := npage ;
  npage := npage^.next_page ;
 end;


npage := High_Page_Free ;
ppage := High_Page_Free ;

{se recorre la cola de paginas altas o de usuarios}
while (npage <> nil ) do
 begin

  {se encontro la pagina}
  if (npage = add_f)  then
   begin
    if (npage = Low_Page_Free) then Low_Page_Free := npage^.next_page
    else if (npage^.next_page = nil) then ppage^.next_page := nil
    else ppage^.next_page := npage^.next_page ;

   exit(0);
   end;

  ppage := npage ;
  npage := npage^.next_page ;
 end;

{algo anda mal no se encontrol pagina !!! se encuentra debajo de memini}
exit(-1);
end;




{ * Free_Reserve_Page :                                                 *
  *                                                                     *
  * addf : direcion fisica de la pagina                                 *
  *                                                                     *
  * Devuelve una pagina reservada                                       *
  *                                                                     *
  ***********************************************************************
}
function free_reserve_page (add_f : pointer ) : dword;[public , alias : 'FREE_RESERVE_PAGE'];
begin
push_free_page (add_f);
mem_map[longint(add_f) shr 12].count := 0 ;
mem_map[longint(add_f) shr 12].count := Pg_Null;
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

end;




{ * Proceso que inicializa todo el sistema de paginacion como malloc , etc * }

procedure paging_init;[public, alias :'PAGING_INIT'];
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

printk('/nCantidad de Paginas : /V%d \n',[nr_page],[]);
printk('/nPrimer Pagina       : /V%d \n',[start_page],[]);
printk('/nPaginas en Mem_Map  : /V%d \n',[mem_map_size div Page_Size],[]);

{ Se inicializa a la MMU }
paging_start;

{ Se iniciliza el directorio de Malloc }
printk('/nIniciando malloc ... ',[],[]);
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
printk('/VOk\n',[],[]);

mem_wait.lock_wait := nil ;
end;





end.
