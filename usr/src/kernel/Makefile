#
#Este archivo compila el kernel de Toro
#
#
#

include $(TOP_DIR)../make.rules

all : init.o  syscall.o printk.o kernel.o dma.o kdev.o
init.o : init.pas 
	$(FPC) $(FPC_FLAGS)  init.pas
	$(AS) -o init.o init.s
	$(RM) *.s
	$(RM) *.ppu


syscall.o : syscall.pas 
	$(FPC) $(FPC_FLAGS) syscall.pas
	$(AS) -o syscall.o syscall.s
	$(RM) *.s
	$(RM) *.ppu


printk.o : printk.pas
	$(FPC) $(FPC_FLAGS) printk.pas
	$(AS) -o printk.o printk.s
	$(RM) *.s
	$(RM) *.ppu


dma.o : dma.pas
	$(FPC) $(FPC_FLAGS) dma.pas
	$(AS) -o dma.o dma.s
	#$(RM) *.s
	$(RM) *.ppu

kdev.o : kdev.pas
	$(FPC) $(FPC_FLAGS) kdev.pas
	$(AS) -o kdev.o kdev.s
	#$(RM) *.s
	$(RM) *.ppu

	
kernel.o : kernel.pas 
	$(FPC) $(FPC_FLAGS) kernel.pas
	$(AS) -o kernel.o kernel.s
	$(RM) link.res
	#$(RM) *.s


	

	
	





