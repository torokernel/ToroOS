#
#Este es el archivo para make para compilar el Fs
#
#
#

include $(TOP_DIR)../make.rules

all : block_dev.o buffer.o exec.o inodes.o namei.o mount.o open.o read_write.o super_bloque.o devices.o ioctl.o dcache.o 

block_dev.o : block_dev.pas 
	$(FPC) $(FPC_FLAGS) block_dev.pas
	$(AS) -o block_dev.o block_dev.s
	$(RM) *.s
	$(RM) *.ppu


buffer.o : buffer.pas 
	$(FPC) $(FPC_FLAGS) buffer.pas
	$(AS) -o buffer.o buffer.s
	$(RM) *.s
	$(RM) *.ppu


exec.o : exec.pas 
	$(FPC) $(FPC_FLAGS) exec.pas
	$(AS) -o exec.o exec.s
	$(RM) *.s
	$(RM) *.ppu


inodes.o : inodes.pas 
	$(FPC) $(FPC_FLAGS) inodes.pas
	$(AS) -o inodes.o inodes.s
	$(RM) *.s
	$(RM) *.ppu


mount.o : mount.pas 
	$(FPC) $(FPC_FLAGS) mount.pas
	$(AS) -o mount.o mount.s
	$(RM) *.s
	$(RM) *.ppu


open.o : open.pas 
	$(FPC) $(FPC_FLAGS) open.pas
	$(AS) -o open.o open.s
	$(RM) *.s
	$(RM) *.ppu


read_write.o : read_write.pas 
	$(FPC) $(FPC_FLAGS) read_write.pas
	$(AS) -o read_write.o read_write.s
	$(RM) *.s
	$(RM) *.ppu


super_bloque.o : super_bloque.pas 
	$(FPC) $(FPC_FLAGS) super_bloque.pas
	$(AS) -o super_bloque.o super_bloque.s
	$(RM) *.s
	$(RM) *.ppu


devices.o : devices.pas 
	$(FPC) $(FPC_FLAGS) devices.pas
	$(AS) -o devices.o devices.s
	$(RM) *.s
	$(RM) *.ppu


ioctl.o : ioctl.pas
	$(FPC) $(FPC_FLAGS) ioctl.pas
	$(AS) -o ioctl.o ioctl.s
	$(RM) *.s
	$(RM) *.ppu


dcache.o : dcache.pas
	$(FPC) $(FPC_FLAGS) dcache.pas
	$(AS) -o dcache.o dcache.s
	$(RM) *.s
	$(RM) *.ppu


namei.o : namei.pas
	$(FPC) $(FPC_FLAGS) namei.pas
	$(AS) -o namei.o namei.s
	$(RM) *.s
	$(RM) *.ppu






