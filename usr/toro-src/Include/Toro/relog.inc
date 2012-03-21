

Const
   Control_Port = $43;
   Frecuencia = 1193182;
   Salida_Bin: array[0..3] of byte=(%00,%01000000,%10000000,%11000000);
   Salida_port : array[0..3] of byte=($40,$41,$42,$44);
   Modo = %00110110;

   {Irq. 0 por segundo}
   Relog_Sistema = 1000;



