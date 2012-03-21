include $(TOP_DIR)../../toro-src/make.rules

all : echo.o

echo.o : echo.pas
	$(FPC) -Sm -k-Ttext -k0x40000000 -k--oformat -kcoff-go32  echo.pas
	$(RENAME) echo.exe echo
	$(MV) echo ..\..\..\bin\echo