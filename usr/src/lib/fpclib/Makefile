#
#Este archivo se encarga de compilar fpclib
#
#
#



include $(TOP_DIR)../../make.rules

all : fpclib.o strings.o system.o objpas.o

strings.o : strings.pas
	$(FPC) -s -Sh -Sg -Cn -Sc -S2 -OG -Sm -Un -a -vwnh -Rintel strings.pas
	$(AS) -o strings.o strings.s
	$(RM) *.s
	$(RM) *.ppu


fpclib.o : fpclib.pas 
	$(FPC) -s -Sh -Sg -Cn -Sc -S2 -OG -Sm -Un -a -vwnh -Rintel fpclib.pas
	$(AS) -o fpclib.o fpclib.s
	$(RM) *.s
	$(RM) *.ppu

system.o : system.pas 
	$(FPC) -s -Sh -Sg -Cn -Sc -S2 -OG -Sm -Un -a -vwnh -Rintel system.pas 
	$(AS) -o system.o system.s
	$(RM) *.s
	$(RM) *.ppu

objpas.o : objpas.pas
	$(FPC) -s -Sh -Sg -Cn -Sc -S2 -OG -Sm -Un -a -vwnh -Rintel objpas.pas 
	$(AS) -o objpas.o objpas.s
	$(RM) *.s
	$(RM) *.ppu




	
	





