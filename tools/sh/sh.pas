// sh.pas
//
// This application shows how a shell is implemented in ToroOS.
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

var err : dword;
    cmd: array[0..254] of char;
    fullcmd: array[0..254] of char;
    dir: array[0..254] of char;
    p, s, a: Pchar;

const root : pchar = '/' ;
      version = '1' ;
      subversion = '3';
      binpath = '/BIN/';

begin
  fillbyte(dir, 0, 255); //this is not working
  fillbyte(fullcmd, 0, 254); //this is not working
  fillbyte(cmd, 0, 254); //this is not working
  dir[0]:= '/';
  writeln('Shell ', version, '.', subversion);
  write('root:', dir);
  while true do
  begin
    readln(fullcmd); 
    p := @fullcmd[0];
    s := @cmd[0];
    a := @dir[0];

    while (p^ <> #32) and (p^ <> #0) do
    begin
      s^ := p^;
      Inc(s);    
      Inc(p);
    end;

    s^ := #0;

    if p^ = #32 then
    begin
      Inc(p);
      while p^ <> #0 do
      begin
        a^ := p^;
        Inc(a);
        Inc(p);
      end;
      a^ := #0;
    end;

    if cmd = 'cd' then
    begin
      chdir(@dir[0]);
    end else
    begin
      err := Exec(cmd, nil);
      ttygotoxy(1, 25);
      if err = 0 then 
        writeln('command not found: ', cmd)
      else 
        waitpid(err);
    end;
    
    ttygotoxy(1, 25);
    write('root:', dir);
  end;
end.
