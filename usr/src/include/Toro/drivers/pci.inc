
const
   PCI_SLOTS = 32; { Nb de slots par bus PCI }
   MAX_PCI=32;
   PCI_CONF_PORT_INDEX = $CF8;
   PCI_CONF_PORT_DATA  = $CFC;

   PCI_CONFIG_INTR        = 15;
   PCI_CONFIG_VENDOR      = 0;
   PCI_CONFIG_CLASS_REV   = 2;
   PCI_CONFIG_BASE_ADDR_0 = 4;


type

   T_pci_device = record
      nb         : dword;
      bus        : dword;
      dev        : dword;
      func       : dword;
      irq        : dword;
      io         : array [0..5] of dword;
      vendor_id  : dword;
      device_id  : dword;
      main_class : dword;
      sub_class  : dword;
   end;

   p_pci_device = ^t_pci_device;


   T_bios32 = record
      magic : dword;
      phys_entry : dword;
      revision : byte;
      length : byte;
      crc : char;
      reserved : array [1..5] of byte;
   end;

   vendor = record
      id   : dword;
      name : string[30];
   end;


   pci_class = record
      id   : dword;
      name : string[30];
   end;


   pci_storage_subclass = record
      id   : dword;
      name : string[30];
   end;


   pci_network_subclass = record
      id   : dword;
      name : string[30];
   end;


   pci_display_subclass = record
      id   : dword;
      name : string[30];
   end;


   pci_multimedia_subclass = record
      id   : dword;
      name : string[30];
   end;


   pci_memory_subclass = record
      id   : dword;
      name : string[30];
   end;


   pci_bridge_subclass = record
      id   : dword;
      name : string[30];
   end;


   pci_serial_subclass = record
      id   : dword;
      name : string[30];
   end;


