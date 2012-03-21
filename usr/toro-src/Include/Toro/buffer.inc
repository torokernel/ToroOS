
const

{ Maximo tama¤ode bloque manejable }
Max_blk_size = 4096 ;


{Porcentage de utilizacion del buffer-cache de la memoria}
Buffer_Use_Mem  = 1 ;

{ valores del mapa de bits de state }
Bh_Dirty = 2 ;



type
p_buffer_Head = ^buffer_head;

buffer_head=record
bloque : dword ;
size : dword ;
Mayor : dword ;
Menor : dword ;
count:dword;
state : dword ;
data:pointer;
wait_on_buffer:wait_queue;
next_buffer:p_buffer_head;
prev_buffer:p_buffer_head;
next_bh_dirty : p_buffer_head;
end;


