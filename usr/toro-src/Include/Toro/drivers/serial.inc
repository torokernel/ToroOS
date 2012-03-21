CONST
  {Constantes para la velocidad}
  v1200=96;
  v2400=48;
  v3600=32;
  v4800=24;
  v7200=16;
  v9600=12;
  v19200=6;
  v28800=4;
  v38400=3;
  v57600=2;
  v115200=1;
 {Contantes para la paridad}
  Sin_Paridad=%0;
  Paridad_Impar=%1000;
  Paridad_Par=%11000;
  Marca=%101000;
  Espacio=%111000;
 {Constantes para el tama¤o del envio}
  bits_8=%11;
  bits_5=%00;
  bits_7=%10;
  bits_6=%01;
 {Constantes para el bit de parada}
  Parada_1=%0;
  Parada_2=%100;
 {Maxima Cantidad de puertos}
  Max_port=4;
 {Posibles respuestas de funciones}
  Arg_Invalidos=1;
  Correcto=0;
  Com_Invalido=2;
 {Manejo de Buffer FIFO}
  FIFO1=%00;
  FIFO4=%01000000;
  FIFO8=%10000000;
  FIFO14=%11000000;
  NO_FIFO=255;

  {Causas de Interrupciones}
  Nuevo_Dato=%100;
  Puerto_Disponible=%10;
  Error=%110;
  Estado_modem=%0;



RBR_Reg=0;{Registro Bufer de Recepcion}
DLL_REG=0;{Divisor de velocidad , parta baja DLAB=1}
THR_REG=0;{Registro de retencion de Transmision}
IER_REG=1;{Registro de Habilitacion de Interrupciones}
DLM_REG=1;{Divisor de Velocidad , parte alta  DLAB=1}
IIR_REG=2;{Registro de Identificacion de Interrupcion}
FCR_REG=2;{Registro de Control FIFO}
LCR_REG=3;{Registro de Control de Linea}
MCR_REG=4;{Registro de control del modem}
LSR_REG=5;{Registro de estado de la linea}
MSR_REG=6;{Registro de estado del modem}
SCR_REG=7;{NO SE UTILIZA}

