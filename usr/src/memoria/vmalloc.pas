Unit Vmalloc;

{ * Vmalloc :                                                           *
  *                                                                     *
  * Este modulo se encarga de la asignacion de memoria a los procesos   *
  * de usuario , se crea la abstraccion de las vm (virtual memory) ,    *
  * estas son areas mas alla de HIGH_MEMORY que pueden crecer o disminu *
  * ir  . Tambien  pueden ser de acceso R o W  . Por ahora cada proceso *
  * solo implementa dos areas  , la stack_vmm y la text_vmm . La        *
  * text_vmm , contiene TEXT + DATA + BBS  y tiene acceso R/W           *
  * Aqui se realiza toda la administracion de estas areas               *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  * 10 / 06 / 2004 : Version Inicial                                    *
  *                                                                     *
  ***********************************************************************
}



interface

{DEFINE DEBUG}


{$I ../include/toro/procesos.inc}
{$I ../include/head/asm.h}
{$I ../include/head/printk_.h}
{$I ../include/head/procesos.h}
{$I ../include/head/paging.h}
{$I ../include/head/mapmem.h}
{$I ../include/head/scheduler.h}


implementation


{$I ../include/head/lock.h}

{ * Vmm_Map :                                                           *
  *                                                                     *
  * Page : Puntero a una pagina                                         *
  * Task : Tarea donde sera mapeada la pagina                           *
  * Vmm_Area : Area donde sera mapeada la pagina                        *
  *                                                                     *
  * Esta funcion mapeada un pagina dada dentro de un area vmm , a dife  *
  * rencia de vmm_alloc , solo se limita a mapear un pagina             *
  *                                                                     *
  ***********************************************************************
}
function vmm_map(page:pointer;Task:p_tarea_struc;vmm_area:p_vmm_area):dword;[public , alias :'VMM_MAP'];
var total_pg,tmp:dword;
    at:word;
begin
 at:=0;

 case vmm_area^.flags of
 VMM_WRITE:at:=Present_Page or User_Mode or Write_page;
 VMM_READ :at:=Present_Page or User_Mode;
 end;

 vmm_area^.add_l_fin += 1;

 umapmem(page,vmm_area^.add_l_fin ,task^.dir_page,at);
 vmm_area^.add_l_fin+=Page_Size - 1 ;

 vmm_area^.size+=Page_Size;

exit(0);
end;


{ * Vmm_Alloc :                                                        *
  *                                                                    *
  * Task : Tarea donde sera alocada el area                            *
  * Vmm_Area : Puntero al area donde sera alocada                      *
  * Size : Tamano de la que sera alocado                               *
  *                                                                    *
  * Esta funcion agrega la cantidad de memoria pedida en size al final *
  * del area punteada en VMM_AREA                                      *
  *                                                                    *
  **********************************************************************
}
function vmm_alloc(Task:p_tarea_struc;vmm_area:p_vmm_area;size:dword):dword;[public , alias :'VMM_ALLOC'];
var total_pg,tmp:dword;
    page,add_l:pointer;
    at:word;
begin

{ Tamano del area }
total_pg := (size div Page_Size);
If (size mod Page_Size)=0 then else total_pg+=1;

{ Hay espacio para el area }
If total_pg > nr_free_page then exit(-1);

{ Se mapean todas las nuevas paginas en el dir de usuario }
for tmp:= 1 to total_pg do
 begin
 page := get_free_page;
 { No se evaluo page que puede ser nil }
 vmm_map(page,Task,vmm_area);

 end;

exit(0);
end;


{ * Vmm_Free :                                                          *
  *                                                                     *
  * Task : Tarea donde sera liberada la zona                            *
  * Vmm_area : Area que sera liberada                                   *
  *                                                                     *
  * Esta funcion desmapea toda la memoria utilizada por una vmm         *
  * Aclaracion : Deve trabajar con Kernel_PDT                           *
  *                                                                     *
  ***********************************************************************
}
function vmm_free(Task:p_tarea_struc;vmm_area:p_vmm_area):dword;[public , alias :'VMM_FREE'];
var i,f:dword;
    pg,fpg:pointer;
Begin

If vmm_area^.size = 0 then exit;

pg:=vmm_area^.add_l_comienzo;

repeat
Unload_Page_Table(pg,Task^.dir_page);
pg += Page_Size * 1024;
until (vmm_area^.add_l_comienzo <= vmm_area^.add_l_fin);

