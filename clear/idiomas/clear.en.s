;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;;        @#@%!$&%$&$#@#             Todos os direitos reservados
;;        !@$%#%&#&@&$%#
;;        @$#!%&@&@#&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************

.erro:            db 10, 10, "Error opening an output device.", 10, 10, 0
.uso:             db 10, 10, "Use: clear", 10, 10
                  db "Clears the contents of standard output and vd1.", 10, 10
                  db "clear version ", versaoCLEAR, 10, 10
                  db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--help", 0