{ ELF header definition }

{$IFNDEF __ELF__}
{$DEFINE __ELF__}

type

   P_elf_phdr     = ^elf_phdr;
   P_elf_header_t = ^elf_header_t;

   { elf_phdr structure defines each segment (.text, .data and .bss) }

   elf_phdr = record   { 32 bytes }
      p_type   : dword;
      p_offset : dword;
      p_vaddr  : dword;
      p_paddr  : dword;
      p_filesz : dword;
      p_memsz  : dword;
      p_flags  : dword;
      p_align  : dword;
   end;

   elf_header_t = record   { 52 bytes }
      e_ident     : array [0..15] of byte;
      e_type      : word;    { Object file type }
      e_machine   : word;    {Tipo de procesador para el que fue escrito}
      e_version   : dword;   {Version del archivo objeto}
      e_entry     : pointer; {Puntero a la primera instruccion del programa}
      e_phoff     : dword;   {offset de la tabla de cabeza en bytes}
      e_shoff     : pointer; {offset de la seccion de cabeza en bytes}
      e_flags     : dword;   {flags de maquina}
      e_ehsize    : word;    {tamano de la cabeza en bytes}
      e_phentsize : word;    {tamano de una entrada en la tabla de cabeza de programa}
      e_phnum     : word;    {numero de entradas en la tabla de cabeza de programa}
      e_shentsize : word;    {tamano de la secion de cabeza en bytes}
      e_shnum     : word;    {numero de entradas en la seccion de cabeza}
      e_shstrndx  : word;
   end;

const

   { type values }

   ET_NONE   = 0;       { No file type }
   ET_REL    = 1;       { Relocatable file }
   ET_EXEC   = 2;       { Executable file }
   ET_DYN    = 3;       { Shared object file }
   ET_CORE   = 4;       { core file }
   ET_LOPROC = $FF00;   { Processor-specific }
   ET_HIPROC = $FFFF;   { Processor-specific }

   { machine values }

   EM_NONE  = 0;   { No machine }
   EM_M32   = 1;   { AT&T WE 32100 }
   EM_SPARC = 2;   { Sparc }
   EM_386   = 3;   { Intel 80x386 CPU }
   EM_68K   = 4;   { Motorola 68000 }
   EM_88K   = 5;   { Motorola 88000 }
   EM_860   = 6;   { Intel 860 CPU }
   EM_MIPS  = 7;   { MIPS R2000 }

   { version values }

   EV_NONE    = 0;   { Invalid version }
   EV_CURRENT = 1;   { Current version }

   { Initial bytes index in an ELF header }

   EI_MAG0    = 0;
   EI_MAG1    = 1;
   EI_MAG2    = 2;
   EI_MAG3    = 3;
   EI_CLASS   = 4;
   EI_DATA    = 5;
   EI_VERSION = 6;

   { Initial bytes of an ELF header }

   ELFMAG0 = $7F;
   ELFMAG1 = $45;   { 'E' }
   ELFMAG2 = $4C;   { 'L' }
   ELFMAG3 = $46;   { 'F' }

   ELFCLASSNONE = 0;   { Invalid class }
   ELFCLASS32   = 1;   { 32-bit objects }
   ELFCLASS64   = 2;   { 64-bit objects }

   ELFDATANONE  = 0;   { Invalid data encoding }
   ELFDATA2LSB  = 1;   { 386-style data encoding }
   ELFDATA2MSB  = 2;   { 68k-style data encoding }

{$ENDIF}
