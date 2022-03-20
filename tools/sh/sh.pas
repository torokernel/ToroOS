// sh.pas
//
// This is a simple shell with built-in and external commands.
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

{$ASMMODE INTEL}
{$I-}

uses Strings, crt;

var cmd: array[0..254] of char;
    args: array[0..254] of char;
    currpath: array[0..254] of char;

const root : pchar = '/' ;
      version = '1' ;
      subversion = '3';
      binpath = '/BIN/';

// TODO: backspace is not working
procedure GetCmdAndArgs(cmd: PChar; args: PChar);
var
  buff: array[0..255] of char;
  pbuff: PChar;
  count, i: LongInt;
begin
  readln(buff);
  count := 0;
  pbuff := @buff[0];
  while (count < 255) and (pbuff^ <> #0) and (pbuff^ <> #32) do
  begin
    Inc(count);
    Inc(pbuff);
  end;
  if pbuff^ = #32 then
  begin
    for i:= 0 to count-1 do
    begin
      cmd[i] := buff[i];
    end;
    cmd[count] := #0;
    Inc(pbuff);
    i := 0;
    while (pbuff^ <> #0) and (count < 255) do
    begin
      args[i] := pbuff^;
      Inc(pbuff);
      Inc(i);
      Inc(count);
    end;
    args[i] := #0;
  end else if pbuff^ = #0 then
  begin
    for i:= 0 to count-1 do
    begin
      cmd[i] := buff[i];
    end;
    cmd[count] := #0;
    args[0] := #0;
  end;
end;

function ExecCmd(cmd: PChar; args: PChar): Boolean;
var
  err: DWord;
begin
  Result := False;
  err := Exec(cmd, args);
  if err = 0 Then
  begin
    Result := false;
    Exit;
  end;
  WaitPid(err);
end;

function DoCdCmd(args: PChar): Boolean;
begin
  if args^ = #0 then
    Exit;
  // si el argumento con una barra al principio  es absoluto
  // entonces cambiamos el dir actual y eliminamos el historia
  // si no comienza con la barra es relativo
  // primero creas un buffer con la copia de actual mas el nuevo
  // cambias el directorio
  // si es succesfull entonces guardas el buffer como nuevo curr path
  chdir(args);
end;

function DoCmd(cmd: PChar; args: PChar): Boolean;
begin
  Result := true;
  if cmd = 'cd' then
    Result := DoCdCmd(args)
  else if cmd = 'ver' then
    Writeln('version command')
  else
    Result := ExecCmd(cmd, args);
end;

begin
  currpath[0]:= '/';
  writeln('Shell ', version, '.', subversion);
  write('$', currpath);
  while true do
  begin
    GetCmdAndArgs(@cmd, @args);
    ttygotoxy(1, 25);
    if not DoCmd(@cmd, @args) then
      Writeln('Command unknow');
    write('$', currpath);
  end;
end.
