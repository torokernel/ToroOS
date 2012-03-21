function fat_inode_lookup (ino : p_inode_t ; dt : p_dentry ) : p_dentry ;external;
procedure fat_read_inode (ino : p_inode_t) ;external;
procedure fat_write_inode ( ino : p_inode_t ) ;external;
procedure fat_delete_inode ( ino : p_inode_t ) ;external;
function find_in_cache ( ino : dword ; sb : p_super_block_t ) : pfat_inode_cache ;external;
procedure fat_put_inode ( ino : p_inode_t ) ; external ;
function fat_mkdir (ino : p_inode_t ; dentry : p_dentry ; mode : dword ) : dword ;external;
function fat_mknod (ino : p_inode_t ; dentry :p_dentry ; int , mayor , menor : dword ) : dword ;external;
function fat_rename (dentry , ndentry : p_dentry) : dword ; external;
function fat_rmdir ( ino : p_inode_t ; dentry : p_dentry ) : dword;external;

function find_fat_dentry ( dt : p_dentry ; const name : string ) : p_dentry ;external;
var   fat_inode_op : inode_operations;external name 'U_FAT_INODES_FAT_INODE_OP';
