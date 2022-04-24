//
// ls.pas
//
// This application shows how ls is implemented in ToroOS.
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

uses crt, strings;
const
  cdir : PChar = '.'#0 ;

type
preaddir_entry = ^readdir_entry ;

readdir_entry = record
name : string ;
ino : dword ;
end;

p_inode_tmp = ^inode_tmp;
inode_tmp = packed record
  ino      : dword;
  mayor    : byte;
  menor    : byte;
  rmayor   : byte;
  rmenor   : byte;
  count    : byte;
  state    : byte;
  mode     : dword;
  atime    : dword;
  ctime    : dword;
  mtime    : dword;
  dtime    : dword;
  nlink    : word;
  flags     : dword;
  size     : dword;
  blksize  : dword;
  blocks   : dword;
end;

var
  st: inode_tmp;
  fd, count: LongInt;
  buf: readdir_entry;
  name: array[0..255] of Char;
  path: array[0..255] of Char;
begin
  If ParamCount < 1 then
    strcopy(@path[0], cdir)
  else
    strpcopy(@path[0], ParamStr(0));
  if Stat(@path[0], Pointer(@st)) < 0 then
    Exit;
  if st.mode and 4 <> 4 then
    Exit;
  fd := open(@path[0], O_RDONLY, 0);
  while true do
  begin
    count := do_read(fd, Pointer(@buf), sizeof(buf));
    if count = 0 then 
      break;
    // TODO: there is a bug in which empty directories are shown when reading
    // for the moment, just ignore them
    if byte(buf.name[0]) = 0 then
      continue;
    StrPCopy(@name[0], buf.name);
    ttygotoxy(1, 25);
    WriteLn(PChar(@name[0]));
  end;
  //do_close(fd);
end.
