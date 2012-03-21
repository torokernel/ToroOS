include $(TOP_DIR)../../toro-src/make.rules

all : mkdir.o

mkdir.o : mkdir.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  mkdir.pas
	$(RENAME) mkdir.exe mkdir
	$(MV) mkdir ..\..\..\bin\mkdir