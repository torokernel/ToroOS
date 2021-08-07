#
#
#Compila los drivers de bloque
#


include $(TOP_DIR)../make.rules

all :  floppy.o dma.o tty.o 

dma.o : dma.pas
	$(FPC) $(FPC_FLAGS) dma.pas
	$(AS) -o dma.o dma.s
	$(RM) *.s
	
floppy.o : floppy.pas
	$(FPC) $(FPC_FLAGS) floppy.pas
	$(AS) -o floppy.o floppy.s
	$(RM) *.s

tty.o : tty.pas
	$(FPC) $(FPC_FLAGS) tty.pas
	$(AS) -o tty.o tty.s
	$(RM) *.s
