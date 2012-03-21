function kmalloc(Size:dword):pointer;external;
function kfree_s(addr:pointer;size:dword):dword;external;

var Mem_Alloc : dword ; external name 'U_MALLOC_MEM_ALLOC';
