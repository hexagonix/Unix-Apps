;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
;;        @#@%!$&%$&$#@#             Todos os direitos reservados
;;        !@$%#%&#&@&$%#
;;        @$#!%&@&@#&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************

.inicio:              db "Hexagonix(R) Operating System Process Viewer", 10, 10, 0   
.pid:                 db "PID of this process: ", 0
.usoMem:              db 10, 10, "Mem use: ", 0
.memTotal:            db 10, "Total installed memory identified: ", 0
.bytes:               db " bytes used by running processes.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.uso:                 db "Use: atop", 10, 10
                      db "Displays the processes loaded into the Hexagonix(R) run stack.", 10, 10 
                      db "Kernel processes are filtered and not displayed in this list.", 10, 10            
                      db "atop version ", versaoATOP, 10, 10
                      db "Copyright (C) 2020-2021 Felipe Miguel Nery Lunkes", 10
                      db "All rights reserved.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--help", 0
.processos:           db " running processes.", 0
.processosCarregados: db "Running processes: ", 10, 10, 0
.numeroProcessos:     db 10, "Number of processes (PIDs) running: ", 0 
.corFonte:            dd 0
.corFundo:            dd 0