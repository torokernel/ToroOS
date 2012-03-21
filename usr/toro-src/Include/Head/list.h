{ * Aqui son declarados los macros utilizados para las colas ligadas ,   *
  * para esto se deven definir 4 simbolos :                              *
  * Use_Tail que le indica el compilador q agregue a  este codigo ,      *
  * nodo_struc , q es la estructura de cada nodo en la cola ligada q por *
  * lo general es uno del tipo puntero  , next_nodo  , q es el nombre    *
  * del puntero al siguiente nodo en la estructura nodo_struct igual q   *
  * prev_nodo , y nodo_tail q es el puntero al primer elemento de la     *
  * cola                                                                 *
  *                                                                      *
  ************************************************************************
}

{$IFDEF Use_Tail Then}


{$IFDEF nodo_tail Then}

procedure Push_Node(Nodo : nodo_struct);inline;
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_nodo := Nodo ;
 nodo^.prev_nodo := Nodo ;
 exit;
end;

nodo^.prev_nodo := nodo_tail^.prev_nodo ;
nodo^.next_nodo := nodo_tail ;
nodo_tail^.prev_nodo^.next_nodo := Nodo ;
nodo_tail^.prev_nodo := nodo ;
end;


procedure Pop_Node(Nodo : nodo_struct );inline;
begin

If (nodo_tail= nodo) and (nodo_tail^.next_nodo = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_nodo := nil;
 nodo^.next_nodo := nil;
 exit;
end;

nodo^.prev_nodo^.next_nodo := nodo^.next_nodo ;
nodo^.next_nodo^.prev_nodo := nodo^.prev_nodo ;
end;

{$ELSE}

procedure Push_Node(Nodo : nodo_struct;var Nodo_Tail : nodo_struct);inline;
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_nodo := Nodo ;
 nodo^.prev_nodo := Nodo ;
 exit;
end;

nodo^.prev_nodo := nodo_tail^.prev_nodo ;
nodo^.next_nodo := nodo_tail ;
nodo_tail^.prev_nodo^.next_nodo := Nodo ;
nodo_tail^.prev_nodo := nodo ;
end;



procedure Push_Node_First ( nodo : nodo_struct ; var Nodo_Tail : nodo_struct) ; inline ;
begin

If nodo_tail = nil then
 begin
 nodo_tail := Nodo ;
 nodo^.next_nodo := Nodo ;
 nodo^.prev_nodo := Nodo ;
 exit;
end;

nodo^.prev_nodo := nodo_tail^.prev_nodo;
nodo^.next_nodo := nodo_tail ;
nodo_tail^.prev_nodo^.next_nodo := nodo;
nodo_tail^.prev_nodo := nodo ;
nodo_tail := nodo ;
end;


procedure Pop_Node(Nodo : nodo_struct;var Nodo_tail : nodo_struct);inline;
begin

If (nodo_tail= nodo) and (nodo_tail^.next_nodo = nodo_tail) then
 begin
 nodo_tail := nil ;
 nodo^.prev_nodo := nil;
 nodo^.next_nodo := nil;
 exit;
end;


if (Nodo_tail = nodo) then Nodo_tail := Nodo^.next_nodo ;


nodo^.prev_nodo^.next_nodo := nodo^.next_nodo ;
nodo^.next_nodo^.prev_nodo := nodo^.prev_nodo ;
nodo^.next_nodo := nil ;
nodo^.prev_nodo := nil;
end;

{$ENDIF}

{$ENDIF}


{$IFDEF Use_Hash}

function Hash_Get (Pid : dword) : p_tarea_struc;
var pos:dword;
    l:p_tarea_struc;
begin

pos := Pid mod Max_HashPid ;

{Si esta primera}

If Hash_Pid[pos]^.pid = Pid  then
 exit(Hash_Pid[pos])
 else
  begin
   {Se deve realizar la busqueda dentro de la cola ligada}
   l := Hash_Pid[pos] ;

   repeat
   If l^.pid = Pid then exit(l);
   l := l^.hash_next;
   until (l = Hash_Pid[pos]);
  end;
{No se encontro el Pid}
exit(nil);
end;

procedure Hash_Push(Tarea:p_tarea_struc);inline;
var pos:dword;
begin

pos := Tarea^.pid mod Max_HashPid ;

 If Hash_Pid[pos] = nil then
  begin
  Hash_Pid[pos] := Tarea;
  Tarea^.hash_next := Tarea;
  Tarea^.hash_prev := Tarea;
  end
   else
    begin
      Tarea^.hash_next := Hash_Pid[pos]^.hash_next ;
      Tarea^.hash_next := Hash_Pid[pos];
      Hash_Pid[pos]^.hash_prev^.hash_next := Tarea ;
      Hash_Pid[pos]^.hash_prev := tarea ;
   end;
end;

procedure Hash_Pop(Tarea:p_tarea_struc);inline;
var pos:dword;
begin

pos := Tarea^.pid mod Max_HashPid ;


 If Hash_Pid[pos] = Tarea then
  begin
   Hash_Pid[pos] := nil ;
   Tarea^.hash_prev := nil ;
   Tarea^.hash_next := nil ;
  end
   else
    begin
    Tarea^.hash_prev^.hash_next:=tarea^.hash_next;
    Tarea^.hash_next^.hash_prev:=tarea^.hash_prev;
    Tarea^.hash_prev:=nil;
    Tarea^.hash_next:=nil;
    end;
end;




{$ENDIF}


{$IFDEF Use_Simple_Tail Then}

procedure Push_Snode (Nodo  , sNodo_Tail : snode_struct);inline;
begin
nodo^.next_snode := sNodo_Tail;
snodo_tail := nodo;
end;

procedure Pop_Snode (Nodo,sNodo_Tail : snode_struct);inline;
var tmp : snode_struct;
label _remove;
begin

tmp := sNodo_Tail ;

if tmp = Nodo then goto _remove ;

while (tmp^.next_snode <> nodo) and (tmp^.next_snode <> nil) do tmp := tmp^.next_snode ;

_remove :

if (tmp^.next_snode = nil) then exit else tmp^.next_snode := nodo^.next_snode;

end;




{$ENDIF}
