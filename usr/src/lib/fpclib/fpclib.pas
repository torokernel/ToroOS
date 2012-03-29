unit fpclib;

{******************************************************************************
 *  stdio.pp
 *
 *  DelphineOS fpc library. It has to define a lot of functions that are used
 *  by the Free Pascal Compiler.
 *
 *  Functions defined (for the moment) :
 *
 *  - FPC_SHORTSTR_COPY   : OK
 *  - FPC_INITIALIZEUNITS : NOT DONE
 *  - FPC_DO_EXIT         : NOT DONE
 *
 *  CopyLeft 2002 GaLi
 *
 *  version 0.0  - 24/12/2001  - GaLi - Initial version
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *****************************************************************************}




INTERFACE

 {$I ../../include/head/asm.h}

IMPLEMENTATION


procedure Move(const source;var dest;count:longint);[public , alias : '_SYSTEM$$_MOVE$$$$$$$$$LONGINT'];
//type
//  bytearray    = array [0..maxlongint] of byte;
var
  i,size : longint;
begin
//  Dec(count);
//  for i:=0 to count do
//         bytearray(dest)[i]:=bytearray(source)[i];
end;


procedure int_strconcat(s1,s2:pointer);[public,alias:'FPC_SHORTSTR_CONCAT'];
var
  s1l, s2l : byte;
type
  pstring = ^string;
begin
  if (s1=nil) or (s2=nil) then
    exit;
  s1l:=length(pstring(s1)^);
  s2l:=length(pstring(s2)^);
  if s1l+s2l>255 then
    s1l:=255-s2l;
  move(pstring(s1)^[1],pstring(s2)^[s2l+1],s1l);
  //pstring(s2)^[0]:=chr(s1l+s2l);
end;

procedure Init_System;[public, alias : 'INIT$$SYSTEM'];
begin
end;

{***********************************************************************************
 * int_strcopy
 *
 * Input  : string length, pointer to source and destination strings
 * Output : None
 *
 * This procedure is ONLY used by the Free Pascal Compiler
 **********************************************************************************}
procedure int_strcopy (len : dword ; sstr, dstr : pointer); assembler; [public, alias : 'FPC_SHORTSTR_COPY'];
asm
   push   eax
   push   ecx
   cld

   mov    edi, dstr
   mov    esi, sstr
   mov    ecx, len
   rep    movsb

   pop    ecx
   pop    eax
end;



{******************************************************************************
 * init
 *
 * This procedure is ONLY used by the FreePascal Compiler
 *****************************************************************************}
procedure initialize_units; [public, alias : 'FPC_INITIALIZEUNITS'];
begin
end;



{******************************************************************************
 * do_exit
 *
 * This procedure is used by the FreePascal Compiler
 *****************************************************************************}
procedure do_exit; [public, alias : 'FPC_DO_EXIT'];
begin
end;



Procedure fillchar(var x;count:longint;value:byte);[public];
//type
//  longintarray = array [0..maxlongint] of longint;
 // bytearray    = array [0..maxlongint] of byte;
var
  i,v : longint;
begin
  if count = 0 then exit;
  v := 0;
  v:=(value shl 8) or (value and $FF);
  v:=(v shl 16) or (v and $ffff);
 // for i:=0 to (count div 4) -1 do
 //   longintarray(x)[i]:=v;
 // for i:=(count div 4)*4 to count-1 do
 //   bytearray(x)[i]:=value;
end;




procedure int_strcmp (dstr, sstr : pointer); assembler; [public, alias : 'FPC_SHORTSTR_COMPARE'];
asm
   cld
   xor   ebx, ebx
   xor   eax, eax
   mov   esi, sstr
   mov   edi, dstr
   mov   al , [esi]
   mov   bl , [edi]
   inc   esi
   inc   edi
   cmp   eax, ebx   { Same length ? }
   jne   @Fin
   mov   ecx, eax
   rep   cmpsb
@Fin:
end;


