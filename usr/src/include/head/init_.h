procedure Init_ ; external name 'INIT_';


{$DEFINE Init_Task :=
 Init_proc := Proceso_Crear(1,Sched_RR);
 Init_Page:= get_free_page;
 stack:= get_free_page;

 umapmem(stack,pointer(HIGH_MEMORY),Init_Proc^.dir_page,Present_Page  or Write_Page or User_mode);
 umapmem(Init_Page,pointer(HIGH_MEMORY+Page_Size),Init_Proc^.dir_page,Present_Page or User_mode);

 memcopy(@Init_,Init_Page,Page_Size);


With Init_Proc^ do
 begin
 text_area.add_l_comienzo := pointer(HIGH_MEMORY + Page_Size);
 text_area.add_l_fin := pointer(HIGH_MEMORY + 2 * Page_Size);
 text_area.size := Page_Size;
 text_area.flags := VMM_READ;

 stack_area.add_l_comienzo := pointer(HIGH_MEMORY);
 stack_area.add_l_fin := pointer(HIGH_MEMORY + Page_Size - 1);
 stack_area.size := Page_Size;
 stack_area.flags := VMM_WRITE;

 reg.eip:= pointer(HIGH_MEMORY + Page_Size);
 reg.esp := pointer(HIGH_MEMORY + Page_Size -1);
end;

add_task(Init_Proc);

ttyino := kmalloc(sizeof(inode_t));
ttyfile := @Init_proc^.Archivos[1];

keybino := kmalloc (sizeof(inode_t));
keybfile := @Init_proc^.Archivos[2];

ttyino^.mode := dt_chr ;
ttyino^.flags := I_RO or I_WO ;
ttyino^.rmayor := tty_mayor ;
ttyino^.rmenor := 0  ;
ttyfile^.f_op := chr_dev[tty_mayor].fops ;
ttyfile^.inodo := ttyino ;
ttyfile^.f_mode := O_RDWR ;

ttyfile^.f_pos := y * 160 + x * 2 ;
keybino^.mode := dt_chr ;
keybino^.flags := I_RO or I_WO ;
keybino^.rmayor := keyb_mayor ;
keybino^.rmenor := 0  ;
keybfile^.f_op := chr_dev[keyb_mayor].fops ;

keybfile^.inodo := keybino ;
keybfile^.f_mode := O_RDWR ;

}
