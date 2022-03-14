//
// memory.pas
//
// This unit contains the functions to allocate memory.
// 
// Copyright (c) 2003-2022 Matias Vara <matiasevara@gmail.com>
// All Rights Reserved
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

Unit memory;

interface

uses arch, printk;

const
 Mem_Ini=$300000;


 VMM_READ=1;
 VMM_WRITE=2;
 Brk_Limit = 16384 ;

dma_Memory = $10000;

High_Memory = $40000000;

Page_Size = 4096;

User_Mode = 4;
Write_Page = 2;
Present_Page = 1;

PG_Reserver=1;
PG_Null=0;

Max_Malloc_Page_Desc=4;


 Type

 p_vmm_area= ^vmm_area_struc;

 vmm_area_struc=record
 size:dword;
 add_l_comienzo:pointer;
 add_l_fin:pointer;
 flags:word;
 end;

P_page=^T_page;

T_page=record
count:word;
flags:word;
end;


p_page_free =^Page_Free;

Page_Free=record
next_page:p_page_free;
end;

Indice=record
Dir_I:word;
Page_I:word;
end;


p_alloc_desc = ^Alloc_desc;

Alloc_desc = record
mem_alloc : pointer;
next_alloc : p_alloc_desc;
end;

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

procedure clear_page(Add_f:pointer);inline;
begin
asm
mov edi , add_f
mov eax , 0
mov ecx ,1024
rep stosd
end;
end;

function get_page_index(Add_l:pointer):Indice;
var tmp:dword;
begin
tmp:=longint(Add_l);
Get_Page_Index.Dir_i:= tmp div (Page_Size * 1024);
Get_Page_Index.Page_i := (tmp mod (Page_Size * 1024)) div Page_Size;
end;

function dma_pop_free_page  : pointer ;
begin
If Dma_page_free = nil then exit(nil);
dma_pop_free_page := Dma_page_free ;
dma_page_free := Dma_Page_free^.next_page ;
end;

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

function kpop_free_page:pointer;
begin
If Low_Page_Free=nil then exit(nil);
KPop_Free_Page := Low_Page_Free;
Low_Page_Free := Low_Page_Free^.next_page;
end;

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

mem_map[longint(tmp) shr 12].count:=1;
mem_map[longint(tmp) shr 12].flags:=PG_Null;
nr_free_page -= 1;
MM_MemFree -= Page_Size;
clear_page(tmp);
exit(tmp);
end;

function kmapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;
var i:indice;
    dp,tp:^dword;
    tmp:pointer;
begin

  If ((longint(add_f) and $FFF) =0) or ((longint(add_l) and $FFF)=0)  then
   else exit(-1);

i := Get_Page_Index(add_l);
dp := add_dir;

If (dp[i.dir_i] and Present_Page) = 0    then
 begin
 tmp := get_free_kpage;

 If tmp=nil then exit(-1);
 dp[I.dir_i]:=longint(tmp) or Write_Page or Present_page;
end;

tp:=pointer(dp[I.dir_i] and $FFFFF000);

  If (tp[i.page_i] and Present_Page) = Present_Page then exit(-1);

tp[I.page_i]:=longint(add_f) or atributos ;

exit(0);
end;

procedure push_free_page(Dir_F:pointer);
var tmp:p_page_free;
begin
tmp:=Dir_f;

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
else
 begin

 tmp := dir_f ;
 tmp^.next_page := High_Page_Free ;
 High_Page_Free := tmp;
 end;

end;

procedure init_lista_page_free;
var last_page:dword;
    ret:dword;
begin
last_page := (MM_TOTALMEM div Page_Size)-1;
for ret := start_page to last_page do push_free_page(pointer(ret * Page_Size));

for ret := 8 to $f do push_free_page (pointer(ret*page_size));
end;

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

function pop_free_page:pointer;
begin
If High_Page_Free=nil then exit(nil);
Pop_Free_Page := High_Page_Free;
High_Page_Free:=High_Page_Free^.next_page;
end;

function get_free_page:pointer;
var tmp:pointer;
begin

tmp := Pop_Free_Page;

If tmp=nil then
 begin
  tmp := kpop_free_page ;

  if tmp = nil then tmp := dma_pop_free_page ;
  if tmp = nil then exit(nil);
 end;

mem_map[longint(tmp) shr 12].count := 1;
mem_map[longint(tmp) shr 12].flags := PG_Null;

