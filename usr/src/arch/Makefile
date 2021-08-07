#
#Archivo Make para la compilacion del modulo Asm
#
#

include $(TOP_DIR)../make.rules

all : arch.o 

arch.o : arch.pas 
	$(FPC) $(FPC_FLAGS) arch.pas
	$(AS) -o arch.o arch.s
	#$(RM) *.s
	$(RM) *.ppu
