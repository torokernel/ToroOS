procedure mark_inode_dirty (ino : p_inode_t);external;
procedure Sync_Inodes ;external;

function Get_Inode(sb : p_super_block_t ; ino : dword ):p_inode_t;external;
function Put_Inode ( ino:p_inode_t ):dword;external;
procedure Invalidate_Inode (ino : p_inode_t ) ; external name 'INVALIDATE_INODE';


var Max_inodes : dword ; external name 'U_INODES_MAX_INODES';

{$define inode_lock := lock }
{$define inode_unlock := unlock }


