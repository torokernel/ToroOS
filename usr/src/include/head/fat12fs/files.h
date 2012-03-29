function fat_read_file ( fichero : p_file_t ; cont : dword ; buff : pointer ) : dword ; external name 'FAT_READ_FILE';
function fat_readdir (fichero : p_file_t ; buffer : pointer ) : dword ;external name 'FAT_READDIR';
function fat_file_seek (fichero : p_file_t ; whence , offset : dword ) : dword ;external name 'FAT_FILE_SEEK';
function fat_file_create ( ino : p_inode_t ; dentry : p_dentry ; tm : dword ) : dword ;external name 'FAT_FILE_CREATE';
function fat_file_write (fichero  :p_file_t ; count : dword ; buffer : pointer ) : dword ;external name 'FAT_FILE_WRITE';
procedure fat_file_truncate ( ino : p_inode_t ) ;external name 'FAT_FILE_TRUNCATE';
