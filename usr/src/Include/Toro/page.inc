{$I mm.inc}

const

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
