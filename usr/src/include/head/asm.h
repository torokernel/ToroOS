

procedure Memcopy(origen , destino :pointer;tamano:dword);external;
procedure Debug(Valor:dword);external;
function  Bit_Test(Val:pointer;pos:dword):boolean;external;
procedure Bit_Set(ptr_dw:pointer;pos:dword);external;
procedure Bit_Reset(Cadena:pointer;pos:dword);external;

procedure Panic(Error:string);external;

function  Mapa_Get(Mapa:pointer;Limite:dword):word;external;
procedure Limpiar_Array(p_array:pointer;fin:word);external;
procedure Reboot;external;
function get_datetime  : dword ;external;

{$DEFINE cerrar := asm cli ; end;}
{$DEFINE abrir := asm sti ; end ;}
{$DEFINE save_flags := asm pushfd; end;}
{$DEFINE restore_flags := asm popfd; end;}
{$DEFINE LoadKernelData := asm mov ax , kernel_data_sel ; mov ds , ax ; mov es , ax ; end;}
{$DEFINE Aqui_Paso := printk('AQUI PASO!!!!\n',[],[]);}
