{$ASMMODE INTEL}
{$I-}

{ * Sh :
  *                                                                  *
  * Shell basica para el sistema toro                                *
  *                                                                  *
  * Versiones :                                                      *
  *                                                                  *
  * 11 / 02 / 2006 : Es totalmente reescritra .                      *
  * 09 / 02 / 2005 : Ahora envia parametros                          *
  * 02 / 08 / 2004 : Se utiliza la unidad stdio                      *
  * 20 / 04 / 2004 : Version Inicial                                 *
  *                                                                  *
  ********************************************************************

}

uses crt,toro,strings;

var err : longint ;
    cmd , path , args , dir ,rela_path: pchar ;
    r : char ;

const root : pchar = '/' ;
      version = '1' ;
      subversion = '2';
      binpath = '/BIN/';


procedure shell ;
var ret , len  : longint ;
    p : pchar ;
begin


if (strscan(cmd,#32) = nil) or (strscan(cmd,#32) = (strend(cmd) -1)) then
 begin

  {cd es considera un un comando de la shell}
  if cmd ='cd' then
   begin
    writeln(dir);
    exit;
   end
   else
    begin

     { si la ruta comienza con / no se utiliza la ruta relativa }
     if cmd^ = '/' then ret := exec (cmd,nil)
     else
      begin
       strcopy (rela_path , binpath);
       strcat (rela_path,cmd);
       ret := exec (rela_path,nil)
      end;

    end;

  end
  else
   begin

    strcopy (args , (strscan (cmd,#32)) + 1 ) ;

    len := longint(pointer(strscan (cmd,#32)) - pointer (cmd) );

    strlcopy (path , cmd, len ) ;

    if (path = 'cd' ) then
     begin
      chdir (string(args)) ;

     {la llamada fue incorrecta ? }
      if ioresult <> 0 then writeln('comando incorrecto')
       else
        begin

         if (args^ = '/') then
          begin

          if strlen(args) = 1 then strcopy(dir,args)
           else
            begin
             if (strend(args)-1)^ = '/' then strcopy(dir,args)
              else
               begin
                strcopy(dir,args);
                strcat (dir,root);
               end;

            end;
         end
         else if (args = '..') then
          begin

           p := strrscan(dir,'/');

           if (p = nil ) then
            begin
            dir := '/';
            exit;
            end
            else p -= 1 ;

           while (p^ <> '/') do p -= 1 ;

           p += 1;

           p^ := #0;

           end
            else if (args^ = '.') then
             begin

             end
            else
           begin
            strcat (dir ,args);
            strcat (dir , root);
          end;

        end;

    exit;
    end else
     begin


      if path^ = '/' then ret := exec (path,args)
      else
       begin
       strcopy(rela_path,binpath);
       strcat(rela_path,path);

       ret := exec (rela_path , args) ;
       end;

     end;

    end;

   ret := ioresult ;

   if (ret <> 0) then writeln('comando incorrecto')
    else waitpid(err);

end;





begin

cmd := stralloc (255) ;
path := stralloc (255);
args := stralloc (255);
dir := stralloc(255);
rela_path := stralloc (255);

dir := '/' ;

writeln('Toro shell ',version,'.',subversion,' by Matias Vara');
writeln('matiasevara@gmail.com');

write('$', dir);

while (true) do
 begin
  readln (cmd);
  shell;
  gotoxy (1,25);
  write('$',dir);
 end;

end.
