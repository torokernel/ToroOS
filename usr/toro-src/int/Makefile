#
#Este archivo compila el modulo de Int.
#
#
#

include $(TOP_DIR)../make.rules

all: excepciones.o idt.o irq.o 

excepciones.o : excepciones.pas 
	$(FPC) $(FPC_FLAGS) excepciones.pas
	$(AS) -o excepciones.o excepciones.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu


idt.o : idt.pas 
	$(FPC) $(FPC_FLAGS) idt.pas
	$(AS) -o idt.o idt.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu



irq.o : irq.pas 
	$(FPC) $(FPC_FLAGS) irq.pas
	$(AS) -o irq.o irq.s
	$(RM) *.s
	$(RM) *.bat
	$(RM) *.ppu
	



	
	





