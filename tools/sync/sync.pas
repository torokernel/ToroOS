
 { * Sync :                                                             *
   *                                                                    *
   * Simple prog. que actualiza el cache del sistema a disco            *
   *                                                                    *
   * Copyright (c) 2003-2007 Matias Vara <matiasevara@gmail.com>         *
   * All Rights Reserved                                                *
   *                                                                    *
   *                                                                    *
   **********************************************************************
}
uses toro , crt ;

begin

sync;
writeln('Buffer - Cache actualizado!!');
end.