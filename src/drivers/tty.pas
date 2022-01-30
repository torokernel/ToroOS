Unit tty;

{ * Tty :                                                               *
  *                                                                     *
  * Esta unidad se encarga del manejo de terminales , por ahora solo so *
  * porta una sola terminal . Tambien se ancarga de captar las pulsacio *
  * nes de tecla y posee un tratamiento especial para los F1..F5        *
  * No se le da un gran manejo a las terminales eso se le deja a los pr *
  * ogrma de usuario.                                                   *
  * La estructura tty_dev controla  ala terminal  , es modificada       *
  * con la llamada ioctl() .Hay gran cantidad de carateres especiales   *
  * estos son  apartir del caracter 250 en adelante                     *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasevara@gmail.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones  :                                                        *
  *                                                                     *
  * 04 / 01 / 2006 : El driver de keyb forma parte de la tty pero sigue *
  * registrandose como un driver diferente                              *
  *                                                                     *
  * 20 / 01 / 2005 : Se aplica el nuevo modelo de driver y se desliga   *
  * el driver del keyb                                                  *
  *                                                                     *
  * 23 / 07 / 2004 : Se modifica el proc. que manejas las interrupciones*
  * del teclado , haciendo que no pase por el Interrumptor para agiliza *
  * la captura de pulsaciones                                           *
  *                                                                     *
  * 06 / 07 / 2004 : La escritura de la terminal se realiza por Printf  *
  *                                                                     *
  * 18 / 03 / 2004 : Primera Version                                    *
  *                                                                     *
  ***********************************************************************
}

interface

uses filesystem, process, arch, printk;

{$DEFINE tty_lock := lock (@tty_wait) ; }
{$DEFINE tty_unlock := unlock (@tty_wait) ; }
{$DEFINE keyb_lock := lock (@keyb_queue_wait); }
{$DEFINE keyb_unlock := unlock (@keyb_queue_wait) ; }

Const
NR_TTY=1;

TTY_OFFSET = $B8000 ;
Scree_Size = 4000 ;
Tty_Mayor = 31 ;

{Comandos a IOCTL}
IO_SET_TTY_TORO = 1;
IO_GET_TTY_TORO = 2;


{En un futuro ests struc. estara mas completa}
{por ahora solo se maneja una sola terminal}


KEYB_PORT=$60;
KEYB_MAYOR = 32 ;


{SCAN CODE}
EXT_CODE=$e0;


Kbesc=1;

Kbenter=28;
Kbleft=75;
Kbrigth=77;
kbSpace=57;
KbBkSpc=14;
kbUp = 72 ;
kbdown = 80 ;
KbCrtl=29;
KbAlt=56;
KbCapsLock=58;
KbShift=42;
kbF1    =$3B;
kbF2    =$3C;
kbF3    =$3D;
kbF4    =$3E;
kbF5    =$3F;
kbF6    =$40;
kbF7    =$41;
kbF8    =$42;
kbF9    =$43;
kbF10   =$44;
kbF11   =$85;
kbF12   =$86;

CHAR_CODE : array [1..57] of char=
   ('0','1','2','3','4','5','6','7','8','9','0','?','=','0',' ','q','w',
   'e','r','t','y','u','i','o','p','[',']','0','0','a','s','d','f','g','h',
   'j','k','l','0','{','}','0','0','z','x','c','v','b','n','m',',','.','-',
   '0','*','0',' ');

SHIFT_CODE : array [1..55] of char=
   ('0','!','"','#','$','%','&','/','(',')','=','=',' ','0',' ','Q','W',
   'E','R','T','Y','U','I','O','P','\','+','0','0','A','S','D','F','G','H',
   'J','K','L','0','[',']','0','0','Z','X','C','V','B','N','M',';',':','_',
   '0','?');

Type
p_tty = ^tty_struct;

tty_struct=record
echo : boolean;
flush : boolean;
color : byte ;
end;

Const
  KEYBUFFLEN = 128;

procedure Setc(pos : word);
procedure Flush;

var tty_ops : file_operations ;
    tty_wait : wait_queue ;
    tty_dev : tty_struct ;

    Shift,CapsLock,Crt,Alt : boolean;

    buffer_keyb  : array[0..KEYBUFFLEN-1] of char;
    buffer_count , last_c: dword;

    keyb_ops : file_operations ;
    keyb_wait : p_tarea_struc ;
    keyb_queue_wait : wait_queue ;
    leds : byte ;

procedure tty_init;

implementation

{$I ../arch/macros.inc}



