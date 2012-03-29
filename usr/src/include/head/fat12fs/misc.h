function get_sector_fat (sb : p_super_block_t ; sector : dword) : word ;external name 'GET_SECTOR_FAT';
function get_free_cluster( sb : p_super_block_t)  : word ;external name 'GET_FREE_CLUSTER';
function find_dir ( bh : p_buffer_head ; name : pchar ; var res : pdirectory_entry ) : dword ;external name 'FIND_DIR';
function find_rootdir ( bh : p_buffer_head ; name : pchar ; var res : pdirectory_entry ) : dword ;external name 'FIND_ROOTDIR';
function fat_name ( const name : string ; destino : pointer ) : dword  ; external name 'FAT_NAME';
function date_dos2unix ( time  , date : word ) : dword ;external name 'DATE_DOS2UNIX'; 
procedure date_unix2dos ( unix_date : dword ; var time  : word ;  var date : word) ;external name 'DATE_UNIX2DOS';
procedure unix_name ( fatname : pchar ; var destino : string ) ; external name 'UNIX_NAME';
procedure unicode_to_unix ( longname : pvfatdirectory_entry ; var destino : string) ; external name 'UNICODE_TO_UNIX';
function add_rootentry (ino : p_inode_t ; entry : pdirectory_entry ) : dword ;external name 'ADD_ROOTENTRY';
function add_direntry (ino : p_inode_t ; entry : pdirectory_entry ) : dword ;external name 'ADD_DIRENTRY';
function add_free_cluster (ino : p_inode_t) : dword ;external name 'ADD_FREE_CLUSTER';
procedure free_cluster ( sb : p_super_block_t ; cluster : dword) ;external name 'FREE_CLUSTER';
procedure put_sector_fat (sb : p_super_block_t ; sector : dword ; val : word ) ; external name 'PUT_SECTOR_FAT';

