procedure proceso_init;external;
function thread_crear (Kernel_Ip:pointer):p_tarea_struc;external;
function proceso_crear (PPid:dword;Sched:word):p_tarea_struc;external;
function proceso_clonar (Tarea_padre:p_tarea_struc):p_tarea_struc;external;
procedure proceso_destruir (Tarea:p_tarea_struc);external;
procedure proceso_interrumpir (Tarea:p_tarea_struc ; var Cola:p_tarea_struc);external;
procedure proceso_reanudar (Tarea:p_tarea_struc;var Cola:p_tarea_struc);external;
procedure esperar_hijo (Tarea_Padre:p_tarea_struc;var PidH:dword;var err_code:word);external;
procedure proceso_eliminar(Tarea:p_tarea_struc);external;
Procedure Farjump (tss:word;entry:pointer) ; external;


var Tq_Interrumpidas : p_tarea_struc ; external name  'U_PROCESOS_TQ_INTERRUMPIDAS';
    Hash_Pid : array[1..Max_HashPid] of p_tarea_struc; external name 'U_PROCESOS_HASH_PID';

