include $(TOP_DIR)../../toro-src/make.rules

all : cat.o

cat.o : cat.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  cat.pas
	$(RENAME) cat.exe cat
	$(MV) cat ..\..\..\bin\cat