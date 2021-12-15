;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2020-2021 Felipe Miguel Nery Lunkes
;;        @#@%!$&%$&$#@#              Todos os direitos reservados
;;        !@$%#%&#&@&$%#
;;        @$#!%&@&@#&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************

.uso:             db 10, 10, "Use: cowsay [character] [message]", 10, 10
                  db "Displays a message to the user in a fun way.", 10, 10
                  db "You can change the profile of animal or entity that displays the message.", 10
                  db "This change must be requested BEFORE the message.", 10
                  db 'In the case of a sentence, the character " must appear before and after the sentence.', 10, 10
                  db "cowsay version ", versaoCOWSAY, 10, 10
                  db "Copyright (C) 2020-2021 Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 0
.parametroAjuda:  db "?", 0