

#
# Este archivo Compila el modulo de memoria
# 
#
#

include $(TOP_DIR)../make.rules


all :  mm.o malloc.o mapmem.o paging.o vmalloc.o 

mm.o : mm.pas 
	$(FPC) $(FPC_FLAGS) mm.pas
	$(AS) -o mm.o mm.s
	$(RM) *.s
	$(RM) *.ppu


malloc.o : malloc.pas
	$(FPC) $(FPC_FLAGS) malloc.pas
	$(AS) -o malloc.o malloc.s
	$(RM) *.s
	$(RM) *.ppu


mapmem.o : mapmem.pas
	$(FPC) $(FPC_FLAGS) mapmem.pas
	$(AS) -o mapmem.o mapmem.s
	$(RM) *.s
	$(RM) *.ppu


paging.o : paging.pas
	$(FPC) $(FPC_FLAGS) paging.pas
	$(AS) -o paging.o paging.s
	$(RM) *.s
	$(RM) *.ppu


vmalloc.o : vmalloc.pas
	$(FPC) $(FPC_FLAGS) vmalloc.pas
	$(AS) -o vmalloc.o vmalloc.s
	$(RM) *.s
	$(RM) *.ppu


	

	
	
	