const
   vendors : array[1..38] of vendor =
      ((id : $0E11 ; name : 'Compaq ' + #0),
       (id : $1000 ; name : 'NCR ' + #0),
       (id : $1002 ; name : 'ATI ' + #0),
       (id : $1004 ; name : 'VLSI ' + #0),
       (id : $100C ; name : 'Tseng ' + #0),
       (id : $100E ; name : 'Weitek ' + #0),
       (id : $1011 ; name : 'DEC ' + #0),
       (id : $1013 ; name : 'Cirrus Logic ' + #0),
       (id : $1014 ; name : 'IBM ' + #0),
       (id : $1022 ; name : 'AMD ' + #0),
       (id : $1023 ; name : 'Trident ' + #0),
       (id : $1025 ; name : 'Acer ' + #0),
       (id : $102B ; name : 'Matrox ' + #0),
       (id : $1033 ; name : 'NEC ' + #0),
       (id : $1036 ; name : 'Future Corporation ' + #0),
       (id : $103C ; name : 'HP ' + #0),
       (id : $104A ; name : 'Thomson ' + #0),
       (id : $104B ; name : 'Buslogic ' + #0),
       (id : $104C ; name : 'Texas Instruments ' + #0),
       (id : $1057 ; name : 'Motorola ' + #0),
       (id : $105A ; name : 'Promise Technology ' + #0),
       (id : $105D ; name : 'Number 9 ' + #0),
       (id : $1060 ; name : 'UMC ' + #0),
       (id : $106B ; name : 'Apple ' + #0),
       (id : $1078 ; name : 'Cyrix ' + #0),
       (id : $108E ; name : 'Sun ' + #0),
       (id : $109E ; name : 'Brooktree Corp. ' + #0),
       (id : $10B7 ; name : '3Com ' + #0),
       (id : $10B8 ; name : 'SMC ' + #0),
       (id : $10B9 ; name : 'ALi ' + #0),
       (id : $10DE ; name : 'Nvidia ' + #0),
       (id : $10EC ; name : 'Realtek ' + #0),
       (id : $1102 ; name : 'Creative Labs ' + #0),
       (id : $1106 ; name : 'VIA Technologies Inc. ' + #0),
       (id : $121A ; name : '3DFX ' + #0),
       (id : $134D ; name : 'Pctel Inc. ' + #0),
       (id : $5333 ; name : 'S3 ' + #0),
       (id : $8086 ; name : 'Intel ' + #0) );


   pci_classes : array[1..18] of pci_class =
      ( (id : $00 ; name : 'pre v2.0' + #0),
        (id : $01 ; name : 'mass storage controller' + #0),
	(id : $02 ; name : 'network interface' + #0),
	(id : $03 ; name : 'display controller' + #0),
	(id : $04 ; name : 'multimedia controller' + #0),
	(id : $05 ; name : 'memory controller' + #0),
	(id : $06 ; name : 'bridge controller' + #0),
	(id : $07 ; name : 'communications controller' + #0),
	(id : $08 ; name : 'base system peripheral' + #0),
	(id : $09 ; name : 'input controller' + #0),
	(id : $0A ; name : 'docking station' + #0),
	(id : $0B ; name : 'processor' + #0),
	(id : $0C ; name : 'serial bus controller' + #0),
	(id : $0D ; name : 'wireless interface' + #0),
	(id : $0E ; name : 'intelligent I/O controller' + #0),
	(id : $0F ; name : 'satellite interface' + #0),
	(id : $10 ; name : 'encryption/decryption' + #0),
	(id : $11 ; name : 'digital signal processor' + #0) );


   pci_storage_subclasses : array[1..5] of pci_storage_subclass =
      ( (id : $00 ; name : 'SCSI controller' + #0),
        (id : $01 ; name : 'IDE controller' + #0),
	(id : $02 ; name : 'floppy controller' + #0),
	(id : $04 ; name : 'RAID controller' + #0),
	(id : $80 ; name : 'Other controller' + #0));


   pci_network_subclasses : array[1..5] of pci_network_subclass =
      ( (id : $00 ; name : 'ethernet interface' + #0),
        (id : $01 ; name : 'token ring interface' + #0),
	(id : $02 ; name : 'FDDI interface' + #0),
	(id : $03 ; name : 'ATM interface' + #0),
	(id : $04 ; name : 'ISDN interface' + #0) );


   pci_display_subclasses : array[1..3] of pci_display_subclass =
      ( (id : $00 ; name : 'VGA controller' + #0),
        (id : $01 ; name : 'XGA controller' + #0),
	(id : $02 ; name : '3D controller' + #0) );


   pci_multimedia_subclasses : array[1..3] of pci_multimedia_subclass =
      ( (id : $00 ; name : 'video controller' + #0),
        (id : $01 ; name : 'audio controller' + #0),
	(id : $02 ; name : 'telephony controller' + #0) );


   pci_memory_subclasses : array[1..2] of pci_memory_subclass =
      ( (id : $00 ; name : 'RAM controller' + #0),
        (id : $01 ; name : 'flash controller' + #0) );


   pci_bridge_subclasses : array[1..10] of pci_bridge_subclass =
      ( (id : $00 ; name : 'host ' + #0),
        (id : $01 ; name : 'ISA ' + #0),
	(id : $02 ; name : 'EISA ' + #0),
	(id : $03 ; name : 'MCA ' + #0),
	(id : $04 ; name : 'PCI ' + #0),
	(id : $05 ; name : 'PCMCIA ' + #0),
	(id : $06 ; name : 'nubus ' + #0),
	(id : $07 ; name : 'cardbus ' + #0),
	(id : $08 ; name : 'raceway ' + #0),
	(id : $80 ; name : 'other' + #0));


   pci_serial_subclasses : array[1..3] of pci_serial_subclass =
      ( (id : $00 ; name : 'IEEE 1394 controller' + #0),
        (id : $03 ; name : 'USB controller' + #0),
	(id : $04 ; name : 'fibre channel controller' + #0) );
