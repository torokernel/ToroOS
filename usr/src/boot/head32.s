
BITS 32

    GLOBAL _inicio  

    EXTERN MULTIBOOT_INIT
    EXTERN PASCALMAIN

    ;
    ; Posible multiboot header flags
    ;

    MULTIBOOT_MODULE_ALIGN		equ	1<<0
    MULTIBOOT_MEMORY_MAP		equ	1<<1
    MULTIBOOT_GRAPHICS_FIELDS	        equ	1<<2
    MULTIBOOT_ADDRESS_FIELDS	        equ	1<<16

    ;
    ; Multiboot header defines
    ;
    
    MULTIBOOT_HEADER_MAGIC		equ	0x1BADB002     
    MULTIBOOT_HEADER_FLAGS		equ	MULTIBOOT_MODULE_ALIGN | MULTIBOOT_MEMORY_MAP
    MULTIBOOT_HEADER_CHECKSUM	equ	-(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

 

SECTION .text

;
; Multiboot header
;
align 4
dd MULTIBOOT_HEADER_MAGIC
dd MULTIBOOT_HEADER_FLAGS
dd MULTIBOOT_HEADER_CHECKSUM

;tamaño del la pila
KERNEL_STACKSIZE		equ	0x4000

   _inicio: 

    mov esp , KERNEL_STACK+KERNEL_STACKSIZE
    mov ebp , KERNEL_STACK+KERNEL_STACKSIZE

    push eax
    push ebx 
    call MULTIBOOT_INIT 

    jmp PASCALMAIN


     GLOBAL FARJUMP
FARJUMP:
    push   ebp
    mov    ebp, esp
    mov    ax , word [ebp + 8]
    mov    word [ebp - 2], ax
    mov    eax, dword [ebp + 12]
    mov    dword [ebp - 6], eax
    jmp    dword far [ebp - 6]
    leave
    ret    8


SECTION .bss

;
; Kernel stack location
;
align 32
KERNEL_STACK:
	resb KERNEL_STACKSIZE

