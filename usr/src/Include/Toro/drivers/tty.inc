CONST

NR_TTY=1;

TTY_OFFSET = $B8000 ;
Scree_Size = 4000 ;
Tty_Mayor = 31 ;

{Comandos a IOCTL}
IO_SET_TTY_TORO = 1;
IO_GET_TTY_TORO = 2;


{En un futuro ests struc. estara mas completa}
{por ahora solo se maneja una sola terminal}


Type
p_tty = ^tty_struct;

tty_struct=record
echo : boolean;
flush : boolean;
color : byte ;
end;




