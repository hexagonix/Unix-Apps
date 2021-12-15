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

.uso:             db 10, 10, "Uso: cowsay [perfil] [mensagem]", 10, 10
                  db "Exibe de forma divertida uma mensagem para o usuario.", 10, 10
                  db "Voce pode alterar o perfil de animal ou entidade que exibe a mensagem.", 10
                  db "Essa alteracao deve ser solicitada ANTES da mensagem.", 10
                  db 'Em caso de frase, o caractere " deve constar antes e depois da frase.', 10, 10
                  db "cowsay versao ", versaoCOWSAY, 10, 10
                  db "Copyright (C) 2020-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.parametroAjuda:  db "?", 0