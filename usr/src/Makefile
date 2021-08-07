#
#Este archivo utilizado por Make se encarga de compilar todo
#el sistema y generar la imagen para el disquet de 3 1/2
#

include make.rules

toro-kernel : 
	make -C arch
	make -C process
	make -C memory
	make -C kernel
	make -C filesystem
	make -C drivers
	$(LD) -g --gc-sections -L. -o toro.elf -T linkfile -Map toro.elf.map
