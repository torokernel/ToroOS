
  {estrutura para la proteccion acceso a recursos}

 type
 p_wait_queue = ^wait_queue ;

 wait_queue = record
 lock : boolean ;
 Lock_Wait : pointer ;
 end;