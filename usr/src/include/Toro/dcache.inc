
{entrada dentro del cache de nombre }


dentry = record
ino : p_inode_t ;
state : dword ;
len : dword;
flags : dword ;
count : dword;
l_count : dword;
name : string ;
parent : p_dentry ;
down_tree : p_dentry ;
down_mount_tree : p_dentry;
next_dentry : p_dentry ;
prev_dentry : p_dentry ;
end;

const

st_vacio = 2;
st_incache = 3;

