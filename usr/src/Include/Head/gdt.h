function gdt_dame:word;external;
procedure gdt_init;external;
procedure gdt_quitar(Selector:word);external;
function gdt_set_tss(tss:pointer):word;external;
procedure init_tss(tss:p_tss_struc);external;


{$DEFINE gdt_lock := lock (@gdt_wait) }
{$DEFINE gdt_unlock := unlock (@gdt_wait) }


var gdt_huecos_libres:dword ; external name 'U_GDT_GDT_HUECOS_LIBRES';
    gdt_wait : wait_queue ; external name 'U_GDT_GDT_WAIT';

