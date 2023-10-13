//
// tty.pas
//
// This unit implements a driver for the keyboard and the screen.
// The support for the keyboard is minimal. It implements a ringbuffer
// that copies keys from hardware and then copies from the ringbuffer to
// the user.
//
// Copyright (c) 2003-2023 Matias Vara <matiasevara@torokernel.io>
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

const

  TTY_OFFSET = $B8000;
  Scree_Size = 4000;
  TTY_NR_MAJOR = 31;

  IO_SET_TTY_TORO = 1;
  IO_GET_TTY_TORO = 2;

  CHAR_PER_LINE = 80;
  KEYB_PORT = $60;
  KEYB_NR_MAJOR = 32;

  Kbesc = 1;
  Kbenter = 28;
  Kbleft = 75;
  Kbrigth = 77;
  kbSpace = 57;
  KbBkSpc = 14;
  kbUp = 72 ;
  kbdown = 80 ;
  KbCrtl = 29;
  KbAlt = 56;
  KbCapsLock = 58;
  KbShift = 42;
  kbF1 = $3B;
  kbF2 = $3C;
  kbF3 = $3D;
  kbF4 = $3E;
  kbF5 = $3F;
  kbF6 = $40;
  kbF7 = $41;
  kbF8 = $42;
  kbF9 = $43;
  kbF10 = $44;
  kbF11 = $85;
  kbF12 = $86;

  SHIFT_CODE : array [1..55] of char =
     ('0','!','"','#','$','%','&','/','(',')','=','=',' ','0',' ','Q','W',
      'E','R','T','Y','U','I','O','P','\','+','0','0','A','S','D','F','G','H',
      'J','K','L','0','[',']','0','0','Z','X','C','V','B','N','M',';',':','_',
      '0','?');

type
  p_tty = ^tty_struct;

  tty_struct=record
    flush: boolean;
    color: byte;
    x, y: byte;
  end;

const
  KEYBUFLEN = 1024;

procedure SetCursor(Offset : word);
procedure TtyInit;

var
  tty_ops: file_operations;
  tty_wait: wait_queue;
  tty_dev: tty_struct;

  KeybRingBuffer: array[0..KEYBUFLEN-1] of char;
  IdxRead, IdxWriter: DWORD;

  keyb_ops: file_operations;
  keyb_wait: p_tarea_struc;
  keyb_queue_wait: wait_queue;

implementation

{$I ../arch/macros.inc}

// Keys are handled by a ring-buffer
function EnqueueKey(Key: Char): Boolean;
begin
  Result := False;
  if (IdxWriter + 1) mod KEYBUFLEN = IdxRead mod KEYBUFLEN then
    Exit;
  KeybRingBuffer[IdxWriter mod KEYBUFLEN] := Key;
  Inc(IdxWriter);
  Result := True;
end;

function DequeueKey(out c: Char): Boolean;
begin
  Result := False;
  if IdxRead = IdxWriter then
    Exit;
  c := KeybRingBuffer[IdxRead];
  Inc(IdxRead);
  Result := True;
end;

// Move screen up one line
procedure ScrollDown;
var
  ult_linea : dword ;
begin
  x := 0;
  y := 24;
  asm
     mov esi , TTY_OFFSET + CHAR_PER_LINE * 2
     mov edi , TTY_OFFSET
     mov ecx , 24 * CHAR_PER_LINE
     rep movsw
  end;
  ult_linea := TTY_OFFSET + CHAR_PER_LINE * 2 * 24;
  asm
    mov eax , ult_linea
    mov edi , eax
    mov ax , 0720h
    mov cx , CHAR_PER_LINE
    rep stosw
  end;
end;

// Move screen down one line
procedure ScrollUp;
var
  line: DWORD;
  p1, p2: Pointer;
begin
  y := 0;
  p1 := pointer(TTY_OFFSET + CHAR_PER_LINE * 2 * 24);
  p2 := pointer(TTY_OFFSET + CHAR_PER_LINE * 2 * 23);
  repeat
    memcopy(p2, p1, CHAR_PER_LINE * 2);
    p2 -= CHAR_PER_LINE * 2;
    p1 -= CHAR_PER_LINE * 2;
  until p2 < pointer(TTY_OFFSET);
  line := TTY_OFFSET;
  asm
    mov eax , line
    mov edi , eax
    mov ax , 0720h
    mov cx , CHAR_PER_LINE
    rep stosw
  end;
end;

procedure WriteChar(c: Char);
var
  Console: ^struc_consola;
begin
  if x > 79 then
  begin
    Inc(y);
    x := 0;
  end;
  if y > 24 then
    if tty_dev.flush then
      ScrollDown;
  Console := Pointer(Pointer(VIDEO_OFF)  + CHAR_PER_LINE * y * 2 + x * 2);
  Console^.form := tty_dev.color;
  Console^.car := c;
  Inc(x);
  SetCursor(y * CHAR_PER_LINE + x);
end;

