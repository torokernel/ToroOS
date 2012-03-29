{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2003-2011 Matias Vara <matiasvara@yahoo.com>
    All Rights Reserved     
    
    System unit for Toro.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit System;

interface

{$DEFINE FPC_IS_SYSTEM}
{$inline on}
{$macro on}
{$asmmode intel}

{$I-,Q-,H-,R-,V-}
{$mode objfpc}

{ Using inlining for small system functions/wrappers }
{$inline on}
{$ifdef COMPPROCINLINEFIXED}
{$define SYSTEMINLINE}
{$endif COMPPROCINLINEFIXED}

{ don't use FPU registervariables on the i386 }
{$ifdef CPUI386}
  {$maxfpuregisters 0}
{$endif CPUI386}


{ needed for insert,delete,readln }
{$P+}
{ stack checking always disabled
  for system unit. This is because
  the startup code might not
  have been called yet when we
  get a stack error, this will
  cause big crashes
}
{$S-}

{****************************************************************************
                         Global Types and Constants
****************************************************************************}

type
  { The compiler has all integer types defined internally. Here we define only aliases }
  DWORD    = LongWord;
  Cardinal = LongWord;
  Integer  = SmallInt;


{$ifdef CPUX86_64}
  {$define DEFAULT_DOUBLE}
  ValReal = Double;

  { map comp to int64, but this doesn't mean we compile the comp support in! }
  {$ifndef Linux}
   Comp = Int64;
  {$endif Linux}

  PComp = ^Comp;

  {$define SUPPORT_SINGLE}
  {$define SUPPORT_DOUBLE}

{$endif CPUX86_64}

{$ifdef CPU64}
  SizeInt = Int64;
  SizeUInt = QWord;
  PtrInt = Int64;
  PtrUInt = QWord;
  ValSInt = Int64;
  ValUInt = QWord;
{$endif CPU64}

{$IFDEF CPU32}
  SizeInt = Longint;
  SizeUInt = DWord;
  PtrInt = Longint;
  PtrUInt = DWORD;
  ValSInt = Longint;
  ValUInt = Cardinal;
{$ENDIF CPU32}

{ Zero - terminated strings }
  PChar               = ^Char;
  PPChar              = ^PChar;

  { AnsiChar is equivalent of Char, so we need
    to use type renamings }
  TAnsiChar           = Char;
  AnsiChar            = Char;
  PAnsiChar           = PChar;
  PPAnsiChar          = PPChar;

  UTF8String          = type ansistring;
  PUTF8String         = ^UTF8String;

  HRESULT             = type Longint;
  TDateTime           = type Int64;
  Error               = type Longint;

  PSingle             = ^Single;
  PDouble             = ^Double;
  PCurrency           = ^Currency;
{$ifdef SUPPORT_COMP}
  PComp               = ^Comp;
{$endif SUPPORT_COMP}
  PExtended           = ^Extended;

  PSmallInt           = ^Smallint;
  PShortInt           = ^Shortint;
  PInteger            = ^Integer;
  PByte               = ^Byte;
  PWord               = ^word;
  PDWord              = ^DWord;
  PLongWord           = ^LongWord;
  PLongint            = ^Longint;
  PCardinal           = ^Cardinal;
  PQWord              = ^QWord;
  PInt64              = ^Int64;
  PPtrInt             = ^PtrInt;
  PSizeInt            = ^SizeInt;

  PPointer            = ^Pointer;
  PPPointer           = ^PPointer;

  PBoolean            = ^Boolean;
  PWordBool           = ^WordBool;
  PLongBool           = ^LongBool;

  PShortString        = ^ShortString;
  PAnsiString         = ^AnsiString;

  PDate               = ^TDateTime;
  PError              = ^Error;

var 
	 fpc_threadvar: pointer; public name 'THREADVARLIST_SI_PRC';
implementation 



end.
