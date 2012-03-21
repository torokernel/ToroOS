{ * Lock :                                                              *
  *                                                                     *
  * Inlines que implementan el uso de colas de espera para la protecc   *
  * ion de recursos como la memoria , dispositivos hard , gdt ,etc .    *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 9 / 05 / 2005 : Primera Version                                     *
  *                                                                     *
  ***********************************************************************
}

procedure lock (queue : p_wait_queue);inline;
begin

if queue^.lock then proceso_interrumpir (tarea_actual,queue^.lock_wait);

cerrar;
queue^.lock := true ;
abrir;
end;


procedure unlock (queue : p_wait_queue) ; inline;
begin
cerrar;
queue^.lock := false ;
proceso_reanudar (queue^.lock_wait,queue^.lock_wait);
abrir;
end;




