include $(TOP_DIR)../../toro-src/make.rules

all : sh.o

sh.o : sh.pas
	$(FPC)  -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  sh.pas
	$(RENAME) sh.exe sh
	$(MV) sh ..\..\..\bin\sh
	