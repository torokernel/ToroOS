

procedure Memcopy(origen , destino :pointer;tamano:dword);external name 'MEMCOPY';
procedure Debug(Valor:dword);external name 'DEBUG';
function  Bit_Test(Val:pointer;pos:dword):boolean;external name 'BIT_TEST';
procedure Bit_Set(ptr_dw:pointer;pos:dword);external name 'BIT_SET';
procedure Bit_Reset(Cadena:pointer;pos:dword);external name 'BIT_RESET';

procedure Panic(Error:pchar);external name 'PANIC';

function  Mapa_Get(Mapa:pointer;Limite:dword):word;external name 'MAPA_GET';
procedure Limpiar_Array(p_array:pointer;fin:word);external name 'LIMPIAR_ARRAY';
procedure Reboot;external name 'REBOOT';
function get_datetime  : dword ;external name 'GET_DATETIME';

{$DEFINE cerrar := asm cli ; end;}
{$DEFINE abrir := asm sti ; end ;}
{$DEFINE save_flags := asm pushfd; end;}
{$DEFINE restore_flags := asm popfd; end;}
{$DEFINE LoadKernelData := asm mov ax , kernel_data_sel ; mov ds , ax ; mov es , ax ; end;}
{$DEFINE Aqui_Paso := printk('AQUI PASO!!!!\n',[],[]);}
