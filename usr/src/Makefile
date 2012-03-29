#
#Este archivo utilizado por Make se encarga de compilar todo
#el sistema y generar la imagen para el disquet de 3 1/2
#

include make.rules

toro-kernel : 
	make -C asm
	make -C boot
	make -C cpu
	make -C gdt
	make -C procesos
	make -C memoria
	make -C int
	make -C kernel
	make -C filesystem
	make -C filesystem/fat
	make -C drivers/bus
	make -C drivers/char
	make -C drivers/block
	make -C lib/fpclib
	$(LD) -m elf_i386 -s -o ../../boot/toro-1.1.3 @links -T linkfile.txt
