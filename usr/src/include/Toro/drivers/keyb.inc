const

KEYB_PORT=$60;
KEYB_MAYOR = 32 ;


{SCAN CODE}
EXT_CODE=$e0;


Kbesc=1;

Kbenter=28;
Kbleft=75;
Kbrigth=77;
kbSpace=57;
KbBkSpc=14;
kbUp = 72 ;
kbdown = 80 ;
KbCrtl=29;
KbAlt=56;
KbCapsLock=58;
KbShift=42;
kbF1    =$3B;
kbF2    =$3C;
kbF3    =$3D;
kbF4    =$3E;
kbF5    =$3F;
kbF6    =$40;
kbF7    =$41;
kbF8    =$42;
kbF9    =$43;
kbF10   =$44;
kbF11   =$85;
kbF12   =$86;

CHAR_CODE : array [1..57] of char=
   ('0','1','2','3','4','5','6','7','8','9','0','?','=','0',' ','q','w',
   'e','r','t','y','u','i','o','p','[',']','0','0','a','s','d','f','g','h',
   'j','k','l','¤','{','}','0','0','z','x','c','v','b','n','m',',','.','-',
   '0','*','0',' ');

SHIFT_CODE : array [1..55] of char=
   ('0','!','"','#','$','%','&','/','(',')','=','¨','­',' ',' ','Q','W',
   'E','R','T','Y','U','I','O','P','\','+','0','0','A','S','D','F','G','H',
   'J','K','L','¥','[',']','0','0','Z','X','C','V','B','N','M',';',':','_',
   '0','?');

