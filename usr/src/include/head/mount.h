function sys_mount(path,path_mount,name:pchar):dword;cdecl;external name 'SYS_MOUNT';
function sys_unmount(path:pchar):dword;cdecl;external name 'SYS_UNMOUNT';
procedure sys_mountroot ; cdecl ;external name 'SYS_MOUNTROOT';
