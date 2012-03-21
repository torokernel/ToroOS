include $(TOP_DIR)../../toro-src/make.rules

all : mknod.o

mknod.o : mknod.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  mknod.pas
	$(RENAME) mknod.exe mknod
	$(MV) mknod ..\..\..\bin\mknod