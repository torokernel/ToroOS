procedure proceso_init;external name 'PROCESO_INIT';
function thread_crear (Kernel_Ip:pointer):p_tarea_struc;external name 'THREAD_CREAR';
function proceso_crear (PPid:dword;Sched:word):p_tarea_struc;external name 'PROCESO_CREAR';
function proceso_clonar (Tarea_padre:p_tarea_struc):p_tarea_struc;external name 'PROCESO_CLONAR';
procedure proceso_destruir (Tarea:p_tarea_struc);external name 'PROCESO_DESTRUIR';
procedure proceso_interrumpir (Tarea:p_tarea_struc ; var Cola:p_tarea_struc);external name 'PROCESO_INTERRUMPIR';
procedure proceso_reanudar (Tarea:p_tarea_struc;var Cola:p_tarea_struc);external name 'PROCESO_REANUDAR';
procedure esperar_hijo (Tarea_Padre:p_tarea_struc;var PidH:dword;var err_code:word);external name 'ESPERAR_HIJO';
procedure proceso_eliminar(Tarea:p_tarea_struc);external name 'PROCESO_ELIMINAR';
Procedure Farjump (tss:word;entry:pointer) ; external name 'FARJUMP';


var Tq_Interrumpidas : p_tarea_struc ; external name  'U_PROCESOS_TQ_INTERRUMPIDAS';
    Hash_Pid : array[1..Max_HashPid] of p_tarea_struc; external name 'U_PROCESOS_HASH_PID';

