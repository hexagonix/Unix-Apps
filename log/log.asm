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

inicioAPP:
	
	push ds
	pop es			
	
	mov	[parametro], edi
	
    mov esi, [parametro]
	
	mov edi, log.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, log.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	mov esi, log.vd2
	
	Andromeda abrir
	
	mov esi, log.vd1

	Andromeda abrir

	novaLinha
	
	jmp terminar

;;************************************************************************************

usoAplicativo:

	mov esi, log.uso
	
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
	
log:

.uso:             db 10, 10, "Uso: log", 10, 10
                  db "Exibe os relatorios e mensagens do Kernel Hexagon(R).", 10, 10
                  db "log versao ", versaoLOG, 10, 10
                  db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
.vd1:             db "vd1", 0
.vd2:             db "vd2", 0
     
parametro: dd ?

regES:     dw 0
