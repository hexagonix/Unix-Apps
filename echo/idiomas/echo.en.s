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

.uso:             db 10, 10, "Use: echo [message]", 10, 10
                  db "Send the contents of a message to standard output.", 10, 10
                  db "echo version ", versaoECHO, 10, 10
                  db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 0