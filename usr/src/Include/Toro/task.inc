
 const
 TAM_TSS=103;                  {Tamano de un TSS }

 TSS_SIST_LIBRE=$89;               {TSS de sistema libre}
 TSS_SIST_OCUP=$8B;                {TSS de sistema ocupado}

 TSS_USER_LIBRE=$E9;               {TSS de Anillo 3 libre}
 TSS_USER_OCUP =$EB;               {TSS de Anillo 3 ocupado }

 TSK_GATE_SIST=$85;                {TASK GATE de Anillo 0}
 TSK_GATE_USER=$E5;                {TASK GATE de Anillo 3}

 INT_GATE_SIST=$8E;                {INT GATE de Anillo 0 }
 INT_GATE_USER=$EE;                {INT GATE de Anillo 3 }


 type
  struc_intr_gate=record
  entrada_0_15:word;
  selector:word;                    {Aqui deve ir Selector a TSS}                          {si es una TASK GATE        }
  nu:byte;
  tipo:byte;
  entrada_16_31:word;
 end;

 type
 p_intr_gate=^struc_intr_gate;

 p_tss_struc=^tss_struc;

 TSS_STRUC=record
      back_link, __blh   : word;
      esp0               : pointer;
      ss0, __ss0         : word;
      esp1               : dword;
      ss1, __ss1         : word;
      esp2               : dword;
      ss2, __ss2         : word;
      cr3                : pointer;
      eip                : pointer;
      eflags             : dword;
      eax, ecx, edx, ebx : dword;
      esp, ebp           : pointer;
      esi, edi           : dword;
      es, __es           : word;
      cs, __cs           : word;
      ss, __ss           : word;
      ds, __ds           : word;
      fs, __fs           : word;
      gs, __gs           : word;
      ldt, __ldt         : word;
      trace, bitmap      : word;
 END;






