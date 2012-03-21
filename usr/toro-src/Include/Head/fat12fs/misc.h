function get_sector_fat (sb : p_super_block_t ; sector : dword) : word ;external;
function get_free_cluster( sb : p_super_block_t)  : word ;external;
function find_dir ( bh : p_buffer_head ; name : pchar ; var res : pdirectory_entry ) : dword ;external;
function find_rootdir ( bh : p_buffer_head ; name : pchar ; var res : pdirectory_entry ) : dword ;external;
function fat_name ( const name : string ; destino : pointer ) : dword  ; external;
function date_dos2unix ( time  , date : word ) : dword ;external;
procedure date_unix2dos ( unix_date : dword ; var time  : word ;  var date : word) ;external;
procedure unix_name ( fatname : pchar ; var destino : string ) ; external;
procedure unicode_to_unix ( longname : pvfatdirectory_entry ; var destino : string) ; external;
function add_rootentry (ino : p_inode_t ; entry : pdirectory_entry ) : dword ;external;
function add_direntry (ino : p_inode_t ; entry : pdirectory_entry ) : dword ;external;
function add_free_cluster (ino : p_inode_t) : dword ;external;
procedure free_cluster ( sb : p_super_block_t ; cluster : dword) ;external;
procedure put_sector_fat (sb : p_super_block_t ; sector : dword ; val : word ) ; external ;