nr_free_page-=1;

MM_MemFree -= Page_Size;
clear_page(tmp);

exit(tmp);
end;

function get_phys_add(add_l,Pdt:pointer):pointer;
var i:indice;
    pd,pt:^dword;
begin
i:=Get_Page_Index(add_l);
pd:=Pdt;

If (pd[I.dir_i] and Present_Page ) = 0 then exit(nil);
pt:=pointer(longint(pd[I.dir_i]) and $FFFFF000);

If (pt[I.page_i] and Present_Page) = 0 then exit(nil);
exit(pointer(longint(pt[I.page_i]) and $FFFFF000));
end;

function unload_page_table(add_l,add_dir:pointer):dword;
var i:indice;
    dp,tp:^dword;
    ret:dword;
    pg:pointer;
begin
i:=Get_Page_index(add_l);
dp:=add_dir;

If (dp[i.dir_i] and Present_Page) = 0 then exit(-1);

tp:=pointer(dp[i.dir_i] and $FFFFF000);

for ret:= 1 to (Page_Size div 4)  do
 begin
 pg:=pointer(tp[ret] and $FFFFF000);

 If (tp[ret] and Present_Page) = 0 then
  else
    If (longint(pg) and $FFF) = 0 then free_page(pg)
    else Panic('Unload_Page_Table : Se quita una pagina no alineada');
end;

free_page(pointer(dp[I.dir_i] and $FFFFF000));

dp[I.dir_i]:=0;
end;

function dup_page_table(add_tp:pointer):dword;[public , alias :'DUP_PAGE_TABLE'];
var tmp:dword;
    pg:^dword;
    p:pointer;
begin

pg:=add_tp;

for tmp:= 1 to (Page_Size div 4) do
 begin
 p:=pointer(pg[tmp] and $FFFFF000);

 If (pg[tmp] and Present_Page ) = 0  then
  else

   If (longint(p) and $FFF ) = 0 then mem_map[longint(p) shr 12].count += 1;
 end;
exit(0);
end;

function umapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;
var i:indice;
    dp,tp:^dword;
    tmp:pointer;
begin

  If ((longint(add_f) and $FFF) =0) or ((longint(add_l) and $FFF)=0)  then
   else exit(-1);


i:=Get_Page_Index(add_l);
dp:=add_dir;

If (dp[i.dir_i] and Present_Page) = 0    then
 begin

 tmp:=get_free_page;

 If tmp=nil then exit(-1);
 dp[I.dir_i]:= Longint(tmp)  or User_Mode or Write_Page or Present_page;

end;

tp:=pointer(dp[I.dir_i] and $FFFFF000);

  If (tp[i.page_i] and Present_Page) = Present_Page then exit(-1);

tp[I.page_i]:=longint(add_f) or atributos;

exit(0);
end;

procedure clean_free_list(i:dword;add_p:pointer);forward;

procedure push_desc(var Cola,Desc:p_alloc_desc);inline;
begin
Desc^.next_alloc := Cola;
Cola := Desc;
end;

function pop_desc(var Cola:p_alloc_desc):p_alloc_desc;inline;
begin
Pop_Desc:=Cola;
Cola:=Cola^.next_alloc;
end;

function init_unassign_list(I:word):dword;
var pdesc:p_alloc_desc;
    tmp:dword;
begin

If size_dir[i].nr_page_desc = MAX_MALLOC_PAGE_DESC then exit(-1);

pdesc := get_free_kpage;

If pdesc=nil then exit(-1);

size_dir[i].nr_page_desc += 1;

for tmp:= 1 to (Page_Size div sizeof(Alloc_desc)) do
 begin
 pdesc^.mem_alloc:=nil;
 Push_Desc(size_dir[I].Unassign_List,pdesc);
 pdesc+=1;
end;

exit(0);
end;

function init_free_list(I:dword):dword;
var tmp:dword;
    pg:pointer;
    pdesc:p_alloc_desc;
begin

If size_dir[i].Unassign_List=nil then
 If Init_Unassign_List(I) <> 0 then exit(-1);

pg := get_free_kpage;

If pg=nil then exit(-1);

Mem_Alloc += Page_Size;

for tmp:= 0 to ((Page_Size div size_dir[i].size)-1) do
 begin

 pdesc := Pop_Desc(size_dir[i].Unassign_List);
 pdesc^.mem_alloc:=pg + (tmp * size_dir[i].size);

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

