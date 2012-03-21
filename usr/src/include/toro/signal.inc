

const

Max_Signal = 31;

Sig_Morir   = 0;
Sig_Detener = 1;
Sig_Alarm   = 2;
Sig_ili  = 3;
Sig_Segv = 4;
Sig_DivE = 5 ;
Sig_FpuE = 6 ;
Sig_BrkPoint = 7 ;
Sig_OverFlow = 8 ;
Sig_Reanudar = 12 ;
Sig_Hijo = 13 ;
Sig_Usr  = 30;
Sig_Usr1 = 31;

Sig_Name : array[0..8] of string[20] = ('Sig_Morir'#0,' ',' ','Sig_ili'#0,
                                        'Sig_Segv'#0 , 'Sig_DivE'#0 ,
                                        'Sig_FpuE'#0 , 'Sig_BrkPoint'#0 ,
                                        'Sig_Overflow'#0 );
