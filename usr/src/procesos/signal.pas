Unit Signal;

{ * Signal:                                                            *
  *                                                                    *
  * Esta unidad es la encargada de chequear si la tarea actual posee   *
  * alguna se¤al pendiente y ejecutar la se¤al correspondiente         *
  * de la se¤al se deve volver con un RET , como si fuese una          *
  * llamada CALL convenicional , si hay muchas signal esperando ser    *
  * atendidas son anidas y la ultima vuelve a la tarea que se estaba   *
  * ejecutando                                                         *
  * Cada BIT de los flags de signal corresponde a un puntero dentro    *
  * del array de punteros signals[]                                    *
  *                                                                    *
  * Hay un total de 32 Signals posibles                                *
  *                                                                    *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>         *
  * All Rights Reserved                                                *
  *                                                                    *
  * Versiones :                                                        *
  *                                                                    *
  * 02 / 04 / 2005 : Es reescrita la mayor parte de la unidad          *
  * ?? - ?? - ?? : Version Inicial                                     *
  *                                                                    *
  **********************************************************************

}

interface

{DEFINE DEBUG}


{$I ../include/toro/procesos.inc}
{$I ../include/toro/signal.inc}
{$I ../include/head/irq.h}
{$I ../include/head/gdt.h}
{$I ../include/head/mm.h}
{$I ../include/head/idt.h}
{$I ../include/head/asm.h}
{$I ../include/head/scheduler.h}
{$I ../include/head/procesos.h}
{$I ../include/head/printk_.h}



implementation



{ * Empilar_Signal :                                                       *
  *                                                                        *
  * new_ret : Nuevo punto de retorno                                       *
  *                                                                        *
  * Proceso que se encarga de anidar las se¤ales de un proceso             *
  *                                                                        *
  **************************************************************************
}

function enpilar_signal (new_ret : pointer ) : dword ;
var tmp , esp : ^dword ;
    s : dword ;
begin

{ Puntero  donde se encuentra la direcion de retorno }
tmp := Tarea_Actual^.ret_eip ;

{ la salvo }
s := tmp^ ;

{ nueva direccion de retorno }
tmp^ := longint(new_ret);

{ esp de retorno }
tmp := Tarea_Actual^.ret_esp ;

{ ahora devo decrementar para guardar el retorno anterior }
tmp^ -= 4;

esp := pointer(tmp^) ;

{ coloco en la pila de usuario el retorno anterior }
esp^ := s ;

exit(0);
end;


{ * Kernel_Signal_Handler :                                             *
  *                                                                     *
  * Manejador de las se¤ales del kernel , cuando un proceso no quiere   *
  * controlarlas el mismo el kernel lo hara , siempre se destruye al    *
  * proceso si recibe una se¤al no esperada no procesable               *
  *                                                                     *
  ***********************************************************************
}
procedure kernel_signal_handler;
var tarea:pointer ;
begin

//printk('$d',[],[Tarea_Actual^.pid]);
printk('/nMuerte por Se¤al : %s \n',[dword(@Sig_name[tarea_actual^.terminacion][1])]);

Proceso_destruir (Tarea_Actual);

scheduling;
end;




{ * Signaling :                                                         *
  *                                                                     *
  * Este proceso es el nucleo de las se¤ales , este es llamado cada vez *
  * que se vuelve a ejecutar una tarea , y evalua que bit de signal esta*
  * activo y de acuerdo a estos bit , ejecuta su hilo correspondiente , *
  *                                                                     *
  ***********************************************************************
}

procedure signaling;[public , alias : 'SIGNALING'];
var tmp  , ret : dword ;
    ret2 : word;
    signal_handler , tarea: pointer ;
begin

{ Son rastreadas todas las signal }
for tmp:= 0 to 31 do
 begin

  { Se esta aguardando por su ejecucion ? }
  if Bit_Test(@Tarea_Actual^.flags_de_signal,tmp) then
   begin

   signal_handler := Tarea_actual^.signals[tmp];

   { Se baja el bit de pendiente }
   bit_reset(@Tarea_Actual^.flags_de_signal,tmp);

   case tmp of
   Sig_Hijo : begin
              Esperar_Hijo (Tarea_Actual,ret,ret2);
              continue;
              end;
   Sig_Morir:begin

              Tarea_Actual^.terminacion := Sig_Morir ;
              Proceso_Destruir (Tarea_Actual) ;

              { Se replanifica }
              Scheduling;

              exit;
             end;
   Sig_Detener:begin
                Proceso_Interrumpir (Tarea_Actual,Tq_Interrumpidas);
                exit;
               end;
   Sig_Alarm:begin
              Enpilar_signal (signal_handler);
              Tarea_Actual^.signals[Sig_Alarm] := nil ;
             end;
   Sig_ili : begin
             { puede ser que el kernel deva ocuparse de la se¤al }

             if signal_handler = nil then
              begin
               Tarea_actual^.terminacion := Sig_ili ;
               kernel_signal_handler;
              end;

             end;
   Sig_Segv : begin

              { puede ser que el kernel deva ocuparse de la se¤al }

              if signal_handler = nil then
               begin
                Tarea_actual^.terminacion := Sig_Segv ;
                kernel_signal_handler;
               end;

              end;
   Sig_Dive : begin
              { puede ser que el kernel deva ocuparse de la se¤al }

              if signal_handler = nil then
               begin
                Tarea_actual^.terminacion := Sig_Dive ;
                kernel_signal_handler;
               end;

              end;
   Sig_Fpue : begin
              { puede ser que el kernel deva ocuparse de la se¤al }

              if signal_handler = nil then
               begin
                Tarea_actual^.terminacion := Sig_Fpue ;
                kernel_signal_handler;
               end;

              end;
   Sig_BrkPoint : begin

                  if signal_handler = nil then
                   begin
                    Tarea_Actual^.terminacion := Sig_brkpoint ;
                    kernel_signal_handler;
                   end;

                  end;
   Sig_OverFlow : begin

                  if signal_handler = nil then
                   begin
                    Tarea_Actual^.terminacion := Sig_Overflow ;
                    kernel_signal_handler;
                   end;

                  end;


       end;

   { la se¤al es procesada por el usuario }
   Enpilar_Signal (signal_handler);
   Tarea_Actual^.signals[tmp] := nil ;
   end;
  end;

end;





{ * Signal_Send :                                                         *
  *                                                                       *
  * Tarea:Tarea a la que se le envia la se¤al                             *
  * signal: Numero de se¤al                                               *
  *                                                                       *
  * Esta funcion envia una se¤al a la tarea indicada en TAREA , activando *
  * el correspondiente BIT                                                *
  * Devolvera error si no hubiera un tratamiento para la se¤al            *
  *                                                                       *
  *************************************************************************
}
procedure signal_send(Tarea:p_tarea_struc;signal:word);[public , alias :'SIGNAL_SEND'];
begin

{ Zona critica }
cerrar;

if Tarea_Actual= nil then Panic ('/nImposible cargar toro  , excepcion desconocida !!!!\n');

{ Ya se esta procesando otra signal }
if Bit_test(@tarea^.flags_de_signal,signal) then exit;

{ Se activa su bit }
Bit_Set(@Tarea^.flags_de_signal,signal);

abrir;

 {$IFDEF DEBUG}
  printk('/nSignal : %d /n --> Pid : %d /V Send\n',[signal,Tarea_actual^.pid],[]);
 {$ENDIF}

end;








end.
