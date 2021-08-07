#
#Este archivo compila el kernel de Toro
#
#
#

include $(TOP_DIR)../make.rules

all : printk.o kernel.o syscall.o torosys.o

printk.o : printk.pas
	$(FPC) $(FPC_FLAGS) printk.pas
	$(AS) --32 -o printk.o printk.s
	$(RM) *.s
	$(RM) *.ppu
	
kernel.o : kernel.pas 
	$(FPC) $(FPC_FLAGS) kernel.pas
	$(AS) --32 -o kernel.o kernel.s
	$(RM) link.res
	$(RM) *.s

syscall.o : syscall.pas 
	$(FPC) $(FPC_FLAGS) syscall.pas
	$(AS) --32 -o syscall.o syscall.s
	$(RM) *.s
	$(RM) *.ppu

torosys.o : ToroSys.pas 
	$(FPC) $(FPC_FLAGS) ToroSys.pas
	$(AS) --32 -o torosys.o ToroSys.s
	$(RM) *.s
	$(RM) *.ppu
