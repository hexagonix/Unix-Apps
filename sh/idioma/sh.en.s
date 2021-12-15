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
;;        @$#!%&@&@#&*@&              Shell Unix para Hexagonix®
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************

.comandoNaoEncontrado: db ": command not fount.", 10, 0
.imagemInvalida:       db ": it is not possible to load the image. Unsupported executable format.", 10, 0
.limiteProcessos:      db 10, 10, "There is no memory available to run the requested application.", 10
                       db "Try to end applications or their instances first, and try again.", 10, 0	
.uso:                  db 10, 10, "Use: sh", 10, 10
                       db "Starts a Unix Shell for the current user.", 10, 10               
                       db "sh version ", versaoSH, 10, 10
                       db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                       db "All rights reserved.", 10, 0
.parametroAjuda2:      db "--help", 0