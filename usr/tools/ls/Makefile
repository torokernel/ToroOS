include $(TOP_DIR)../../toro-src/make.rules

all : ls.o

ls.o : ls.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  ls.pas
	$(RENAME) ls.exe ls
	$(MV) ls ..\..\..\bin\ls