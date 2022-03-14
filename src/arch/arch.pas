//
// Arch.pas
//
// This units contains the the code that is platform-dependent.
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

Unit arch;

  
interface
 const

  Kernel_Data_Sel = $10;
  Kernel_Code_Sel = $8;
  User_Data_Sel = $1B;
  User_Code_Sel =$23;

  Gdt_Nueva = $2000;
  Idt_Pos   = 0;

  Max_Sel=50;
  Max_Int=55;

  Sistema_Datos=$92;
  Sistema_Codigo=$9A;

  Usuario_Datos=$F2;
  Usuario_Codigo=$FA;

  Type
  struc_GDTR = packed record
  limite :word;
  base_lin:pointer;
  end;

  Type
  struc_descriptor= packed record
  limite_0_15:word;
  base_0_15:word;
  base_16_23:byte;
  tipo:byte;
  limite_16_23:byte;
  base_24_31:byte;
  end;

 Type
 p_struc_GDT=^struc_GDT;
 struc_GDT = array[0..Max_Sel-1] of struc_descriptor;

 type
 p_wait_queue = ^wait_queue ;

 wait_queue = record
 lock : boolean ;
 Lock_Wait : pointer ;
 end;

 const
 TAM_TSS=103;                  

 TSS_SIST_LIBRE=$89;               
 TSS_SIST_OCUP=$8B;                

 TSS_USER_LIBRE=$E9;              
 TSS_USER_OCUP =$EB;               

 TSK_GATE_SIST=$85;                
 TSK_GATE_USER=$E5;               

 INT_GATE_SIST=$8E;                
 INT_GATE_USER=$EE;

  Status_Port : array[0..1] of byte = ($20,$A0);
  Mask_Port : array[0..1] of byte = ($21,$A1);

  EOI = $20;
  PIC_MASK:array [0..7] of byte =(1,2,4,8,16,32,64,128);
 type
  struc_intr_gate=packed record
  entrada_0_15:word;
  selector:word;                 
  nu:byte;
  tipo:byte;
  entrada_16_31:word;
 end;

 type
 p_intr_gate=^struc_intr_gate;

 p_tss_struc=^tss_struc;

 TSS_STRUC= packed record
      back_link, __blh   : word;
      esp0               : pointer;
      ss0, __ss0         : word;
      esp1               : dword;
      ss1, __ss1         : word;
      esp2               : dword;
      ss2, __ss2         : word;
      cr3                : pointer;
      eip                : pointer;
      eflags             : dword;
      eax, ecx, edx, ebx : dword;
      esp, ebp           : pointer;
      esi, edi           : dword;
      es, __es           : word;
      cs, __cs           : word;
      ss, __ss           : word;
      ds, __ds           : word;
      fs, __fs           : word;
      gs, __gs           : word;
      ldt, __ldt         : word;
      trace, bitmap      : word;
 end;

{$I macros.inc}

procedure Memcopy(origen , destino :pointer;tamano:dword);
procedure debug(Valor:dword);
function Bit_Test(bitmap:Pointer;pos:dword):boolean;
procedure Bit_Reset(bitmap:pointer;pos:dword);
procedure Bit_Set(bitmap:pointer;pos:dword);
procedure Panic(error:pchar);
function Mapa_Get(Mapa:pointer;Limite:dword):word;
procedure Limpiar_Array(p_array:pointer;fin:word);
procedure Reboot;assembler;
function get_datetime  : dword ;
procedure enviar_byte(Data:byte;Puerto:word);assembler;
function leer_byte(puerto:word):byte;
procedure Enviar_Wd(Data:word;Puerto:dword);
function Leer_Wd(Puerto:word) : word ;
procedure Enviar_DW(Data:dword;Puerto:word);
procedure delay_io;
function Verify_User_Buffer (buff : pointer) : boolean;
function cmos_read(port : byte ) : byte ;
procedure ArchInit;
function gdt_dame:word;
procedure gdt_quitar(Selector:word);
function gdt_set_tss(tss:pointer):word;
procedure habilitar_irq(Irq:byte);
procedure dhabilitar_irq(Irq:byte);
procedure set_int_gate(int:byte;handler:pointer);
function bin_to_dec(bin:byte):byte;
procedure FarJump(tss:word;entry:pointer);
procedure set_int_gate_user(int:byte;handler:pointer);

var
  gdt_huecos_libres:dword;

implementation

