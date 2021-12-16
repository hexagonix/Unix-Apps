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

.uso:             db 10, 10, "Uso: echo [mensagem]", 10, 10
                  db "Envia o conteudo de uma mensagem para a saida padrao.", 10, 10
                  db "echo versao ", versaoECHO, 10, 10
                  db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0