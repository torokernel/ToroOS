Unit Malloc;

{ * Malloc :                                                            *
  *                                                                     *
  * Esta unidad se encarga del asignamiento de memoria al kernel  ,a    *
  * diferencia de get_free_kpage , esta maneja huecos de 16 , 32 , 64 , *
  * 128 , 256 , 512 , 1024 , 2048 y 4096 bytes , que se encuentran la   *
  * lista size_dir . Cada entrada aqui posee 3 colas, la cola de desc   *
  * no asignados , la cola de descriptores en uso y la cola de desc. a  *
  * huecos libres                                                       *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones:                                                          *
  * 05 / 07 / 2004 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************


}

interface

{DEFINE DEBUG}



{$I ../include/toro/procesos.inc}
{$I ../include/head/asm.h}
{$I ../include/head/mm.h}
{$I ../include/head/printk_.h}
{$I ../include/head/paging.h}



var size_dir : array[1..9] of dir_alloc_entry;
    Mem_Alloc: dword;


procedure Clean_Free_List(i:dword;add_p:pointer);


implementation

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
function kmalloc(Size:dword):pointer;[public , alias :'KMALLOC'];
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
function kfree_s(addr:pointer;size:dword):dword;[public , alias :'KFREE_S'];
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

end.
