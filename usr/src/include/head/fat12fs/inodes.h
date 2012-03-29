function fat_inode_lookup (ino : p_inode_t ; dt : p_dentry ) : p_dentry ;external name 'FAT_INODE_LOOKUP';
procedure fat_read_inode (ino : p_inode_t) ;external name 'FAT_READ_INODE';
procedure fat_write_inode ( ino : p_inode_t ) ;external name 'FAT_WRITE_INODE';
procedure fat_delete_inode ( ino : p_inode_t ) ;external name 'FAT_DELETE_INODE';
function find_in_cache ( ino : dword ; sb : p_super_block_t ) : pfat_inode_cache ;external name 'FIND_IN_CACHE';
procedure fat_put_inode ( ino : p_inode_t ) ; external  name 'FAT_PUT_INODE';
function fat_mkdir (ino : p_inode_t ; dentry : p_dentry ; mode : dword ) : dword ;external name 'FAT_MKDIR';
function fat_mknod (ino : p_inode_t ; dentry :p_dentry ; int , mayor , menor : dword ) : dword ;external name 'FAT_MKNOD';
function fat_rename (dentry , ndentry : p_dentry) : dword ; external name 'FAT_RENAME';
function fat_rmdir ( ino : p_inode_t ; dentry : p_dentry ) : dword;external name 'FAT_RMDIR';

function find_fat_dentry ( dt : p_dentry ; const name : string ) : p_dentry ;external name 'FIND_FAT_DENTRY';
var   fat_inode_op : inode_operations;external name 'U_FAT_INODES_FAT_INODE_OP';
