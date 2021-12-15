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

.inicio:              db "Visualizador de processos do Sistema Operacional Hexagonix(R)", 10, 10, 0   
.pid:                 db "PID deste processo: ", 0
.usoMem:              db 10, 10, "Uso de memoria: ", 0
.memTotal:            db 10, "Total de memoria instalada identificada: ", 0
.bytes:               db " bytes utilizados pelos processos em execucao.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.uso:                 db "Uso: atop", 10, 10
                      db "Exibe os processos carregados na pilha de execucao do Hexagonix(R).", 10, 10 
                      db "Processos do Kernel sao filtrados e nao exibidos nesta lista.", 10, 10            
                      db "atop versao ", versaoATOP, 10, 10
                      db "Copyright (C) 2020-2021 Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--ajuda", 0
.processos:           db " processos em execucao.", 0
.processosCarregados: db "Processos em execucao: ", 10, 10, 0
.numeroProcessos:     db 10, "Numero de processos (PIDs) em execucao: ", 0 
.corFonte:            dd 0
.corFundo:            dd 0