function strchararray(p:pchar; l : longint):shortstring;[public,alias:'FPC_CHARARRAY_TO_SHORTSTR'];
var
 s: shortstring;
begin
  if l>=256 then
    l:=255
  else if l<0 then
    l:=0;
  move(p^,s[1],l);
//  s[0]:=chr(l);
//  strchararray := s;
end;






procedure str_to_chararray(strtyp, arraysize: longint; src,dest: pchar);[public,alias:'FPC_STR_TO_CHARARRAY'];
type
  plongint = ^longint;
var
  len: longint;
begin
  case strtyp of
    { shortstring }
    0:
      begin
        len := byte(src[0]);
        inc(src);
      end;
{$ifdef SUPPORT_ANSISTRING}
    { ansistring}
    1: len := length(ansistring(pointer(src)));
{$endif SUPPORT_ANSISTRING}
    { longstring }
    2:;
    { widestring }
    3:;
  end;
  if len > arraysize then
    len := arraysize;
  { make sure we don't dereference src if it can be nil (JM) }
  if len > 0 then
    move(src^,dest^,len);
    fillchar(dest[len],arraysize-len,0);
end;


function strpas(p:pchar):shortstring;[public,alias:'FPC_PCHAR_TO_SHORTSTR'];
var
  l : longint;
  s: shortstring;
begin
  if p=nil then
    l:=0
  else
//    l:=strlen(p);
  if l>255 then
    l:=255;
  if l>0 then
    move(p^,s[1],l);
  //s[0]:=chr(l);
//  strpas := s;
end;

function strlen(p:pchar):longint;[public , alias :'_SYSTEM$$_STRLEN$PCHAR'];
var i : longint;
begin
  i:=0;
  while p[i]<>#0 do inc(i);
  exit(i);
end;


function strcomp(str1,str2:pchar):boolean;[public , alias :'STRCOMP'];
begin
while (str1^ <> #0) or (str2^ <> #0) do
 begin
 If str1^ <> str2^ then exit(false);
 str1+=1;
 str2+=1;
end;
exit(true);
end;




Function InitVal(const s:shortstring;var negativ:boolean;var base:byte):ValSInt;
var
  Code : Longint;
begin
{Skip Spaces and Tab}
  code:=1;
  while (code<=length(s)) and (s[code] in [' ',#9]) do
   inc(code);
{Sign}
  negativ:=false;
  case s[code] of
   '-' : begin
           negativ:=true;
           inc(code);
         end;
   '+' : inc(code);
  end;
{Base}
  base:=10;
  if code<=length(s) then
   begin
     case s[code] of
      '$' : begin
              base:=16;
              repeat
                inc(code);
              until (code>=length(s)) or (s[code]<>'0');
            end;
      '%' : begin
              base:=2;
              inc(code);
            end;
     end;
  end;
  InitVal:=code;
end;




{

Function ValUnsignedInt(Const S: ShortString; var Code: ValSInt): ValUInt; [public, alias:'FPC_VAL_UINT_SHORTSTR'];
var
  u, prev: ValUInt;
  base : byte;
  negative : boolean;
begin
  ValUnSignedInt:=0;
  Code:=InitVal(s,negative,base);
  If Negative or (Code>length(s)) Then
    Exit;
  while Code<=Length(s) do
   begin
     case s[Code] of
       '0'..'9' : u:=Ord(S[Code])-Ord('0');
       'A'..'F' : u:=Ord(S[Code])-(Ord('A')-10);
       'a'..'f' : u:=Ord(S[Code])-(Ord('a')-10);
     else
      u:=16;
     end;
     prev := ValUnsignedInt;
     If (u>=base) or
        (ValUInt(MaxUIntValue-u) div ValUInt(Base)<prev) then
      begin
        ValUnsignedInt:=0;
        exit;
      end;
     ValUnsignedInt:=ValUnsignedInt*ValUInt(base) + u;
     inc(code);
   end;
  code := 0;
end;
}


end.
