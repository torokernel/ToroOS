#
#Este es el archivo para make para compilar el Fs
#
#
#

include $(TOP_DIR)../../make.rules

all : super.o inodes.o files.o misc.o

super.o : super.pas 
	$(FPC) $(FPC_FLAGS) super.pas
	$(AS) -o super.o super.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu


inodes.o : inodes.pas 
	$(FPC) $(FPC_FLAGS) inodes.pas
	$(AS) -o inodes.o inodes.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu


files.o : files.pas 
	$(FPC) $(FPC_FLAGS) files.pas
	$(AS) -o files.o files.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu


misc.o : misc.pas 
	$(FPC) $(FPC_FLAGS) misc.pas
	$(AS) -o misc.o misc.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu

