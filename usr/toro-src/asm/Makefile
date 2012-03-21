#
#Archivo Make para la compilacion del modulo Asm
#
#

include $(TOP_DIR)../make.rules

all : asmb.o 

asmb.o : asmb.pas 
	$(FPC) $(FPC_FLAGS) asmb.pas
	$(AS) -o asmb.o asmb.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu


	
	





