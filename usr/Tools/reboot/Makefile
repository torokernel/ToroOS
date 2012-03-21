include $(TOP_DIR)../../toro-src/make.rules

all : reboot.o

reboot.o : reboot.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  reboot.pas
	$(RENAME) reboot.exe reboot
	$(MV) reboot ..\..\..\bin\reboot