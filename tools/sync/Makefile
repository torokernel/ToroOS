include $(TOP_DIR)../../toro-src/make.rules

all : sync.o

sync.o : sync.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  sync.pas
	$(RENAME) sync.exe sync
	$(MV) sync ..\..\..\bin\sync