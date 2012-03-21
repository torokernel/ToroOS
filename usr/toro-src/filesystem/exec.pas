Unit Exec;

{ * Exec :                                                          *
  *                                                                 *
  * Esta Unidad se encarga de realizar la llamada al sistema        *
  * SYS_EXEC , utiliza archivos COFF.                               *                                                   *
  *                                                                 *
  * Copyright (c) 2003-2006 Matias Vara <matiasvara@yahoo.com>      *
  * All Rights Reserved                                             *
  *                                                                 *
  * Versiones  :                                                    *
  * 07 / 02 / 2005 : Exec() soporta argumentos!!!!                  *
  *                                                                 *
  * 29 / 05 / 2004 : Es modificada la llamada Exec() , los          *
  * segmentos de codigo , datos y pila se ponen en un unico         *
  * hueco de memoria                                                *
  *                                                                 *
  * 19 / 05 / 2004 : Es aplicado el modelo de memoria paginado      *
  * El codigo y datos son puestos en una unica area vmm , no asi el *
  * stack , que se encuentra en STACK_AREA                          *
  *                                                                 *
  * 13 / 04 / 2004 : Primera Version                                *
  *                                                                 *
  *                                                                 *
  *******************************************************************
}

interface

{DEFINE DEBUG}

{$I ../Include/Toro/procesos.inc}
{$I ../Include/Head/asm.h}
{$I ../Include/Head/open.h}
{$I ../Include/Head/inodes.h}
{$I ../Include/Head/super.h}
{$I ../Include/Head/dcache.h}
{$I ../Include/Toro/coff.inc}
{$I ../Include/Toro/buffer.inc}
{$I ../Include/Head/buffer.h}
{$I ../Include/Head/mm.h}
{$I ../Include/Head/scheduler.h}
{$I ../Include/Head/printk_.h}
{$I ../Include/Head/itimer.h}
{$I ../Include/Head/paging.h}
{$I ../Include/Head/vmalloc.h}
{$I ../Include/Head/procesos.h}
{$I ../Include/Head/namei.h}

const MAX_ARG_PAGES = 10 ;


implementation

{$I ../Include/Head/lock.h}

{ * get_args_size : simple funcion que devuelve el tama¤o de los argumentos *
}
function get_args_size (args : pchar) : dword;
var cont : dword ;
begin

cont := 0 ;
If args = nil then exit(1);

