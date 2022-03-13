ENTRY(_START)
SECTIONS
{
     . = 0x40000000;
     .text ALIGN (0x1000) :
    {
    _text = .;
    KEEP(*(.init .init.*))
    *(.text .text.*)
    *(.strings)
    *(.rodata .rodata.*)
    *(.comment)
    _etext = .;
    }
    .data ALIGN (0x1000) :
    {
    _data = .;
    *(.data .data.*)
    KEEP (*(.fpc .fpc.n_version .fpc.n_links))
    _edata = .;
    }
    . = ALIGN(4);
    .bss :
    {
    _bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    }
_bss_end = . ;
}
_end = .;
