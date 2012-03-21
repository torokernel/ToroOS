Unit Relog;

{ * Relog :                                                              *
  *                                                                      *
  * Esta libreria se encarga de controlar al generador de la             *
  * irq 0 , en el que esta instalado el scheduler , maneja               *
  * todas las salidas de este                                            *
  *                                                                      *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>           *
  * All Rights Reserved                                                  *
  *                                                                      *
  * Versiones :                                                          *
  *                                                                      *
  * 16 / 01 / 2005 : Se crea la llamada al sistema Sys_Time y Sys_Stime  *
  *                                                                      *
  * ?? / ?? / ???? : Primera Version                                     *
  *                                                                      *
  ************************************************************************
}

interface


{DEFINE DEBUG}

{$I ../Include/Toro/page.inc}
{$I ../Include/Toro/relog.inc}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/printk_.h}

implementation

{$I ../Include/Head/ioport.h}


procedure poner_contador(Freq:word;Salida:byte);
var cont:word;
    config:byte;
    buf:byte;
    s:byte;
begin

cont:=Frecuencia div Freq;
config:=Modo xor salida_bin[Salida];
enviar_byte(config,Control_Port); {Configuro el puerto}

asm
 mov ax,cont
 mov buf,al
end;
enviar_byte(buf,salida_port[salida]);{envio la parte baja}
asm
mov ax,cont
mov buf,ah
end;
enviar_byte(buf,salida_port[salida]);{envio la parte alta}
end;


procedure iniciar_relog;[public , alias :'INICIAR_RELOG'];
begin

asm
          mov eax,1191180
          mov ebx,1000
          xor edx,edx
          div ebx
          mov ecx,eax
          mov al,52
          out $43,al
          mov al,cl
          out $40,al
          mov al,ch
          out $40,al

end;

end;


{ * sonar_parlante : hace sonar al parlante a la frecuencia indicada * }

procedure sonar_parlante(Freq:word);[public , alias :'SONAR_PARLANTE'];
var s:byte;
begin
poner_contador(Freq,2);
s:=leer_byte($61);
s:=s or 3;
enviar_byte(s,$61);
end;

{  * parar_parlante : Para el sonido emitido por el parlante * }

procedure parar_parlante;[public , alias :'PARA_PARLANTE'];
begin
asm
mov dx,$61
in al,dx
and al,$fc
out dx,al
end;
end;



{ * Sys_Time :                                                          *
  *                                                                     *
  * T: Puntero del buffer donde sera almacenada la hora actual          *
  * Retorno : 0 si fue correcto o -1 sino                               *
  *                                                                     *
  * Llamada al sistema que devuelve la hora actual del sistema          *
  *                                                                     *
  ***********************************************************************
}

function sys_time(t:pointer):dword;cdecl;[public , alias : 'SYS_TIME'];
var res : dword ;
begin

res := get_datetime;

If (t <> nil ) and (t > pointer(High_Memory)) then
 begin
 memcopy(@res,t,sizeof(res));
 exit(0);
 end
 else exit(-1);

end;



{ * Ktime :                                                           *
  *                                                                   *
  * Retorno : Un dword que indica la fecha actual                     *
  *                                                                   *
  * Funcion utilizada por el kernel que al igual que Time devuelve la *
  * fecha actual                                                      *
  *                                                                   *
  *********************************************************************
}
function ktime : dword ; [public , alias : 'KTIME'];
begin
exit(get_datetime);
end;



{ * Sys_Stime :                                                         *
  *                                                                     *
  * Time : Fecha dada en segundos                                       *
  * Retorno : 0 si fue correcto o -1 sino                               *
  *                                                                     *
  * Llamada al sistema que pone en hora el relog del sistema            *
  *                                                                     *
  ***********************************************************************
}

function sys_stime( time : dword ) : dword ; cdecl ; [public , alias : 'SYS_STIME'];
var sec , min , hour , day , mon , year  , tmp: dword;
begin
{Llamada al sistema no implementada por el momento}
end;

end.