vmm_area^.add_l_comienzo:=nil;
vmm_area^.add_l_fin:=nil;
vmm_area^.size:=0;
vmm_area^.flags:=0;

exit(0);

end;



{ * Vmm_Clone :                                                         *
  *                                                                     *
  * Task_p : Tarea Padre                                                *
  * Task_H : Tarea Hijo                                                 *
  * Vmm_area_p : Area de origen                                         *
  * Vmm_area_h : Area de distino                                        *
  * ret : 0 si fue correcta o -1 si no                                  *
  *                                                                     *
  * Esta funcion duplica una vmm , lo que hace basicamente es copiar    *
  * las tablas de pagina de la zona del padre a la misma area logica    *
  * dentro del PDT del hijo , aumentando el contador de uso de cada pag *
  * ina                                                                 *
  * Aclaracion : Devemos utilizar Kernel_PDT                            *
  *                                                                     *
  ***********************************************************************
}

function vmm_clone(Task_P,Task_H:p_tarea_struc;vmm_area_p,vmm_area_h:p_vmm_area):dword;[public , alias :'VMM_CLONE'];
var add_f:pointer;
    total_tp,tmp:dword;
    i,fin:indice;
    pt_p,pt_h:^dword;
begin


i := Get_Page_Index(vmm_area_p^.add_l_comienzo);
fin := Get_Page_Index(vmm_area_p^.add_l_fin);
pt_p := Task_P^.dir_page;
pt_h := Task_H^.dir_page;

{ Duplica las tablas de pagina }
for tmp:= i.dir_I to fin.dir_i do
  begin
  { direccion de la tp }
  add_f := pointer(longint(pt_p[tmp]) and $FFFFF000);

  { se duplica la tp }
  dup_page_table(add_f);

  pt_h[tmp] := pt_p[tmp];
end;

{ el descriptor del area es duplicado }
vmm_area_h^:=vmm_area_p^;

exit(0);
end;


{ * Vmm_Copy:                                                           *
  *                                                                     *
  * Task_Ori : Tarea de origen                                          *
  * Task_Dest : Tarea de destino                                        *
  * vmm_area_ori : Area de origen                                       *
  * vmm_area_dest : Area de destino                                     *
  *                                                                     *
  * Esta funcion a diferencia de vmm_dup copia una vmm aa otra pagina   *
  * por pagina .                                                        *
  * Esta funcion deve trabajar sobre Kernel_Pdt                         *
  *                                                                     *
  ***********************************************************************
}
procedure vmm_copy(Task_Ori,Task_Dest:p_tarea_struc;vmm_area_ori,vmm_area_dest:p_vmm_area);[public , alias :'VMM_COPY'];
var tmp:dword;
    ori,dest:pointer;
begin
for tmp:= 0 to (vmm_area_ori^.size div Page_Size)-1 do
 begin
 ori := vmm_area_ori^.add_l_comienzo + (tmp * Page_Size);
 ori := Get_Phys_Add(ori,Task_Ori^.dir_page);
 dest := vmm_area_dest^.add_l_comienzo + (tmp * Page_Size);
 dest := Get_Phys_Add(dest,Task_Dest^.dir_page);
 memcopy(ori,dest,Page_Size);
 end;
end;


{ * Sys_Brk :                                                            *
  *                                                                      *
  * Size : Tamano en que aumentara el segmento de datos                  *
  *                                                                      *
  * Esta funcion aumenta de acuerdo size el tama¤o del segmento de datos *
  * que es el area vmm text_area . Se mantienen las especificaciones de  *
  * de la llamadas al sistema brk() de Unix , en que el deve haber un    *
  * espacio de 16kb entre STACK_AREA y el fin de text_area               *
  *                                                                      *
  * Modificaciones :                                                     *
  * 01 / 09 / 2004 : Version Inicial                                     *
  ************************************************************************
}
function sys_brk(Size:dword):pointer;cdecl;[public , alias : 'SYS_BRK'];
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

If vmm_alloc(Tarea_Actual,@Tarea_Actual^.text_area,size)=0 then printk('/nSys_Brk : Ok\n',[],[])
else
 begin
 Mem_Unlock;
 exit(nil);
 end;

Mem_Unlock;

Restore_Cr3 ;

Exit(oldpos);
end;



end.