var gdtreg:struc_gdtr;
    gdt_ar:p_struc_gdt;
    gdt_bitmap:array [0 .. 1023] of byte;
    Idtr:struc_Gdtr;

procedure habilitar_irq(Irq:byte);
var puerto:word;
    irqs,buf:byte;
    l:byte;
begin
puerto := $A1;

If (IRQ < 7) then puerto:=$21;

irqs:=leer_byte(puerto);
buf:=IRQS and (not PIC_MASK[irq]);
enviar_byte(buf,puerto);
end;

procedure dhabilitar_irq(Irq:byte);
var puerto:word;
    irqs,buf:byte;
begin
puerto:=$A1;
if IRQ<7 then puerto :=$21;

irqs:=leer_byte(puerto);
buf:=irqs or PIC_MASK[IRQ];
enviar_byte(buf,puerto);
end;

procedure fdi;[public , alias :'FDI'];
begin
enviar_byte($20,status_port[0]);
enviar_byte($20,status_port[1]);
end;

procedure habilitar_todasirq;
begin
enviar_byte(0,mask_port[0]);
enviar_byte(0,mask_port[1]);
end;

procedure dhabilitar_todasIrq;
begin
enviar_byte($ff,mask_port[0]);
enviar_byte($ff,mask_port[1]);
end;


function bin_to_dec(bin:byte):byte;inline;
var cont:byte;
begin
cont := 0 ;
repeat
If Bit_test(@bin,cont) then exit(cont);
cont += 1;
until (cont = 8) ;
exit(-1);
end;

procedure desviar_irqs ; assembler;
asm
    mov   al , 00010001b
    out   20h, al
    nop
    nop
    nop
    out  0A0h, al
    nop
    nop
    nop
    mov   al , 20h
    out   21h, al
    nop
    nop
    nop
    mov   al , 28h
    out  0A1h, al
    nop
    nop
    nop
    mov   al , 00000100b
    out   21h, al
    nop
    nop
    nop
    mov   al , 2
    out  0A1h, al
    nop
    nop
    nop
    mov   al , 1
    out   21h, al
    nop
    nop
    nop
    out  0A1h, al
    nop
    nop
    nop

    mov   al , 0FFh
    out   21h, al
    mov   al , 0FFh
    out  0A1h, al
end;

procedure set_int_gate(int:byte;handler:pointer);
var k:p_intr_gate;
    bajo:word;
    alto:dword;
begin

k := pointer(IDT_POS + int * 8);
asm
mov eax , handler
mov bajo, ax
mov alto , eax
end;

k^.entrada_0_15 := bajo;
k^.selector := Kernel_Code_Sel ;
k^.tipo := Int_Gate_Sist;
k^.entrada_16_31 := alto shr 16;
end;

procedure set_int_gate_user(int:byte;handler:pointer);
var alto,bajo:word;
    k:p_intr_gate ;
begin
k:=pointer(IDT_POS + int * 8 );
asm
mov eax , handler
mov bajo , ax
shr eax , 16
mov alto , ax
end;
k^.entrada_0_15 := bajo;
k^.selector := Kernel_Code_Sel;
k^.tipo := Int_Gate_User;
k^.entrada_16_31 := alto;

end;

Procedure int_ignore;interrupt;
begin
LoadKernelData;
asm 
cli
hlt
end;
//printk('/Virq/n : Irq igonarada\n',[]);
end;

procedure idt_init;
var m:word;
begin

idtr.base_lin := pointer(Idt_Pos);
idtr.limite := MAX_INT * 8 ;

asm
lidt [idtr]
end;

Habilitar_irq(2);

for m:= 17 to 54 Do
begin
Set_Int_Gate(m,@int_ignore);
end;

desviar_irqs;
end;

function gdt_dame:word;
var n:word;
begin

n:=Mapa_Get(@gdt_bitmap,Max_Sel);
If n = Max_Sel then exit(0)
 else
  begin
   Bit_Reset(@gdt_bitmap,n);
   Gdt_Huecos_Libres-=1;
   exit(n+1);
  end;
end;

procedure gdt_quitar(Selector:word);
begin
bit_Set(@gdt_bitmap,Selector-1);
Gdt_huecos_Libres +=1;
end;

procedure init_tss(tss:p_tss_struc);
var tmp:dword;
begin
tmp:=sizeof(tss_struc);
asm
mov ecx , tmp
mov edi , tss
xor eax , eax
rep stosb
end;
end;

