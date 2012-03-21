
const
      INTEL_ID=$756e6547;
      AMD_ID  =$68747541;
      INTEL=1;
      AMD  =2;



type

 struc_cpu=record
 Marca:word;
 Family:dword;
 Model:dword;
 Types:dword;


end;
