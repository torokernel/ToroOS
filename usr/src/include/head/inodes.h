procedure mark_inode_dirty (ino : p_inode_t);external name 'MARK_INODE_DIRTY';
procedure Sync_Inodes ;external name 'SYNC_INODES';

function Get_Inode(sb : p_super_block_t ; ino : dword ):p_inode_t;external name 'GET_INODE';
function Put_Inode ( ino:p_inode_t ):dword;external name 'PUT_INODE';
procedure Invalidate_Inode (ino : p_inode_t ) ; external name 'INVALIDATE_INODE';


var Max_inodes : dword ; external name 'U_INODES_MAX_INODES';

{$define inode_lock := lock }
{$define inode_unlock := unlock }


