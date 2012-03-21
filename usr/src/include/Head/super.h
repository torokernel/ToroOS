function get_super (Mayor , Menor : dword ) : p_super_block_t ;external;
function read_super ( Mayor , Menor , flags : dword ; fs : p_file_system_type ) : p_super_block_t ;external;
function get_fstype ( const name : string ) : p_file_system_type ;external;

var i_root : p_inode_t ; external name 'U_SUPER_BLOQUE_I_ROOT';


{$define super_lock := lock}
{$define super_unlock := unlock}
