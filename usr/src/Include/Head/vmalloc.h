function vmm_alloc(Task:p_tarea_struc;vmm_area:p_vmm_area;size:dword):dword;external;
function vmm_map(page:pointer;Task:p_tarea_struc;vmm_area:p_vmm_area):dword;external;
function vmm_free(Task:p_tarea_struc;vmm_area:p_vmm_area):dword;external;
procedure vmm_copy(Task_Ori,Task_Dest:p_tarea_struc;vmm_area_ori,vmm_area_dest:p_vmm_area);external;
function vmm_clone (Task_p,Task_H : p_tarea_struc ; vmm_area_p , vmm_area_h : p_vmm_area ) : dword ;external;
function  sys_brk(Size:dword):pointer;cdecl;external;
