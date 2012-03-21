

 const

  {Descriptores del sistema}
  Kernel_Data_Sel = $10;
  Kernel_Code_Sel = $8;
  {Descriptores de Usuario}
  User_Data_Sel = $1B;
  User_Code_Sel =$23;

  {Posiciones en memoria}
  Gdt_Nueva = $2000;
  Idt_Pos   = 0;

  {Numero de descriptores validos}
  Max_Sel=50;
  Max_Int=55;

  {Descriptores del Sistema}
  Sistema_Datos=$92;
  Sistema_Codigo=$9A;

  {Descriptores de Usuario}
  Usuario_Datos=$F2;
  Usuario_Codigo=$FA;

  {Estructura del registro Gdtr}
  Type
  struc_GDTR =record
  limite :word;
  base_lin:pointer;
  end;

  {Estructura de un descriptor}
  Type
  struc_descriptor=record
  limite_0_15:word;
  base_0_15:word;
  base_16_23:byte;
  tipo:byte;
  limite_16_23:byte;
  base_24_31:byte;
  end;

 {Puntero a la Gdt}
 Type
 p_struc_GDT=^struc_GDT;
 struc_GDT = array[0..Max_Sel-1] of struc_descriptor;