{ * Putcar :                                                            *
  *                                                                     *
  * c : Caracter                                                        *
  *                                                                     *
  * Procedimiento que imprime un caracter en la pantalla                *
  *                                                                     *
  ***********************************************************************
}
procedure putcar(c:char);
var consola : ^struc_consola ;
begin


if x > 79 then
 begin
 y += 1 ;
 x := 0 ;
end;

if y = 25 then if tty_dev.flush then flush;

consola := pointer(pointer(VIDEO_OFF)  + 160 * y + (x * 2) );

consola^.form:= tty_dev.color;
consola^.car := c;

x += 1;

Setc(y * 80 + x);
end;


{ * Setc :                                                      *
  *                                                             *
  * Procedimiento que coloca el cursor en el punto x e y        *
  *                                                             *
  ***************************************************************
}
procedure SetC(pos:word);assembler;
asm
mov bx , pos
mov dx , $3D4
mov al , $0E
out dx , al
inc dx
mov al , bh
out dx , al
dec dx
mov al , $0f
out dx , al
inc dx
mov al , bl
out dx , al
end;


{ * Flush :                                                             *
  *                                                                     *
  * Procedimiento que mueve la pantalla hacia arriba                    *
  *                                                                     *
  ***********************************************************************
}
procedure Flush;
var ult_linea : dword ;
begin
x := 0 ;
y := 24 ;

asm
mov esi , TTY_OFFSET + 160
mov edi , TTY_OFFSET
mov ecx , 24*80
rep movsw
end;
ult_linea := TTY_OFFSET + 160 * 24;
    asm
      mov eax , ult_linea
      mov edi , eax
      mov ax , 0720h
      mov cx , 80
      rep stosw
    end;
end;


{ * UpFlush :                                                           *
  *                                                                     *
  * Procedimiento que a diferencia de Flush mueve la pantalla hacia     *
  * abajo                                                               *
  *                                                                     *
  ***********************************************************************
}
procedure upflush;
var linea : dword ;
    p1 , p2 : pointer ;
begin
y := 0 ;
p1 := pointer(TTY_OFFSET + 160 * 24) ;
p2 := pointer(TTY_OFFSET + 160 * 23) ;


repeat
memcopy(p2 , p1 , 160);
p2 -= 160 ;
p1 -= 160 ;
until (p2 < pointer(TTY_OFFSET));


linea := TTY_OFFSET;
    asm
      mov eax , linea
      mov edi , eax
      mov ax , 0720h
      mov cx , 80
      rep stosw
    end;
end;

{ * Putc                                                                *
  *                                                                     *
  * Procedimiento que coloca un caracter en pantalla                    *
  *                                                                     *
  ***********************************************************************
}
procedure putc(Chr : char);
var cont : dword;
begin

