#
#
#Este archivo es el utilizado por make para la compilacion de los Drivers
#
#

include $(TOP_DIR)../../make.rules

all : tty.o

tty.o : tty.pas
	$(FPC) $(FPC_FLAGS) tty.pas
	$(AS) -o tty.o tty.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu
