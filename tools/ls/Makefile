include $(TOP_DIR)../../src/make.rules

all : ls.o

ls.o : ls.pas
	$(FPC) -TEmbedded -Fi$(FPC_RTL)/i386 -Fi$(FPC_RTL)/embedded -Fi$(FPC_RTL)/inc -Fu$(FPC_RTL)/embedded -Us $(FPC_RTL)/embedded/system.pp
	$(FPC) -s -MObjfpc -Fi$(FPC_RTL)/i386 -Fi$(FPC_RTL)/inc -TEmbedded -Fu$(FPC_RTL)/inc/ -Fu$(FPC_RTL)/objpas/ -Fu$(FPC_RTL)/embedded -Sm ls.pas
	$(LD) -g --gc-sections  -L. -o ls -T ../layout.ld -Map ls.map ls.o $(FPC_RTL)/objpas/objpas.o $(FPC_RTL)/inc/strings.o $(FPC_RTL)/embedded/crt.o $(FPC_RTL)/embedded/system.o
	rm ls.o
clean : 
	rm ls.o