If Cola=nil then exit(nil);

If Cola^.mem_alloc=add_b then
 begin
 Remove_Desc:=Cola;
 Cola:=Cola^.next_alloc;
 exit;
end;

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

function kmalloc(Size:dword):pointer;
var i:dword;
    descp:p_alloc_desc;
    tmp:pointer;

    begin

If size > Page_Size then
 begin
 {$IFDEF DEBUG}
  printk('/nKmalloc : Se pide mas de 4096 bytes !!!!\n',[],[]);
 {$ENDIF}
 exit(nil);
end;

i:=0;
repeat
i+=1;
until (size_dir[i].size >= Size);

If size_dir[i].Free_list = nil then
 If Init_Free_List(i) <> 0 then exit(nil);

Mem_Alloc-=size_dir[i].size;
descp:=Pop_Desc(size_dir[i].Free_List);

Push_Desc(Size_dir[i].busy_list,descp);

{$IFDEF DEBUG}
 printk('/nKmalloc : Hueco /V %d \n',[longint(descp^.mem_alloc)],[]);
{$ENDIF}

tmp:=pointer(longint(descp^.mem_alloc) and $FFFFF000);
mem_map[longint(tmp) shr 12].count+=1;

exit(descp^.mem_alloc);

end;

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

descp:=Remove_Desc(size_dir[i].busy_list,addr);

If descp = nil then exit(-1);

descp^.next_alloc:=nil;

tmp:=pointer(longint(descp^.mem_alloc) and $FFFFF000);
mem_map[longint(tmp) shr 12].count-=1;

if mem_map[longint(tmp) shr 12].count=1 then
 begin
 Push_Desc(size_dir[i].unassign_list,descp);

 Clean_Free_List(i,tmp);

 free_page(tmp);

 end
else  Push_Desc(size_dir[i].free_list,descp);

Mem_Alloc+=size_dir[i].size;
{$IFDEF DEBUG}
 printk('/nKfree_S : Hueco /V %d liberado\n',[longint(addr)],[]);
{$ENDIF}
exit(0);
end;

procedure clean_free_list(i:dword;add_p:pointer);
var tmp,l:p_alloc_desc;
begin
tmp:=size_dir[i].free_list;
if tmp=nil then exit;

while (tmp <> nil) do
 begin
If pointer(longint(tmp^.mem_alloc) And $FFFFF000)=add_p then
 begin

 Del_Desc(size_dir[i].free_list,tmp);
 tmp^.mem_alloc:=nil;
 l:=tmp^.next_alloc;

 Push_Desc(size_dir[i].unassign_list,tmp);
 tmp:=l;
 end
else tmp:=tmp^.next_alloc;

end;
end;

{$DEFINE mem_lock := lock (@mem_wait) ; }
{$DEFINE mem_unlock := unlock (@mem_wait) ;}

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

Mem_Lock;

If vmm_alloc(Tarea_Actual,@Tarea_Actual^.text_area,size)=0 then
else
 begin
 Mem_Unlock;
 exit(nil);
 end;

Mem_Unlock;

Restore_Cr3 ;

Exit(oldpos);
end;

procedure paging_start;
var tmp:pointer;
    ret:dword;
begin
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

nr_page:=(MM_MemFree div Page_Size);
mem_map_size:=nr_page * sizeof(T_page);
nr_page-=(mem_map_size div Page_Size);
nr_free_page:=nr_page;
start_page:=(MeM_Ini + mem_map_size) div Page_Size;
start_mem:=pointer(start_page * Page_Size);
Low_Page_Free:=nil;
High_Page_Free:=nil;
mem_map:= pointer (Mem_Ini) ;

Init_Lista_Page_Free;

printkf('Number of available pages: /V%d/n\n',[nr_page]);
printkf('First Page: /V%d/n\n',[start_page]);
printkf('Pages in Mem_Map: /V%d/n\n',[mem_map_size div Page_Size]);

paging_start;

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

procedure MMInit;
begin
mm_total_fisica;
mm_memfree := mm_totalmem - mem_ini;
printkf('Total Physical Memory ... /V%d/n\n',[MM_TotalMem]);
printkf('Free Physical Memory  ... /V%d/n\n',[MM_MEMFREE]);
Paging_Init;
end;

end.
