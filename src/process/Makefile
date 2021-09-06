#
# Este archivo Compila el modulo encargado del manejo de procesos
# 
#
#

include $(TOP_DIR)../make.rules


all : process.o

process.o : process.pas
	$(FPC) $(FPC_FLAGS) process.pas
	$(AS) -o process.o process.s
	$(RM) *.s
	$(RM) *.ppu
