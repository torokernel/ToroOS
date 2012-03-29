#
#
#Este archivo es el utilizado por make para la compilacion de los Drivers
#
#

include $(TOP_DIR)../../make.rules


all : pci.o 

pci.o : pci.pas
	$(FPC) $(FPC_FLAGS) pci.pas
	$(AS) -o pci.o pci.s
	$(RM) *.s
	$(RM) *.ppu


	
	
	





