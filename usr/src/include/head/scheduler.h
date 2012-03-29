procedure scheduling;external name 'SCHEDULING';
procedure scheduler_init;external name 'SCHEDULER_INIT';
procedure add_task (tarea:p_tarea_struc);external name 'ADD_TASK';
procedure remove_Task (tarea:p_tarea_struc);external name 'REMOVE_TASK';
procedure add_interrupt_task ( tarea : p_tarea_struc ) ; external name 'ADD_INTERRUPT_TASK';


function sys_setscheduler (pid , politica , prioridad :dword ) :dword;cdecl ;external name 'SYS_SETSCHEDULER' ;
function sys_getscheduler (pid : dword ) : dword ; cdecl ; external name 'SYS_GETSCHEDULER' ;

var tarea_Actual : p_tarea_struc ; external name 'U_SCHEDULER_TAREA_ACTUAL';
    need_sched : boolean ; external name 'U_SCHEDULER_NEED_SCHED';

