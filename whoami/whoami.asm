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

use32		

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo. Anteriormente,
;; o cabeçalho era criado em cada imagem e poderia diferir de uma para outra. Caso algum
;; campo da especificação HAPP mudasse, os cabeçalhos de todos os aplicativos deveriam ser
;; alterados manualmente. Com uma estrutura padronizada, basta alterar um arquivo que deve
;; ser incluído e montar novamente o aplicativo, sem a necessidade de alterar manualmente
;; arquivo por arquivo. O arquivo contém uma estrutura instanciável com definição de 
;; parâmetros no momento da instância, tornando o cabeçalho tão personalizável quanto antes.

include "../../../LibAPP/HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 40, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/andrmda.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************			

inicioAPP: ;; Ponto de entrada do Gerenciador de Login do Andromeda®

    mov	[linhaComando], edi
	
	mov edi, whoami.parametroAjuda
	mov esi, [linhaComando]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, whoami.parametroAjuda2
	mov esi, [linhaComando]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
		
	mov edi, whoami.parametroTudo
	mov esi, [linhaComando]
	
	Andromeda compararPalavrasString
	
	jc usuarioEGrupo
	
	mov edi, whoami.parametroUsuario
	mov esi, [linhaComando]
	
	Andromeda compararPalavrasString
	
	jc exibirUsuario

	jmp exibirUsuario
	
;;************************************************************************************			
	
exibirUsuario:
  
	novaLinha
	novaLinha
	
	Andromeda obterUsuario
	
	imprimirString
	
	novaLinha
	
	jmp terminar

;;************************************************************************************

usuarioEGrupo:

	novaLinha
	novaLinha
	
	Andromeda obterUsuario
	
	push eax
	
	imprimirString
	
	mov esi, whoami.grupo
	
	imprimirString
	
	pop eax
	
	imprimirInteiro
	
	novaLinha
	
	jmp terminar
	
;;************************************************************************************		

usoAplicativo:

	mov esi, whoami.uso
	
	imprimirString
	
	jmp terminar
	
;;************************************************************************************	

terminar:	

	Andromeda encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
linhaComando: dd 0

whoami:

.uso:              db 10, 10, "Uso: whoami", 10, 10
                   db "Exibe o nome do usuario atualmente logado no Sistema.", 10, 10     
                   db "Parametros possiveis (em caso de falta de parametros, a opcao '-u' sera selecionada):", 10, 10
                   db "-t - Exibe todas as informacoes possiveis do usuario atualmente logado", 10
                   db "-u - Exibe apenas o nome do usuario logado", 10, 10             
                   db "whoami versao ", versaoWHOAMI, 10, 10
                   db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                   db "Todos os direitos reservados.", 10, 0
.parametroAjuda:   db "?", 0  
.parametroAjuda2:  db "--ajuda", 0 
.parametroTudo:    db "-t", 0
.parametroUsuario: db "-u", 0
.grupo:            db ", do grupo ", 0              
