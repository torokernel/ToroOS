
 {$I wait.inc}
 {$I gdt.inc}
 {$I task.inc}
 {$I page.inc}
 {$I relog.inc}
 {$i timer.inc}
 {$I sched.inc}
 {$I fs.inc}



 Const

 {Comienzo del area de pila del usuario}
 Stack_Page = $80000000;

 {Tiempo  de Cpu}
 Quantum = 100;

 {Numero de entradas en el array de la tabla Hash}
 Max_HashPid = 1000 ;

 {Estados de los Procesos }
 Tarea_Lista=1;
 Tarea_Corriendo=2;
 Tarea_Interrumpida=4;
 Tarea_Zombie=5;

 {Valores de Prioridad}
 nice_bajo = 1 ;
 nice_normal = 2 ;
 nice_alto = 3 ;

 {Maxima cantidad de llamadas al sistema}
 Nr_Syscall=50;


 {Estructura de un proceso cualquiera}

 type
 p_Tarea_struc=^Tarea_struc;

 Tarea_struc=record

 pid : dword;           {Ident. de procesos}
 PaDre_Pid : dword;       {pid del Padre     }
 estado : byte;         {Estado del proceso}
 Terminacion : byte;    {Causa de que termino }
 Politica : byte;       {Politica empleada para la planificacion }

 quantum_a : byte;      {cantidad de tiempo que lleva }
 errno : dword ;

 {Numero de milisegundos consumidos en cpu}
 virtual_time : dword ;

 {tiempo real de milisegundos en cpu , este indica el momento en que entro
 a la ejecucion devera ser restado a contador para saber su edad}
 real_time : dword ;
 nice : word ;

 tss_descp : word;      {Descriptor a la TSS dentro de la GDT para cuando se libera}
 tss_p : ^struc_descriptor; {Puntero al descriptor dentro de la GDT}

 {Registros Generales de la TAREA}
 reg:tss_struc;

 {punteros a los retornos cuando el proceso entra en modo nucleo}
 ret_eip  , ret_esp : pointer;

 {Punteros a tratamientos de ejecucion}
 signals : array[0..31] of pointer;
 flags_de_signal : dword;{Flags que ordenan la ejecucion de signals}

 {puntero al pdt de usurio}
 dir_page : pointer;

 {puntero a la pagina de pila 0 }
 stack0_page : pointer;

 {area de memoria virtual}
 text_area  : vmm_area_struc;
 data_area  : vmm_area_struc;
 stack_area : vmm_area_struc;

 {Los timer de usuarios}
 Despertador : struc_timer;
 Timer : struc_timer_user;

 {Area de fs del proceso}
 Archivos:array[0..32] of file_t;
 cwd:p_inode_t;

 {puntero a las colas ligadas }
 next_tarea:p_tarea_struc;
 prev_tarea:p_tarea_struc;
 hash_next:p_tarea_struc;
 hash_prev:p_tarea_struc;

 end;


 {$DEFINE set_errno := Tarea_Actual^.errno  }
 {$DEFINE clear_errno := Tarea_Actual^.errno := 0 }

