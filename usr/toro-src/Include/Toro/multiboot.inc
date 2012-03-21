const

Kernel_Stacksize = $4000;

Multiboot_Bootloader_Magic = $2BADB002;

type
Pelf_section_header_table_t = ^elf_section_header_table_t;

elf_section_header_table_t = packed record
num: dword;
size: dword;
addr: dword;
shndx: dword;
end;

Pmultiboot_info_t = ^multiboot_info_t;
multiboot_info_t = packed record
flags: dword;
mem_lower: dword;
mem_upper: dword;
boot_device: dword;
cmdline: dword;
mods_count: dword;
mods_addr: dword;
elf_sec: elf_section_header_table_t;
mmap_length: dword;
mmap_addr: dword;
end;

Pmodule_t = ^module_t;

module_t = packed record
mod_start: dword;
mod_end: dword;
name: dword;
reserved: dword;
end;

Pmemory_map_t = ^memory_map_t;

memory_map_t = packed record
size: dword;
base_addr_low: dword;
base_addr_high: dword;
length_low: dword;
length_high: dword;
mtype: DWOrd

end;