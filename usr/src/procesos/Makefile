#
# Este archivo Compila el modulo encargado del manejo de procesos
# 
#
#

include $(TOP_DIR)../make.rules


all : procesos.o relog.o scheduler.o signal.o sys_procesos.o itimer.o ktimer.o

procesos.o : procesos.pas
	$(FPC) $(FPC_FLAGS) procesos.pas
	$(AS) -o procesos.o procesos.s
	$(RM) *.s
	$(RM) *.ppu


relog.o : relog.pas
	$(FPC) $(FPC_FLAGS) relog.pas
	$(AS) -o relog.o relog.s
	$(RM) *.s
	$(RM) *.ppu


scheduler.o : scheduler.pas
	$(FPC) $(FPC_FLAGS) scheduler.pas
	$(AS) -o scheduler.o scheduler.s
	$(RM) *.s
	$(RM) *.ppu


signal.o : signal.pas
	$(FPC) $(FPC_FLAGS) signal.pas
	$(AS) -o signal.o signal.s
	$(RM) *.s
	$(RM) *.ppu

sys_procesos.o : sys_procesos.pas
	$(FPC) $(FPC_FLAGS) sys_procesos.pas
	$(AS) -o sys_procesos.o sys_procesos.s
	$(RM) *.s
	$(RM) *.ppu


itimer.o : itimer.pas
	$(FPC) $(FPC_FLAGS) itimer.pas
	$(AS) -o itimer.o itimer.s
	$(RM) *.s
	$(RM) *.ppu

ktimer.o : ktimer.pas
	$(FPC) $(FPC_FLAGS) ktimer.pas
	$(AS) -o ktimer.o ktimer.s
	$(RM) *.s
	$(RM) *.ppu


	
	