while (args^ <> #0) do
 begin
 args += 1;
 If (cont div Page_Size) = Max_Arg_Pages then break
 else cont += 1;
end;
exit(cont + 1);
end;


{ * get_argc : devuelve la cantidad de argumentos pasados * }

function get_argc ( args : pchar) : dword ;
var tmp : dword ;
begin

if args = nil then exit(0);

tmp := 0 ;

{ esto puede seguir hasta el infinito!!! }
while (args^ <> #0) do
 begin
  if args^ = #32 then tmp += 1;
  args += 1;
 end;

tmp += 1 ;

if (args-1)^ = #32 then tmp -= 1 ;

exit(tmp);
end;



{ * Sys_Exec :                                                             *
  *                                                                        *
  * Path : Ruta donde se encuentra el archivo                              *
  * args : Puntero a un array de argunmentos . No utilizado por ahora      *
  * Devuelve : 0 si falla o El pid de la nueva tarea                       *
  *                                                                        *
  * Esta funcion carga en memoria un archivo ejecutable del tipo COFF      *
  * y devuelve el PID del nuevo proceso  , si la operacion no hubiese sido *
  * correcta devuelve 0                                                    *
  * Esta basado en la llamada al sistema sys_exec del kernel de ROUTIX     *
  * Routix / src / syscalls / sys_proc.c                                   *
  * Routix.sourceforge.net                                                 *
  *                                                                        *
  **************************************************************************
}

function sys_exec(path , args : pchar):dword;cdecl ; [public , alias : 'SYS_EXEC'];
var tmp:p_inode_t;
    nr_sec,ver,count:word;
    coff_hd:p_coff_header;
    argccount , ret,count_pg,nr_page,ppid,argc:dword;
    _text,_data,_bbs:coff_sections;
    opt_hd:coff_optheader;
    l:p_coff_sections;
    tmp_fp:file_t;
    buff:array[1..100] of byte;
    new_tarea:p_tarea_struc;
    cr3_save , page,page_args,pagearg_us: pointer;
    nd : pchar ;
    r : dword ;
    k : dword ;

label _exit;
begin

r := contador ;

ppid := Tarea_Actual^.pid;

tmp := name_i(path);

set_errno := -ENOENT ;

{ruta invalida}
If (tmp = nil) then exit(0);

set_errno := -EACCES ;

{el inodo deve tener permisos de ejecucion y de lectura}
if (tmp^.flags and I_XO <> I_XO) and (tmp^.flags and I_RO <> I_RO) then goto _exit ;

set_errno := -ENOEXEC ;

if (tmp^.mode <> dt_Reg) then goto _exit ;

{Se crea un descriptor temporal}
tmp_fp.inodo := tmp;
tmp_fp.f_pos := 0;
tmp_fp.f_op := tmp^.op^.default_file_ops ;


coff_hd:=@buff;

{Leo la cabecera del archivo coff y la mando a un buffer}
ret := tmp_fp.f_op^.read(@tmp_fp,sizeof(coff_header),coff_hd);

set_errno := -EIO ;

{Si hubiese algun error al leer el archivo}
If (ret = 0) then goto _exit ;

set_errno := -ENOEXEC;

{Se chequea el numero magico}
If (coff_hd^.f_magic <> COFF_MAGIC) then goto _exit;

set_errno := -ENOEXEC;

{El archivo COFF devera tener 3 secciones = TEXT , DATA, BBS}
If coff_hd^.f_nscns <> 3 then goto _exit;

ret := tmp_fp.f_op^.read(@tmp_fp,sizeof(coff_optheader),@opt_hd);

{Me posiciono donde se encuentran las cabezas de secciones}
tmp_fp.f_pos := sizeof(coff_header) + coff_hd^.f_opthdr;

nr_sec := coff_hd^.f_nscns;
ver := 0;
l := @buff;

set_errno := -EIO;

while (nr_sec <> 0) do
 begin

 {Leo las secciones}
 ret := tmp_fp.f_op^.read(@tmp_fp,sizeof(coff_sections),l);

 {hubo un error de lectura}
 If (ret = 0) then goto _exit ;

 {Se evalua el tipo de seccion}
 Case l^.s_flags of
 COFF_TEXT:begin
            memcopy(@buff,@_text,sizeof(coff_sections));
            ver:=ver or COFF_TEXT;
            end;
 COFF_DATA:begin
            memcopy(@buff,@_data,sizeof(coff_sections));
            ver:=ver or COFF_DATA;
            end;
 COFF_BBS:begin
            memcopy(@buff,@_bbs,sizeof(coff_sections));
            ver:=ver or COFF_BBS;
            end;
    else  goto _exit ;

 end;
 nr_sec-=1;
end;

 set_errno := -ENOEXEC;

 {Se chequea que se encuentren todas las secciones}
 If ver <> (COFF_BBS or COFF_DATA or COFF_TEXT) then goto _exit ;

 {Se crea el proceso}
 new_tarea := Proceso_Crear(ppid,Sched_RR);

 If (new_tarea=nil) then goto _exit ;

 Mem_Lock ;


 If (_text.s_size + _data.s_size + _bbs.s_size) >=  MM_MEMFREE then
  begin
   Proceso_Eliminar (new_tarea);
   goto _exit ;
  end;


 {Area de Codigo}
 {Aqui tambien se encuentran los datos  y el codigo}

 with new_tarea^.text_area do
  begin
  size := 0 ;
  flags := VMM_WRITE;
  add_l_comienzo := pointer(HIGH_MEMORY);
  add_l_fin := pointer(HIGH_MEMORY - 1);
 end;

 {Stack}
 with new_tarea^.stack_area do
  begin
  size := 0;
  flags := VMM_WRITE;
  add_l_comienzo := pointer(STACK_PAGE);
  add_l_fin := pointer(STACK_PAGE - 1);
 end;

 { tama¤o de los argumentos  }
 argc := get_args_size (args) ;

 { cantidad de argumentos pasados }
 argccount := get_argc(args) ;

 {Solo se soportan 4096 bytes de argumentos }
 page_Args := get_free_kpage ;

  If argc > 1 then
   begin

   {Hay argumentos}
   If argc > Page_Size then argc := Page_Size ;

   {Son copiados los argumentos}
   memcopy(args, page_Args + (Page_size - argc)-1 , argc);
   end
    else
     begin
     {No hay argumentos}

     nd := Page_args;
     nd += Page_size - 2 ;
     nd^ := #0 ;
     end;


 Save_Cr3;
 Load_Kernel_Pdt;

 {Es leido el archivo completo }
 count:=0;
 count_pg:=0;
 nr_page := (_text.s_size + _data.s_size) div Page_Size ;
 If ((_text.s_size + _data.s_size) mod Page_Size ) = 0 then else nr_page+=1;

 tmp_fp.f_pos:=_text.s_scnptr;

 k := contador ;

 repeat
 page := get_free_page;

 If page = nil then
  begin
   vmm_free(new_tarea,@new_tarea^.text_area);
   Proceso_Eliminar(new_tarea);
   Mem_Unlock;
   goto _exit ;
  end;

 count += tmp_fp.f_op^.read(@tmp_fp,Page_Size,page);
 vmm_map(page,new_tarea,@new_tarea^.text_area);
 count_pg+=1;

 until (nr_page = count_pg);
 k := contador - k ;

 {Se verifica que la cantidad leidos sean correctos}
 If count <> (_text.s_size + _data.s_size) then
  begin
   vmm_free(new_tarea,@new_tarea^.text_area);
   vmm_free(new_tarea,@new_tarea^.data_area);
   Proceso_Eliminar(new_tarea);
   Mem_Unlock;
   goto _exit ;
  end;


 {Las areas de datos no inicializados son alocadas}
 vmm_alloc(new_tarea,@new_tarea^.text_area,_bbs.s_size);
 vmm_alloc(new_tarea,@new_tarea^.stack_area,Page_Size);

 {Entrada estandar y salida estandar}
 clone_filedesc(@Tarea_Actual^.Archivos[1],@new_tarea^.Archivos[1]);
 clone_filedesc(@Tarea_Actual^.Archivos[2],@new_tarea^.Archivos[2]);


 {La pagina deve ser de la zona alta y no de la del kernel}
 pagearg_us := get_free_page ;
 memcopy(page_args , pagearg_us , Page_Size);

 {No se necesita mas la pagina}
 free_page (page_args);

 {Se mapea la pagina de argumentos}
 vmm_map(pagearg_us,new_tarea,@new_tarea^.stack_area);

 {Se libera la proteccion de la memoria}
 Mem_Unlock;

 new_tarea^.reg.esp := pointer(new_tarea^.stack_area.add_l_fin - argc)  ;
 new_tarea^.reg.eip := pointer(opt_hd.entry);

 { son pasados los argumentos }
 new_tarea^.reg.eax := argccount ;
 new_tarea^.reg.ebx := longint(new_tarea^.reg.esp) ;
 new_tarea^.reg.ecx := 0 ;


 { la nueva tarea tiene como directorio de trabajo el cwd de la tarea que
 realizo el exec
 }
 Tarea_actual^.cwd^.count += 1 ;
 Tarea_Actual^.cwd^.i_dentry^.count += 1 ;
 new_tarea^.cwd := Tarea_Actual^.cwd ;


 Restore_Cr3;

  {$IFDEF DEBUG}
   printk('/nsys_exec  : Head Section Sizes\n',[],[]);
   printk('/nText  : %d \n',[_text.s_size],[]);
   printk('/nData  : %d \n',[_data.s_size],[]);
   printk('/nBbs :  %d \n',[_bbs.s_size],[]);
   printk('/npid : %d\n',[new_tarea^.pid],[]);
   printk('/nDuracion : %d milis.\n',[contador-r],[]);
   printk('/nTiempo de io : %d milise.\n',[k],[]);
   printk('/nParametros : %d \n',[argccount],[]);
 {$ENDIF}

 add_task (new_tarea);
 put_dentry(tmp^.i_dentry);

 clear_errno;

 exit(new_tarea^.pid);

 _exit :

 {$IFDEF debug}
  printk('/Vexec/n: Error de lectura de archivo\n',[],[]);
 {$ENDIF}

 put_dentry (tmp^.i_dentry);
 exit(0);

end;


end.
