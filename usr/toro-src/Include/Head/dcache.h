
function Alloc_Entry ( ino_p : p_inode_t ; const name : string ) : p_dentry ; external;
procedure Free_Dentry ( dt : p_dentry ) ;external;
procedure Put_dentry (dt : p_dentry ) ; external;
function Alloc_dentry (const name : string ) : p_dentry ;external;

var Max_dentrys : dword ;external name 'U_DCACHE_MAX_DENTRYS';
    dentry_root : p_dentry ; external name 'U_DCACHE_DENTRY_ROOT';
