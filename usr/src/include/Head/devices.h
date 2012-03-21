
procedure Devices_Init;external;
procedure Register_Chrdev(nb : byte ; name : pchar ; fops : p_file_ops);external;
procedure Register_Blkdev (nb : byte ; name : pchar ; fops : p_file_ops);external;
function Register_Filesystem (fs : p_file_system_type) : dword ;external;


var Blk_Dev:array[1..Nr_Blk] of device ;external name 'U_DEVICES_BLK_DEV';
    Chr_Dev:array[Nr_Blk..Nr_Chr] of device ;external name 'U_DEVICES_CHR_DEV';
    fs_type : p_file_system_type ; external name 'U_DEVICES_FS_TYPE';
