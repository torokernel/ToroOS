const

 {Comienzo del Area de Memoria Fisica}
 Mem_Ini=$300000;


 VMM_READ=1;
 VMM_WRITE=2;
 Brk_Limit = 16384 ;



 Type

 {Esto marca un area dentro del espacio mapeado de una tarea}
 p_vmm_area= ^vmm_area_struc;

 vmm_area_struc=record
 size:dword;
 add_l_comienzo:pointer;
 add_l_fin:pointer;
 flags:word;
 end;



