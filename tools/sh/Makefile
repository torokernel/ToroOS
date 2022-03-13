include $(TOP_DIR)../../src/make.rules

all : sh.o

sh.o : sh.pas
	$(FPC) -TEmbedded -Fi$(FPC_RTL)/i386 -Fi$(FPC_RTL)/embedded -Fi$(FPC_RTL)/inc -Fu$(FPC_RTL)/embedded -Us $(FPC_RTL)/embedded/system.pp
	$(FPC) -s -Fi$(FPC_RTL)/i386 -Fi$(FPC_RTL)/inc -TEmbedded -Fu$(FPC_RTL)/inc/ -Fu$(FPC_RTL)/embedded -Sm sh.pas
	$(LD) -g --gc-sections -L. -o sh -T ../layout.ld -Map sh.map sh.o $(FPC_RTL)/embedded/crt.o $(FPC_RTL)/embedded/system.o 
	rm sh.o
clean : 
	rm sh.o
