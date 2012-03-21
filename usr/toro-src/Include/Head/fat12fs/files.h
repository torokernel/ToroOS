function fat_read_file ( fichero : p_file_t ; cont : dword ; buff : pointer ) : dword ; external;
function fat_readdir (fichero : p_file_t ; buffer : pointer ) : dword ;external;
function fat_file_seek (fichero : p_file_t ; whence , offset : dword ) : dword ;external;
function fat_file_create ( ino : p_inode_t ; dentry : p_dentry ; tm : dword ) : dword ;external;
function fat_file_write (fichero  :p_file_t ; count : dword ; buffer : pointer ) : dword ;external;
procedure fat_file_truncate ( ino : p_inode_t ) ;external;