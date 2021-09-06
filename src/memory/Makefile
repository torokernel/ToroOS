

#
# Este archivo Compila el modulo de memoria
# 
#
#

include $(TOP_DIR)../make.rules

all :  memory.o 

memory.o : memory.pas 
	$(FPC) $(FPC_FLAGS) memory.pas
	$(AS) -o memory.o memory.s
	$(RM) *.s
	$(RM) *.ppu
