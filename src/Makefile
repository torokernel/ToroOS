include make.rules

toro-kernel : 
	make -C arch
	make -C process
	make -C memory
	make -C kernel
	make -C filesystem
	make -C drivers
	$(LD) -g --gc-sections -L. -o toro.elf -T linkfile -Map toro.elf.map $(FPC_EMB)/system.o $(FPC_EMB)/objpas.o $(FPC_EMB)/multiboot.o
