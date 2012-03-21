Unit Mapmem;

{ * Mapmem :
  *                                                                   *
  * Esta unidad se encarga del mapeo de paginas dentro de dp , tanto  *
  * usuarios como  el del kernel , en los casos del usuario , puede   *
  * pasar que la pagina se encuentre mas alla de HIGH_MEMORY   ,      *
  * asi solo a traves del KERNEL_PDT se podra acceder a estas paginas *
  *                                                                   *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>        *
  * All Rights Reserved                                               *
  *                                                                   *
  * Versiones :                                                       *
  * 05 / 07 / 2004 : Version Inicial                                  *
  *                                                                   *
  *********************************************************************
}

interface


{DEFINE DEBUG}


{$I ../include/toro/procesos.inc}
{$I ../include/head/asm.h}
{$I ../include/head/mm.h}
{$I ../include/head/printk_.h}
{$I ../include/head/paging.h}



implementation


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
function kmapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;[public , alias :'KMAPMEM'];
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
function umapmem(add_f , add_l , add_dir:pointer;atributos:word):dword;[public , alias :'UMAPMEM'];
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



{ * Kunmapmem :                                                         *
  *                                                                     *
  * add_l : Direccion logica de la pagina                               *
  * add_dir : Directorio de paginas                                     *
  *                                                                     *
  * Esta funcion quita de un directorio una direcion logica dada , pero *
  * no llama a free_page , devuelve la pagina fisica , para que sea     *
  * liberada luego , si la tabla de paginas estubiese vacia la libera   *
  * del PDT                                                             *
  *                                                                     *
  ***********************************************************************
}
function kunmapmem(add_l,add_dir:pointer):pointer;[public , alias :'KUNMAPMEM'];
var  tp,dp:^dword;
     i:indice;
     tmp,count:word;
begin


{ Las direcciones deven estar alineadas con los 4 kb }
  If ((longint(add_l) and $FFF) =0) or ((longint(add_dir) and $FFF)=0)  then
   else exit(nil);


i:=Get_Page_Index(add_l);
dp:=add_dir;
dp+=i.dir_i;

 { Si el directorio no estubiese presente }
 If (dp^ and Present_Page) = 0 then exit(nil);


{ Punteo al comienzo de la Tabla de Paginas }
tp:=pointer(dp[I.dir_i] and $FFFFF000);

 { Si la pagina no estubiese presente }
 If (tp[I.Page_i] and Present_Page)= 0 then exit(nil);


kunmapmem:=pointer(tp[I.page_i] and $FFFFF000);
tp[I.Page_i]:=0;

{ Se verifica si todas las paginas de la tabla fueron liberadas }
{ y en ese caso se libera la tabla de paginas }

for tmp:= 1 to (Page_Size div 4) do If tp[tmp]=0 then count+=1;

If count =(Page_Size div 4) then
 begin
 Free_Page(pointer(dp^ and $FFFFF000));
 { Se calcula la dir fisica para Free_Page }
 dp^:=0; { Es borrada la entrada en el directorio }
end;

end;


{ * Unmapmem :                                                          *
  *                                                                     *
  * Vease KUNMAPMEN , es exactamente lo mismo pero para el usuario      *
  * Aclaracion : Deve trabajar sobre Kernel_Pdt                         *
  *                                                                     *
  ***********************************************************************
}
function unmapmem(add_l,add_dir:pointer):pointer;[public , alias :'UNMAPMEM'];
var  tp,dp:^dword;
     i:indice;
     tmp,count:word;
begin


{ Las direcciones deven estar alineadas con los 4 kb }
  If ((longint(add_l) and $FFF) =0) or ((longint(add_dir) and $FFF)=0)  then
   else exit(nil);


i := Get_Page_Index(add_l);
dp := add_dir;
dp += i.dir_i;

 { Si el directorio no estubiese presente }
 If (dp^ and Present_Page) = 0 then exit(nil);


{ Punteo al comienzo de la Tabla de Paginas }
tp:=pointer(dp[I.dir_i] and $FFFFF000);

 { Si la pagina no estubiese presente }
 If (tp[I.Page_i] and Present_Page)= 0 then exit(nil);


unmapmem:=pointer(tp[I.page_i] and $FFFFF000);
tp[I.Page_i]:=0;

{ Se verifica si todas las paginas de la tabla fueron liberadas }
{ y en ese caso se libera la tabla de paginas }
for tmp:= 1 to (Page_Size div 4) do If tp[tmp]=0 then count+=1;

If count =(Page_Size div 4) then
 begin
 Free_Page(pointer(dp^ and $FFFFF000));{ Se calcula la dir fisica para Free_Page}
 dp^:=0;{ Es borrada la entrada en el directorio }
end;
end;

end.
