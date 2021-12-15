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

.comandoNaoEncontrado: db ": comando nao encontrado.", 10, 0
.imagemInvalida:       db ": nao e possivel carregar a imagem. Formato executavel nao suportado.", 10, 0
.limiteProcessos:      db 10, 10, "Nao existe memoria disponivel para executar o aplicativo solicitado.", 10
                       db "Tente primeiramente finalizar aplicativos ou suas instancias, e tente novamente.", 10, 0	
.uso:                  db 10, 10, "Uso: sh", 10, 10
                       db "Inicia um Shell Unix para o usuario atual.", 10, 10               
                       db "sh versao ", versaoSH, 10, 10
                       db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                       db "Todos os direitos reservados.", 10, 0
.parametroAjuda2:      db "--ajuda", 0