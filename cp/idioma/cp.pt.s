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

.naoEncontrado:     db 10, 10, "Arquivo nao encontrado. verifique a ortografia e tente novamente.", 10, 0
.uso:               db 10, 10, "Uso: cp [arquivo de entrada] [arquivo de saida]", 10, 10
                    db "Realiza a copia de um arquivo fornecido em outro. Dois nomes de arquivo sao necessarios, sendo um", 10
                    db "de entrada e outro de saida.", 10, 10
                    db "cp versao ", versaoCP, 10, 10
                    db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                    db "Todos os direitos reservados.", 10, 0
.fonteIndisponivel: db 10, 10, "O arquivo fonte fornecido nao pode ser encontrado neste disco.", 10, 0                              
.destinoExistente:  db 10, 10, "Ja existe um arquivo com o nome fornecido para o destino. Por favor, remova o arquivo com o mesmo", 10
                    db "nome do destino e tente novamente.", 10, 0
.erroAbrindo:       db 10, 10, "Um erro ocorreu ao tentar abrir o arquivo de origem da copia.", 10
                    db "Tente novamente. Se o erro persistir, reinicie o computador.", 10, 0
.erroSalvando:      db 10, 10, "Um erro ocorreu ao solicitar o salvamento do arquivo de destino no disco.", 10
                    db "Isso pode ter ocorrido devido a uma protecao de escrita, remocao da unidade", 10
                    db "de armazenamento ou devido ao fato do Sistema estar ocupado. Tente novamente", 10
                    db "mais tarde.", 10, 0
.copiaConcluida:    db 10, 10, "O arquivo foi copiado com sucesso.", 10, 0
 .parametroAjuda:   db "?", 0
 .parametroAjuda2:  db "--ajuda", 0