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

.uso:             db 10, 10, "Use: date", 10, 10
                  db "Displays system date and time.", 10, 10
                  db "date version ", versaoDATE, 10, 10
                  db "Copyright (C) 2020-2021 Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 0
.domingo:         db " (sunday)", 0
.segunda:         db " (monday)", 0
.terca:           db " (tuesday)", 0
.quarta:          db " (wednesday)", 0
.quinta:          db " (thursday)", 0
.sexta:           db " (friday)", 0
.sabado:          db " (saturday)", 0
.espacamento:     db " of ", 0