const
  Status_Port : array[0..1] of byte = ($20,$A0);
  Mask_Port : array[0..1] of byte = ($21,$A1);

  EOI = $20;
  PIC_MASK:array [0..7] of byte =(1,2,4,8,16,32,64,128);
