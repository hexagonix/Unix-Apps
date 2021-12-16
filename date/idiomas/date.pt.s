;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2015-2021 Felipe Miguel Nery Lunkes
;;        @#@%!$&%$&$#@#             Todos os direitos reservados
;;        !@$%#%&#&@&$%#
;;        @$#!%&@&@#&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************   

.uso:             db 10, 10, "Uso: date", 10, 10
                  db "Exibe data e hora do sistema.", 10, 10
                  db "date versao ", versaoDATE, 10, 10
                  db "Copyright (C) 2020-2021 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.domingo:         db " (domingo)", 0
.segunda:         db " (segunda-feira)", 0
.terca:           db " (terca-feira)", 0
.quarta:          db " (quarta-feira)", 0
.quinta:          db " (quinta-feira)", 0
.sexta:           db " (sexta-feira)", 0
.sabado:          db " (sabado)", 0
.espacamento:     db " de ", 0