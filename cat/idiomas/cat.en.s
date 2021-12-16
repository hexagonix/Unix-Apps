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

.naoEncontrado:   db 10, 10, "File not found. Check your spelling and try again.", 10, 0
.uso:             db 10, 10, "Use: cat [file]", 10, 10
                  db "Sends the contents of a file to standard output.", 10, 10
                  db "cat version ", versaoCAT, 10, 10
                  db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--help", 0