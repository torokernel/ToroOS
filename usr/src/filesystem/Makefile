#
#Este es el archivo para make para compilar el Fs
#
#
#

include $(TOP_DIR)../make.rules

all : fat.o filesystem.o

filesystem.o : filesystem.pas 
	$(FPC) $(FPC_FLAGS) filesystem.pas
	$(AS) -o filesystem.o filesystem.s
	$(RM) *.s
	$(RM) *.ppu

fat.o : fat.pas 
	$(FPC) $(FPC_FLAGS) fat.pas
	$(AS) -o fat.o fat.s
	$(RM) *.s
	$(RM) *.ppu