if  (chr > #13) and (chr < #250) then
 begin
  putcar (chr);
  exit;
 end;

{ Caracteres  especiales }
Case Chr of

{ Algunos caracteres son simulados por ejemplo el TAB }
#9   : for cont := 1 to 9 do putcar(#32);
#10  : exit;
#252 : begin
       y += 1;

       if (y = 25) and (tty_dev.flush) then flush
        else if (y = 25 ) then y := 24 ;

       setc ( y * 80 + x);
       exit;

       end;
#251 : begin
       if (y = 0 ) then
        begin
         if (tty_dev.flush) then upflush;
        end
       else y -= 1;

       setc (y * 80 + x);
       exit;
       end;
#253 : begin
       x += 1;
       if x > 79 then x := 0 ;
       Setc (y * 80 + x);
      exit;
      end;
#250 : begin
      x -= 1;
      if x= -1 then x := 0;
      setC (y * 80 + x);
      exit;
      end;
#8 : begin
      If (x <> 0) then
       begin
       x -= 1 ;
       putcar(#0);
       x -= 1;
       setc ( y * 80 + x);
       exit;
       end;
      end;
      { Caracter de cambio de linea }
#13 : begin
      y += 1;

      If (y = 25) and (tty_dev.flush) then flush;

      setc (y * 80 + x);
      exit;
      end;
end;

end;


procedure Echo(c:char);inline;
begin
If (tty_dev.echo ) then putc(c) else exit;
end;



{ * Tty_Open :                                                          *
  *                                                                     *
  * Inodo : Puntero al inodo                                            *
  * Fichero : Puntero al descriptor del archivo                         *
  * Retorno : 0 si fue correcto o -1 sino                               *
  *                                                                     *
  * Funcion que se encarga de la apertura de la terminal                *
  *                                                                     *
  ***********************************************************************
}
function tty_open ( Inodo : p_Inode_t ; Fichero : p_file_t ) : dword ;
var flags : dword ;
begin
cerrar ;

{ el curso se posiciona al pie de la pantalla }
Fichero^.f_pos := 24 * 160 + 2 ;

abrir;
exit(0);
end;



{ * Tty_Seek :                                                          *
  *                                                                     *
  * Fichero : Puntero al descriptor de archivo                          *
  * whence : Algoritmo a utilizar                                       *
  * offset : Nueva posicion                                             *
  * Retorno : Nueva posicion del archivo                                *
  *                                                                     *
  * Funcion que realiza el posicionamiento sobre la tty                 *
  *                                                                     *
  ***********************************************************************
}
function tty_seek(Fichero : p_file_t ; whence  , offset : dword ): dword ;
var off :dword ;
begin
off := offset ;
off *= 2;
Case whence of
SEEK_SET: If (offset > Scree_Size) then exit(-1)
          else Fichero^.f_pos := off ;
SEEK_CUR: If (Fichero^.f_pos + offset > Scree_Size) then exit(-1)
          else Fichero^.f_pos += off ;
SEEK_EOF: exit(-1);
end;
exit(Fichero^.f_pos);
end;


{ * Tty_Write :                                                         *
  *                                                                     *
  * Fichero : Puntero al descriptor del fichero                         *
  * count : Contador                                                    *
  * buff : Buffer donde se toman los datos                              *
  * Retorno : Numero de bytes escritos                                  *
  *                                                                     *
  * Funcion que escribe sobre la tty                                    *
  *                                                                     *
  ***********************************************************************
}
function tty_write (Fichero : p_file_t ; count : dword ; buff : pointer ) : dword ;
var cont , flags :dword;
    c : ^char ;
begin

tty_lock ;

x := (fichero^.f_pos div 2)   mod 80 ;
y := (Fichero^.f_pos div 2)   div 80 ;

{ Contador de caracteres }
cont:=0;

{ Puntero al buffer de usuario }
c := buff ;

{ Comienza la transferencia }

repeat
putc(c^);
cont +=1;
c += 1;


until (count = cont);

{ Nueva posicion }
Fichero^.f_pos := y * 160 + x * 2;

Setc(y * 80 + x);

{ Liberar el dispositivo }
tty_unlock;

exit(count)
end;




{ * Tty_Ioctl :                                                         *
  *                                                                     *
  * Fichero : Puntero a un desc. de archivo                             *
  * req : Comando                                                       *
  * argp : Puntero a los argumentos                                     *
  * Retorno : -1 si falla o 0 sino                                      *
  *                                                                     *
  * Llamada de control a la tty                                         *
  *                                                                     *
  ***********************************************************************
}
function tty_ioctl (Fichero : p_file_t ; req : dword ; argp : pointer ) : dword ;
var r:p_tty;
begin

If argp = nil then exit(-1);

case req of
IO_SET_TTY_TORO : begin
                  r := argp ;
                  tty_dev.flush := r^.flush;
                  tty_dev.echo := r^.echo ;
                  tty_dev.color :=r^.color;
                  exit(0);
                  end;
IO_GET_TTY_TORO:  begin
                  memcopy(@tty_dev,argp,sizeof(tty_dev));
                  exit(0);
                  end;

end;
exit(-1);
end;



{ * Procedimiento que espera a que el teclado este escuchando * }

procedure wait_keyboard;
var tmp : byte ;
begin

tmp := leer_byte($64);

while ((tmp and 2) = 1 ) do tmp := leer_byte ($64);

end;



{ * Procedimiento que coloca los bits de los leds de acuerdo a la variable leds * }

procedure set_leds;
begin

wait_keyboard ;
enviar_byte ($ED , $60);

wait_keyboard ;
enviar_byte (leds , $60);

wait_keyboard ;
end;


{ * Keyb_Open :                                                         *
  *                                                                     *
  * Inodo : Puntero al inodo                                            *
  * Fichero : Puntero al descriptor                                     *
  * Retorno : 0 si fue correcto o -1 sino                               *
  *                                                                     *
  * Esta funcion es solo por convencionalismos siempre es correcta      *
  *                                                                     *
  ***********************************************************************
}
function Keyb_Open(Inodo : p_inode_t ; Fichero : p_file_t ) : dword ;
begin
exit(0);
end;



procedure Keyb_Irq;interrupt;
var code ,key : byte;
    p : pchar ;

label reanudar;
begin

{el hecho q habilite las irq puede hacer q pierda teclas si son muy
sucesivas y rapidas}

abrir ;
enviar_byte ($20,$20);

 while (leer_byte($64) and 1) = 1 do
  begin

  code := leer_byte($60);

  key := 127 and code;

   {Son generadas dos irq una cuando se pulsa y otra cuando se suelta}
   {yo quiero cuando se suelta}

    {Teclas especiales}
    If (code and 128) <> 0 then
     begin
      case key of
       KbShift:shift := false;
       KbCrtl: Crt := false;
      end;
     end
   else
     begin

        {Se realiza la identificacion de la tecla}
        {Teclas especiales que no usan buffer}
        case key of
         KbCrtl: Crt := true;
         KbShift: Shift := true;
         KbCapsLock : begin
                      CapsLock := not (CapsLock) ;
                      leds := leds or 4;
                      set_leds;
                     end;
         else
          begin
              p := @buffer_keyb[buffer_count];
              Inc(buffer_count);
              buffer_count := buffer_count mod KEYBUFFLEN;


           {Caracteres que necesitan el buffer}
           case key of
            KbBkSpc : begin
                       echo(#8);
                       p^ := #8 ;
                       goto reanudar;
                      end;
            KbEnter : begin
                        echo(#13);
                        p^ := #13;
                        goto reanudar;
                      end;
            KbLeft : begin
                       echo(#250);
                       p^ := #250 ;
                     end;
              Kbup : begin
                       echo(#251);
                       p^ := #251 ;
                     end;
            Kbdown : begin
                       echo (#252);
                       p^:= #252 ;
                       goto reanudar ;
                     end;
          KbRigth : begin
                      echo(#253);
                      p^ := #253 ;
                      goto reanudar;
                    end;
         else
          begin

           If (Shift or CapsLock) then p^ := Shift_Code[key]
            else p^ := Char_Code[key];

           {Se muestra en pantalla}
           echo(p^);

           {Se despierta al proceso en wait}
           reanudar:
           Proceso_Reanudar (keyb_wait , keyb_wait);
          end;
      end;
   end;
end;
end;

end;
end;


{ * Keyb_Read :                                                         *
  *                                                                     *
  * Fichero : Puntero al descriptor de file                             *
  * count : Contador de bytes                                           *
  * buff : Puntero donde sera escrito                                   *
  *                                                                     *
  * Funcion que se encarga de la lectura desde el teclado su procesamie *
  * ento deve ser lo mas rapido posible puesto que las IRQ  de teclado  *
  * se suceden muy rapidamente                                          *
  *                                                                     *
  ***********************************************************************
}
function keyb_read (Fichero : p_file_t ; count : dword ; buff : pointer ): dword ;
begin
  Result := 0;
  if not Verify_User_Buffer(pointer(buff+count)) then
    Exit;
  keyb_lock;
  while true do
  begin
    If buffer_count = last_c then
      Proceso_Interrumpir (Tarea_Actual , keyb_wait) ;
    while (last_c < buffer_count) and (Result < count) do
    begin
      Inc(Result);
      if buffer_keyb[last_c] = #13 then
        buffer_keyb[last_c] := #10;
      memcopy (@buffer_keyb[last_c] , buff , 1);
      Inc(last_c);
      last_c := last_c mod KEYBUFFLEN;
      Inc(buff);
      if buffer_keyb[last_c-1] = #10 then
        Break;
    end;
    if (count = Result) or (buffer_keyb[last_c-1] = #10) then
    begin
      keyb_unlock;
      Exit;
    end;
  end;
end;


function keyb_ioctl ( Fichero : p_file_t ; req : dword ; argp : pointer ) : dword ;
begin
exit(-1);
end;




{ * Tty_Init :                                                  *
  *                                                             *
  * Proceso que inicializa la Terminal                          *
  *                                                             *
  ***************************************************************
}
procedure tty_init;
begin
printkf('/nIniciando tty0 ... /VOk\n',[]);

tty_ops.write := @tty_write ;
tty_ops.read :=  nil ;
tty_ops.seek :=  @tty_seek;
tty_ops.ioctl := @tty_ioctl;
tty_ops.open :=  @tty_open ;

Register_ChrDev(TTY_MAYOR , 'tty', @tty_ops);
tty_Wait.lock := false ;
tty_wait.lock_wait := nil;

tty_dev.echo := true ;
tty_dev.flush := true ;
tty_dev.color := $7;


{ se pasa al registro del teclado !! }

printkf('/nIniciando keyb0 ... /VOk\n',[]);

keyb_ops.seek := nil ;
keyb_ops.open := @keyb_open;
keyb_ops.write := nil ;
keyb_ops.read := @keyb_read ;
keyb_ops.ioctl := @keyb_ioctl;

Register_Chrdev(Keyb_Mayor,'keyb',@keyb_ops);

keyb_wait := nil ;

leds := 0 ;
set_leds;

buffer_count := 0 ;
last_c := 0 ;

Wait_Short_Irq(1,@Keyb_Irq);
end;

end.
