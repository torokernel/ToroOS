#
#
# Este es el archivo de make para la compilacion del modulo de CPU
# 
#
#



include $(TOP_DIR)../make.rules

all : cpu.o 

cpu.o : cpu.pas 
	$(FPC) $(FPC_FLAGS) cpu.pas
	$(AS) -o cpu.o cpu.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu




	

	
	
	





