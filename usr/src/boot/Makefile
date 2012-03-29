#
#Archivo make para compilacion del Modulo de booteo
# 
#
#



include $(TOP_DIR)../make.rules

all : head32.o multiboot.o

head32.o : head32.s
	$(NASM) -o head32.o -f elf head32.s

multiboot.o : multiboot.pas
	$(FPC) $(FPC_FLAGS) multiboot.pas
	$(AS) -o multiboot.o multiboot.s
	$(RM) multiboot.s
	$(RM) *.ppu





	
	





