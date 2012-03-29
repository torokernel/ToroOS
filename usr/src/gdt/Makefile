#
#Este archivo compila la GDT
#
#

include $(TOP_DIR)../make.rules


all : gdt.o 

gdt.o : gdt.pas 
	$(FPC) $(FPC_FLAGS) gdt.pas
	$(AS) -o gdt.o gdt.s
	$(RM) *.s
	$(RM) *.ppu



	
	





