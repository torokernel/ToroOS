

type

t_fsid = record
id : dword ;
name : string[20];

end;


const

fsid : array [1..2] of t_fsid = ((id : 1 ; name : 'torofs'),
                                (id : 2 ; name : 'fatfs'));







