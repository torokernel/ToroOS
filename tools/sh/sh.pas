//
// sh.pas
//
// This is a shell with built-in and external commands based on exec().
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

{$ASMMODE INTEL}
{$I-}

uses Strings, crt;

const root : PChar = '/'#0 ;
      version = '1' ;
      subversion = '3';
      binpath : PChar = '/BIN/'#0;
      BUFF_PATH_SIZE = 255;

var
  cmd: array[0..BUFF_PATH_SIZE-1] of char;
  args: array[0..BUFF_PATH_SIZE-1] of char;
  currpathbuff: array[0..BUFF_PATH_SIZE-1] of char;
  currpath: PChar = @currpathbuff[0];

procedure GetCmdAndArgs(cmd: PChar; args: PChar);
var
  buff: array[0..BUFF_PATH_SIZE-1] of char;
  pbuff: PChar;
  count, i: LongInt;
begin
  readln(buff);
  count := 0;
  pbuff := @buff[0];
  while (count < BUFF_PATH_SIZE) and (pbuff^ <> #0) and (pbuff^ <> #32) do
  begin
    Inc(count);
    Inc(pbuff);
  end;
  if pbuff^ = #32 then
  begin
    strlcopy(cmd, buff, count);
    Inc(pbuff);
    i := 0;
    strlcopy(args, pbuff, BUFF_PATH_SIZE);
  end else if pbuff^ = #0 then
  begin
    strlcopy(cmd, buff, count);
    args^ := #0;
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
  i, err: LongInt;
  p: PChar;
  tmp: Char;
begin
  Result := true;
  if args^ = #0 then
  begin
    chdir(root);
    strcopy(currpath, root);
  end else if args^ = '/' then
  begin
    chdir(args);
    err := IOResult;
    if err = 0 then
      strcopy(currpath, args)
    else
      Result := false;
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
      tmp := p^;
      p^ := #0;
      chdir(currpath);
    end;
  end else
  begin
    i := strlen(currpath);
    strcat(currpath, args);
    strcat(currpath,'/');
    chdir(currpath);
    err := IOResult;
    if err <> 0 then
    begin
       Result := false;
       currpath[i] := #0;
    end;
  end;
end;

function DoBinCmd(cmd, args: PChar): Boolean;
var
  buff: array[0..BUFF_PATH_SIZE-1] of Char;
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
    if not DoCmd(@cmd, @args) then
      Writeln('Command unknown');
    write('$', currpath);
  end;
end.
