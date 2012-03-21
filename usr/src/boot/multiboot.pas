Unit multiboot;

{ * Multiboot :                                                         *
  *                                                                     *
  * Aqui es capturada la info dada por el booteador sobre el estandar   *
  * multiboot y es certificada por ahora solo verifica el numero magico *
  * en el futuro controlara el tama¤o del kernel                        *
  *                                                                     *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>          *
  * All Rights Reserved                                                 *
  *                                                                     *
  * Versiones :                                                         *
  *                                                                     *
  * 14 / 07 / 2005 : Primera Version                                    *
  *                                                                     *
  *                                                                     *
  ***********************************************************************
}


interface


{$I ../include/toro/multiboot.inc}
{$I ../include/head/printk_.h}
{$I ../include/head/asm.h}

implementation


{ * multiboot_init :                                                    *
  *                                                                     *
  * llamada al comienzo del kernel identifica que se haya booteado      *
  * con un booteador que se encuentre con el standar multiboot          *
  *                                                                     *
  ***********************************************************************
}
procedure multiboot_init (mbinfo : pmultiboot_info_t ; mbmagic : dword ) ; stdcall ; [public , alias : 'MULTIBOOT_INIT'];
begin
if (mbmagic <> Multiboot_Bootloader_Magic ) then Panic ('/nBooteador no aceptado bajo el standar multiboot\n');
end;


end.