function gdt_set_tss(tss:pointer):word;
var s,bajo:word;
         j:dword;
var altoA,altoB:byte;
begin

s := Gdt_Dame;

If s = 0 then exit(0);

Gdt_Set_Tss := s;
Init_Tss(Tss);

asm
mov eax , tss
mov bajo , ax
shr eax  , 16
mov ALTOB , al
mov ALTOA , ah
end;

GDT_AR^[s-1].limite_0_15:=104;
GDT_AR^[s-1].base_0_15:=bajo;
GDT_AR^[s-1].base_16_23:=ALTOB;
GDT_AR^[s-1].base_24_31:=ALTOA;
GDT_AR^[s-1].tipo:=TSS_SIST_LIBRE;
GDT_AR^[s-1].limite_16_23:=$40;
end;

procedure gdt_init;
var tmp:pointer;
    ret:dword;
begin

tmp:=@gdt_bitmap;
asm
mov  ecx , 256
mov  eax , $FFFFFFFF
mov  edi , tmp
rep  stosd
end;

gdtreg.limite:= 8192 * 8 - 1;        
gdtreg.base_lin:= pointer(GDT_NUEVA);             

Bit_Reset(@gdt_bitmap,0);
Bit_Reset(@gdt_bitmap,1);
Bit_Reset(@gdt_bitmap,2);
Bit_Reset(@gdt_bitmap,3);
Bit_Reset(@gdt_bitmap,4);

Gdt_Ar := pointer(gdt_nueva);

gdt_ar^[0].limite_0_15 := 0;
gdt_ar^[0].base_0_15 := 0 ;
gdt_ar^[0].base_16_23 := 0 ;
gdt_ar^[0].tipo :=0 ;
gdt_ar^[0].limite_16_23 := 0 ;
gdt_ar^[0].base_24_31 := 0 ;

gdt_ar^[1].limite_0_15 := $ffff;
gdt_ar^[1].base_0_15 := 0 ;
gdt_ar^[1].base_16_23 := 0 ;
gdt_ar^[1].tipo := sistema_codigo ;
gdt_ar^[1].limite_16_23 := $cf ;
gdt_ar^[1].base_24_31 := 0 ;

gdt_ar^[2].limite_0_15 := $ffff;
gdt_ar^[2].base_0_15 := 0 ;
gdt_ar^[2].base_16_23 := 0 ;
gdt_ar^[2].tipo := sistema_datos ;
gdt_ar^[2].limite_16_23 := $cf ;
gdt_ar^[2].base_24_31 := 0 ;

gdt_ar^[3].limite_0_15 := $ffff;
gdt_ar^[3].base_0_15 := 0 ;
gdt_ar^[3].base_16_23 := 0 ;
gdt_ar^[3].tipo := usuario_datos ;
gdt_ar^[3].limite_16_23 := $cf ;
gdt_ar^[3].base_24_31 := 0 ;

gdt_ar^[4].limite_0_15 := $ffff;
gdt_ar^[4].base_0_15 := 0 ;
gdt_ar^[4].base_16_23 := 0 ;
gdt_ar^[4].tipo := usuario_codigo ;
gdt_ar^[4].limite_16_23 := $cf ;
gdt_ar^[4].base_24_31 := 0 ;

asm
lgdt [gdtreg]
end;

Gdt_Huecos_Libres:=MAX_SEL - 5;
end;

procedure enviar_byte(Data:byte;Puerto:word);assembler;inline;
asm
mov dx,Puerto
mov al,data
out dx,al
end;

function leer_byte(puerto:word):byte;
var tmp : byte ;
begin
asm
mov dx,Puerto
in  al,dx
mov tmp , al
end;
exit(tmp);
end;

procedure Enviar_Wd(Data:word;Puerto:dword);inline;
var tmp : pointer ;
begin
tmp := @data ;
asm
mov edx , Puerto
mov esi , tmp
outsw
end;
end;

function Leer_Wd(Puerto:word) : word ;inline;
var r:dword;
   tmp : pointer ;
begin

tmp := @r ;

asm
mov dx , Puerto
mov edi ,  tmp
insw
end;

exit(r);
end;


function Leer_DW(Puerto:word):word;inline;
var r : word;
    tmp : pointer ;
begin

tmp := @r;

asm
mov dx , puerto
mov edi , tmp
insd
end;

