function kmalloc(Size:dword):pointer;external name 'KMALLOC';
function kfree_s(addr:pointer;size:dword):dword;external name 'KFREE_S';

var Mem_Alloc : dword ; external name 'U_MALLOC_MEM_ALLOC';
