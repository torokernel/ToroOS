function gdt_dame:word;external name 'GDT_DAME';
procedure gdt_init;external name 'GDT_INIT';
procedure gdt_quitar(Selector:word);external name 'GDT_QUITAR'; 
function gdt_set_tss(tss:pointer):word;external name 'GDT_SET_TSS';
procedure init_tss(tss:p_tss_struc);external name 'INIT_TSS';


{$DEFINE gdt_lock := lock (@gdt_wait) }
{$DEFINE gdt_unlock := unlock (@gdt_wait) }


var gdt_huecos_libres:dword ; external name 'U_GDT_GDT_HUECOS_LIBRES';
    gdt_wait : wait_queue ; external name 'U_GDT_GDT_WAIT';