exit(r);
end;

procedure Enviar_DW(Data:dword;Puerto:word);inline;
var tmp : pointer ;
begin
tmp := @data ;

asm
mov esi , tmp
mov dx , puerto
outsd
end;

end;


procedure delay_io;
var tmp  : dword ;
begin
for tmp := 1 to 500 do ;
end;


function Verify_User_Buffer (buff : pointer) : boolean;inline;
begin
if buff < pointer ($40000000) then exit(false) else exit(true);
end;


function cmos_read(port : byte ) : byte ;inline;
begin
enviar_byte($80 or port , $70);
delay_io;
exit(leer_byte($71));
end;

procedure Memcopy(origen , destino :pointer;tamano:dword);
begin
  asm
    push esi
    push edi
    mov esi , origen
    mov edi , destino
    mov ecx , tamano
    rep movsb
    pop edi
    pop esi
  end;
end;

procedure debug(Valor:dword);
begin
asm
xor edx , edx
mov edx , valor
@bucle:
 jmp @bucle
end;
end;

function Bit_Test(bitmap: Pointer; pos:dword):boolean;
var
 b: ^Byte;
 bt, off: dword;
begin
  Result := False;
  b := bitmap;
  bt := pos div 8;
  off := pos mod 8;
  if (b[bt] shr off) and 1 = 1 then
    Result := True;
end;

procedure Bit_Reset(bitmap: Pointer; pos: dword);
var
 b: ^Byte;
 bt, off: dword;
begin
  b := bitmap;
  bt := pos div 8;
  off := pos mod 8;
  b[bt] := b[bt] and (not(1 shl off));
end;

procedure Bit_Set(bitmap: Pointer; pos:dword);
var
 b: ^Byte;
 bt, off: dword;
begin
  b := bitmap;
  bt := pos div 8;
  off := pos mod 8;
  b[bt] := b[bt] or (1 shl off);
end;

procedure Panic(error:pchar);
begin
//printk(@error,[],[]);
debug(-1);
end;

function Mapa_Get(Mapa:pointer;Limite:dword):word;
var ret:word;
begin
dec(Limite);
asm
mov esi , Mapa
mov ecx , limite
xor eax ,  eax
@bucle:
  bt dword[esi] , ax
  jc @si
  inc ax
  loop @bucle
@si:
   mov ret , ax
end;
exit (ret);
end;

procedure Limpiar_Array(p_array:pointer;fin:word);
var tmp:word;
    cl:^char;
begin
cl:=p_array;
for tmp:= 0 to Fin do
 begin
 cl^:=#0;
 cl+=1;
end;
end;

procedure Reboot;assembler;
asm
   cli

   @wait:
      in    al , $64
      test  al , 2
   jnz @wait

   mov   edi, $472
   mov   word [edi], $1234
   mov   al , $FC
   out   $64, al

   @die:
      hlt
      jmp @die
end;


procedure Bcd_To_Bin(var val:dword) ;inline;
begin
val := (val and 15) + ((val shr 4) * 10 );
end;

function get_datetime  : dword ;
var sec , min , hour  , day , mon , year  : dword ;
begin

repeat
      sec  := Cmos_Read(0);
      min  := Cmos_Read(2);
      hour := Cmos_Read(4);
      day  := Cmos_Read(7);
      mon  := Cmos_Read(8);
      year := Cmos_Read(9);

until (sec = Cmos_Read(0));

Bcd_To_Bin(sec);
Bcd_To_Bin(min);
Bcd_To_Bin(hour);
Bcd_To_Bin(day);
Bcd_To_Bin(mon);
Bcd_To_Bin(year);

mon -= 2 ;

If (0 >= mon) then
 begin
 mon += 12 ;
 year -= 1;
end;


get_datetime :=   (( ((year div 4 - year div 100 + year div 400 + 367 * mon div 12 + day)  +(year * 365)  -(719499))
   *24 +hour )
   *60 +min  )
   *60 +sec;
end;

procedure FarJump(tss:word;entry:pointer);assembler;[nostackframe];
asm
    push ebp
    mov ebp , esp
    mov    ax , tss
    mov    word [ebp - 2], ax
    mov    eax, entry
    mov    dword [ebp - 6], eax
    ljmp   dword [ebp - 6]
    leave
    ret 8
end;

procedure ArchInit;
begin
gdt_init;
idt_init;
end;

end.
