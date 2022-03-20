// sh.pas
//
// This is a simple shell with built-in and external commands based on exec().
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

const root : PChar = '/'#0 ;
      version = '1' ;
      subversion = '3';
      binpath : PChar = '/BIN/'#0;

var
  cmd: array[0..254] of char;
  args: array[0..254] of char;
  currpathbuff: array[0..254] of char;
  currpath: PChar = @currpathbuff[0];

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
    // TODO: replace with strcpy()
    for i:= 0 to count-1 do
    begin
      cmd[i] := buff[i];
    end;
    cmd[count] := #0;
    Inc(pbuff);
    i := 0;
    // TODO: replace with strcpy()
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
  Result := True;
  err := Exec(cmd, args);
  if err = 0 Then
  begin
    Result := False;
    Exit;
  end;
  WaitPid(err);
end;

function DoCdCmd(args: PChar): Boolean;
var
  i: LongInt;
  p: PChar;
begin
  Result := true;
  if args^ = #0 then
    Exit;
  if args^ = '/' then
  begin
    chdir(args);
  end else if args = '.' then
  begin
    writeln(currpath)
  end else if args = '..' then
  begin
    if currpath <> '/' then
    begin
      i := strlen(currpath) - 1;
      currpath[i] := #0;
      p := strrscan(currpath, '/');
      Inc(p);
      p^ := #0;
      chdir(currpath);
      // TODO: check ioresult
      i := IOResult;
    end;
  end else
  begin
    strcat(currpath, args);
    strcat(currpath,'/');
    chdir(currpath);
  end;
end;

function DoBinCmd(cmd, args: PChar): Boolean;
var
  buff: array[0..255] of Char;
begin
  buff[0] := #0;
  strcat(Pchar(@buff[0]), binpath);
  strcat(Pchar(@buff[0]), cmd);
  Result := ExecCmd(@buff[0], args);
end;

function DoCmd(cmd: PChar; args: PChar): Boolean;
begin
  Result := true;
  if cmd = 'cd' then
    Result := DoCdCmd(args)
  else if cmd = 'ver' then
    Writeln('Shell ', version, '.', subversion)
  else
    Result := DoBinCmd(cmd, args);
end;

begin
  strcopy(currpath, root);
  writeln('Shell ', version, '.', subversion);
  write('$', currpath);
  while true do
  begin
    GetCmdAndArgs(@cmd, @args);
    ttygotoxy(1, 25);
    if not DoCmd(@cmd, @args) then
      Writeln('Command unknown');
    write('$', currpath);
  end;
end.
