{Estructura de un Timer}
Type
 p_struc_timer=^struc_timer;

 {estrutura general de los timer}
 struc_timer = record
 interval : dword ;
 time_action:dword;
 end;

 p_timer_kernel = ^struc_timer_kernel ;

 {estructura utilizada para los timers de kernel}
 struc_timer_kernel = record
 timer : struc_timer ;
 handler : procedure ( param : dword ) ;
 param : dword ;
 next_timer : p_timer_kernel ;
 prev_timer : p_timer_kernel ;
 end;


 p_timer_user = ^struc_timer_user ;

 {estructura de los timers de usuarios}

 struc_timer_user = record
 timer : struc_timer;
 tarea:pointer;
 estado:boolean;
 next_timer:p_timer_user;
 prev_timer:p_timer_user;

end;