procedure SetCursor(Offset: Word);
begin
  enviar_byte($0e, $3d4);
  enviar_byte((Offset and $ff00) shr 8, $3d5);
  enviar_byte($0f, $3d4);
  enviar_byte(byte(Offset and $ff), $3d5);
end;

procedure WriteCharF(c: Char);
begin
  case c of
    #8  : begin
            If x > 0 then
            begin
              Dec(x);
              WriteChar(#0);
              Dec(x);
            end;
          end;
    #13 : begin
            Inc(y);
            If (y > 24) and (tty_dev.flush) then
              ScrollDown;
          end;
  end;
end;

procedure WriteChars(c: PChar; Count: DWORD);
var
  j: LongInt;
begin
  for j := 0 to Count-1 do
  begin
    if  (c[j] > #13) and (c[j] < #250) then
      WriteChar(c[j])
    else
      WriteCharF(c[j]);
  end;
  SetCursor (y * CHAR_PER_LINE + x);
end;


function TtyOpen(Inodo: p_Inode_t; fd: p_file_t): DWORD;
begin
  cerrar;
  fd^.f_pos := 24 * CHAR_PER_LINE * 2 + 2;
  abrir;
  Result := 0;
end;

function TtySeek(fd: p_file_t; whence, offset: dword ): dword ;
var
  off :dword ;
begin
  off := offset ;
  off *= 2;
  Case whence of
  SEEK_SET: If (offset > Scree_Size) then exit(-1)
          else fd^.f_pos := off;
  SEEK_CUR: If (fd^.f_pos + offset > Scree_Size) then exit(-1)
          else fd^.f_pos += off;
  SEEK_EOF: exit(-1);
  end;
  Result := fd^.f_pos;
end;

function TtyWrite(fd: p_file_t; count: DWORD; buf: pointer): DWORD;
begin
  tty_lock ;
  x := (fd^.f_pos div 2) mod CHAR_PER_LINE;
  y := (fd^.f_pos div 2) div CHAR_PER_LINE;
  WriteChars(PChar(buf), count);
  fd^.f_pos := y * CHAR_PER_LINE * 2 + x * 2;
  tty_unlock;
  Result := count;
end;

function TtyIoctl(fd: p_file_t; req: dword; argp: pointer): DWORD;
var
  r: p_tty;
begin
  Result := -1;
  If argp = nil then
    Exit;
  case req of
  IO_SET_TTY_TORO : begin
                      r := argp ;
                      tty_dev.flush := r^.flush;
                      tty_dev.color :=r^.color;
                      Result := 0;
                    end;
  IO_GET_TTY_TORO:  begin
                      tty_dev.x := x;
                      tty_dev.y := y;
                      memcopy(@tty_dev,argp,sizeof(tty_dev));
                      Result := 0;
                    end;
  end;
end;

function KeybOpen(Inodo: p_inode_t; Fichero: p_file_t): DWORD;
begin
  Result := 0;
end;

procedure KeybIrqHandler; Interrupt;
begin
  while (leer_byte($64) and 1) = 1 do
  begin
    if not EnqueueKey(Char(leer_byte($60))) then
      printkf('keyb: ring buffer is full!\n', []);
    Proceso_Reanudar (keyb_wait , keyb_wait);
  end;
  // send EOI
  enviar_byte ($20, $20);
end;

function KeybRead(fd: p_file_t; count: DWORD; buf: Pointer): DWORD;
var
  c: Char;
begin
  Result := 0;
  if not Verify_User_Buffer(Pointer(buf + count)) then
    Exit;
  keyb_lock;
  while count > 0 do
  begin
    while not DequeueKey(c) do
      Proceso_Interrumpir (Tarea_Actual, keyb_wait);
    memcopy(@c, buf, sizeof(Char));
    Dec(count);
    Inc(Result);
  end;
  keyb_unlock;
end;

function KeybIOctl(Fichero: p_file_t; req: DWORD; argp: pointer): DWORD;
begin
  Result := 0;
end;

procedure TtyInit;
begin
  printkf('/nInitializing tty0 ... /VOk\n',[]);

  tty_ops.write := @TtyWrite;
  tty_ops.read := nil;
  tty_ops.seek := @TtySeek;
  tty_ops.ioctl := @TtyIoctl;
  tty_ops.open := @TtyOpen;

  Register_ChrDev(TTY_NR_MAJOR, 'tty', @tty_ops);

  tty_Wait.lock := false;
  tty_wait.lock_wait := nil;

  tty_dev.flush := true;
  tty_dev.color := $7;

  printkf('/nInitializing keyb0 ... /VOk\n',[]);

  keyb_ops.seek := nil;
  keyb_ops.open := @KeybOpen;
  keyb_ops.write := nil;
  keyb_ops.read := @KeybRead;
  keyb_ops.ioctl := @KeybIOctl;

  Register_Chrdev(KEYB_NR_MAJOR,'keyb',@keyb_ops);

  keyb_wait := nil;

  IdxRead := 0;
  IdxWriter := 0;

  Wait_Short_Irq(1, @KeybIrqHandler);
end;

end.
