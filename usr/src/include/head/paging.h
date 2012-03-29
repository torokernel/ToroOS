function get_free_page:pointer;external name 'GET_FREE_PAGE';
procedure free_page(Add_f:pointer);external name 'FREE_PAGE';
function get_phys_add(add_l,Pdt:pointer):pointer;external name 'GET_PHYS_ADD';
function get_page_index(Add_l:pointer):Indice;external name 'GET_PAGE_INDEX';
function unload_page_table(add_l,add_dir:pointer):dword;external name 'UNLOAD_PAGE_TABLE';
function dup_page_table(add_tp:pointer):dword;external name 'DUP_PAGE_TABLE';
function get_free_kpage:pointer;external name 'GET_FREE_KPAGE';
procedure paging_init;external name 'PAGING_INIT';
function free_reserve_page (add_f : pointer ) : dword;external name 'FREE_RESERVE_PAGE';
function reserve_page (add_f:pointer):dword;external name 'RESERVE_PAGE';
function get_dma_page : pointer ;external name 'GET_DMA_PAGE';


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



