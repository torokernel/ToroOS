#
#
#Compila los drivers de bloque
#


include $(TOP_DIR)../../make.rules

all :  ll_rw_block.o floppy.o 

ll_rw_block.o : ll_rw_block.pas
	$(FPC)  $(FPC_FLAGS) ll_rw_block.pas
	$(AS) -o ll_rw_block.o ll_rw_block.s
	$(RM) *.s

floppy.o : floppy.pas
	$(FPC) $(FPC_FLAGS) floppy.pas
	$(AS) -o floppy.o floppy.s
	$(RM) *.s
	
