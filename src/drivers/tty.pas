//
// tty.pas
//
// This unit contains functions to access the terminal.
// 
// Copyright (c) 2003-2022 Matias Vara <matiasevara@gmail.com>
// All Rights Reserved
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
Unit tty;

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

IO_SET_TTY_TORO = 1;
IO_GET_TTY_TORO = 2;


KEYB_PORT=$60;
KEYB_MAYOR = 32 ;


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

procedure putc(Chr : char);
var cont : dword;
begin

if  (chr > #13) and (chr < #250) then
 begin
  putcar (chr);
  exit;
 end;

Case Chr of

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


function tty_open ( Inodo : p_Inode_t ; Fichero : p_file_t ) : dword ;
var flags : dword ;
begin
cerrar ;

Fichero^.f_pos := 24 * 160 + 2 ;

abrir;
exit(0);
end;

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

function tty_write (Fichero : p_file_t ; count : dword ; buff : pointer ) : dword ;
var cont , flags :dword;
    c : ^char ;
begin

tty_lock ;

x := (fichero^.f_pos div 2)   mod 80 ;
y := (Fichero^.f_pos div 2)   div 80 ;

cont:=0;

c := buff ;

repeat
putc(c^);
cont +=1;
c += 1;


until (count = cont);

Fichero^.f_pos := y * 160 + x * 2;

Setc(y * 80 + x);

tty_unlock;

exit(count)
end;

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

procedure wait_keyboard;
var tmp : byte ;
begin

tmp := leer_byte($64);

while ((tmp and 2) = 1 ) do tmp := leer_byte ($64);

end;



procedure set_leds;
begin

wait_keyboard ;
enviar_byte ($ED , $60);

wait_keyboard ;
enviar_byte (leds , $60);

wait_keyboard ;
end;


function Keyb_Open(Inodo : p_inode_t ; Fichero : p_file_t ) : dword ;
begin
exit(0);
end;



procedure Keyb_Irq;interrupt;
var code ,key : byte;
    p : pchar ;

label reanudar;
begin

abrir ;
enviar_byte ($20,$20);

 while (leer_byte($64) and 1) = 1 do
  begin

  code := leer_byte($60);

  key := 127 and code;

    If (code and 128) <> 0 then
     begin
      case key of
       KbShift:shift := false;
       KbCrtl: Crt := false;
      end;
     end
   else
     begin

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

           echo(p^);

           reanudar:
           Proceso_Reanudar (keyb_wait , keyb_wait);
          end;
      end;
   end;
end;
end;

end;
end;


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

procedure tty_init;
begin
printkf('/nInitializing tty0 ... /VOk\n',[]);

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


printkf('/nInitializing keyb0 ... /VOk\n',[]);

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
