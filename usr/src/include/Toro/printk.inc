type
struc_consola=record
car:char;
form:byte;
end;


const VIDEO_OFF=$B8000;

   hex_char : array[0..15] of char = ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
   color : byte = 7 ;
