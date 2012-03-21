Unit Pci;

{ * Pci:                                                                 *
  *                                                                      *
  * Esta Unidad detecta los dispositivos dentro del bus PCI  y los       *
  * coloca en el array pci_devices , el codigo fue extraido de Delhineos *
  *                                                                      *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>           *
  * All Rights Reserved                                                  *
  *                                                                      *
  * Versiones :                                                          *
  *                                                                      *
  * 3 / 05 / 2005 : Ultima Revision                                      *
  *                                                                      *
  ************************************************************************

}

interface

{$I ../../Include/Head/asm.h}
{$I ../../Include/Head/printk_.h}
{$I ../../Include/Toro/drivers/pci.inc}
{$I ../../Include/Toro/page.inc}

procedure check_pci_devices;
function  pci_device_count (bus : dword) : dword;
function  pci_read_dword (bus, device, fonction, regnum : dword) : dword;
procedure scanpci (bus : dword);



var
   pci_devices      : array[0..MAX_PCI] of t_pci_device;
   actual_nb    : dword;
   nm_pci_dev:dword;


implementation


{$I ../../Include/Head/ioport.h}


{ * Pci_Init :                                                         *
  *                                                                    *
  * Procedimiento que se inicializa la tabla de dispostivos que se     *
  * encuentran sobre el bus pci                                        *
  *                                                                    *
  **********************************************************************
}
procedure pci_init;[public , alias :'PCI_INIT'];
var base:^T_Bios32;
    found:boolean;
begin

base := pointer($E0000);
found := false;
nm_pci_dev := 0;

while not (found) or (base < pointer($100000)) do
 begin
 If base^.magic = $5F32335F then
  begin
   found:=true;
   printk('/nIniciando pcibus ... /VOk\n',[],[]);
   check_pci_devices;
   exit;
  end;

base += 1;
end;

printk('/nIniciando pcibus ... /Rfault\n',[],[]);
end;



procedure scanpci (bus : dword);

var
   bug_tmp    : dword;
   dev, read  : dword;
   vendor_id  : dword;
   device_id  : dword;
   iobase, i  : dword;
   ipin, ilin : dword;
   func       : dword;
   main_class, sub_class : dword;

begin

   for dev := 0 to 31 do
      begin
         for func := 0 to 7 do
	 begin
            read := pci_read_dword(bus, dev, func, PCI_CONFIG_VENDOR);
	    vendor_id := read and $FFFF;
	    device_id := read div 65536; { device_id := read shr 16 }

	    if (func = 0) then
	        bug_tmp := device_id
	    else if (device_id = bug_tmp) then
	             break;

	    if ((vendor_id < $FFFF) and (vendor_id <> 0)) then
	       begin
	          read := pci_read_dword(bus, dev, func, PCI_CONFIG_CLASS_REV);
	          main_class := read div 16777216; { class := read shr 24 }
	          sub_class := (read div 65536) and $FF;



	          iobase := 0;

	          for i := 0 to 5 do
	             begin
		        read := pci_read_dword(bus, dev, func, PCI_CONFIG_BASE_ADDR_0 + i);
		        if (read and 1 = 1) then
		           begin
			      iobase := read and $FFFFFFFC;
			      pci_devices[actual_nb].io[i] := iobase;
                           end;
                     end;

	          read := pci_read_dword(bus, dev, func, PCI_CONFIG_INTR);
	          ipin := (read div 256) and $FF;
	          ilin := read and $FF;

                    with  pci_devices[actual_nb] do
                     begin
                     bus:= bus;
                     dev:= dev;
                     func:= func;
                     irq := ilin;
                     vendor_id:= vendor_id;
                     device_id:= device_id;
		     main_class:=main_class;
		     sub_class:= sub_class;

                     actual_nb := actual_nb + 1;
                     end;
	       end;
	 end;
      end;
end;


function pci_read_dword (bus, device, fonction, regnum : dword) : dword;

var
   send : dword;

begin
   asm
      mov   eax, $80000000
      mov   ebx, bus
      shl   ebx, 16
      or    eax, ebx
      mov   ebx, device
      shl   ebx, 11
      or    eax, ebx
      mov   ebx, fonction
      shl   ebx, 8
      or    eax, ebx
      mov   ebx, regnum
      shl   ebx, 2
      or    eax, ebx
      mov   send, eax
   end;

   enviar_dw(send,PCI_CONF_PORT_INDEX);
   pci_read_dword := leer_dw(PCI_CONF_PORT_DATA);

end;




function pci_device_count (bus : dword) : dword;

var
   vendor_id  : dword;
   device_id  : dword;
   dev, devs  : dword;
   func, read : dword;
   bug_tmp    : dword;

begin

   devs := 0;

   for dev:=0 to (PCI_SLOTS - 1) do
      begin
         for func:=0 to 7 do
	 begin
            read := pci_read_dword(bus, dev, func, PCI_CONFIG_VENDOR);
	    vendor_id := read and $FFFF;
	    device_id := read div 65536;

	    { Correction du bug (voir procédure scanpci) }

	    if (func = 0) then
	       begin
	          bug_tmp := device_id;
	       end
	    else
	       begin
	          if (device_id = bug_tmp) then
		     break;
	       end;

	    { Fin correction du bug }

	    if ((vendor_id < $FFFF) and (vendor_id <> 0)) then
	       begin
	          devs := devs + 1;
	       end;
	 end;
      end;

   pci_device_count := devs;

end;



function pci_lookup (vendorid, deviceid : dword) : p_pci_device; [public, alias : 'PCI_LOOKUP'];
var tmp:dword;
begin

   if (nm_pci_dev = 0 ) then exit;
 for tmp:= 0 to Max_PCI do
 begin
      If (pci_devices[tmp].vendor_id=vendorid) and  (pci_devices[tmp].device_id=deviceid) then
      begin
      pci_lookup:=@pci_devices[tmp];
      exit
      end;
 end;

end;



procedure check_pci_devices;

var
   devices  : array[0..3] of dword;
   i        : dword;

begin

   for i := 0 to 3 do
      begin
         devices[i] := pci_device_count(i);
	 nm_pci_dev := nm_pci_dev + devices[i];
      end;


   actual_nb        := 0;

   for i:=0 to 3 do
      begin
         if (devices[i] > 0) then scanpci(i);
      end;
end;




end.




