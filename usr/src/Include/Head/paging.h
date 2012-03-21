function get_free_page:pointer;external;
procedure free_page(Add_f:pointer);external;
function get_phys_add(add_l,Pdt:pointer):pointer;external;
function get_page_index(Add_l:pointer):Indice;external;
function unload_page_table(add_l,add_dir:pointer):dword;external;
function dup_page_table(add_tp:pointer):dword;external;
function get_free_kpage:pointer;external;
procedure paging_init;external;
function free_reserve_page (add_f : pointer ) : dword;external;
function reserve_page (add_f:pointer):dword;external;
function get_dma_page : pointer ;external;


{$DEFINE mem_lock := lock (@mem_wait) ; }
{$DEFINE mem_unlock := unlock (@mem_wait) ;}
{$DEFINE flush_tlp := asm eax , cr3 ; mov cr3 , eax ; end ;}
{$DEFINE Save_Cr3 := asm mov eax ,cr3 ; push eax ; end ;}
{$DEFINE Restore_Cr3 := asm pop eax ; mov cr3 , eax ; end ;}
{$DEFINE Load_Kernel_Pdt := asm mov eax , kernel_pdt ; mov cr3 , eax ; end ;}



var nr_free_page:dword;external name 'U_PAGING_NR_FREE_PAGE';
    Kernel_PDT:pointer;external name 'U_PAGING_KERNEL_PDT';
    mem_map : P_page ;external name 'U_PAGING_MEM_MAP';
    mem_wait : wait_queue ; external name 'U_PAGING_MEM_WAIT';



