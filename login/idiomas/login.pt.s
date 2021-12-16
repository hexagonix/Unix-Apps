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
;;                                                                                  
;;               Gerenciador de Login do Sistema Operacional Andromeda®                 
;;                                                                   
;;                  Copyright © 2016-2021 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************

.solicitarUsuario: db 10, "Realizar login para: ", 0
.solicitarSenha:   db 10, "Digite sua senha UNIX: ", 0 
.uso:              db 10, 10, "Uso: login [usuario]", 10, 10
                   db "Realiza login em um usuario cadastrado.", 10, 10               
                   db "login versao ", versaoLOGIN, 10, 10
                   db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                   db "Todos os direitos reservados.", 10, 0
.semArquivoUnix:   db 10, 10, "O arquivo de configuracao do ambiente Unix de controle de contas nao foi encontrado.", 10, 0        
.parametroAjuda2:  db "--ajuda", 0 
.sobreAndromeda:   db 10, 10   
                   db "        %#@$%&@$%&@$%$ tm          Sistema Operacional Andromeda(R)", 10
                   db "        #$@$@$@#@#@#@$", 10
                   db "        @#@$&    %#$#%", 10
                   db "        @#$@$    #@#$@", 10
                   db "        #@#$$    !@#@#     Copyright (C) 2016-2021 Felipe Miguel Nery Lunkes",10
                   db "        @#@%!$&%$&$#@#              Todos os direitos reservados",10
                   db "        !@$%#%&#&@&$%#", 10
                   db "        @$#!%&@&@#&*@&", 10
                   db "        $#$#%    &%$#@", 10
                   db "        @#!$$    !#@#@", 10, 10, 0	
.versaoAndromeda:  db "Sistema Operacional Andromeda versao ", 0
.dadosErrados:     db 10, "Falha na autenticacao.", 10, 0
.loginUnix:        db 10, "login versao ", versaoLOGIN, 10, 0