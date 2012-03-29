procedure idt_init;external name 'IDT_INIT';
procedure set_int_gate(int:byte;handler:pointer);external name 'SET_INT_GATE';
procedure set_int_gate_user(int:byte;handler:pointer);external name 'SET_INT_GATE_USER';


