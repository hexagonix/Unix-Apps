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
	
	mov edi, clear.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, clear.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	jmp realizarLimpeza

;;************************************************************************************

realizarLimpeza:

	mov esi, vd1         ;; Abrir o dispositivo de saída secundário em memória (Buffer) 
	
	Andromeda abrir      ;; Abre o dispositivo
	
	jc .erro
	
	Andromeda limparTela ;; Limpa seu conteúdo
	
	mov esi, vd0         ;; Reabre o dispositivo de saída padrão 
	
	Andromeda abrir      ;; Abre o dispositivo

	Andromeda limparTela
	
	jmp terminar
	
.erro:

	mov esi, clear.erro
	
	imprimirString
	
	jmp terminar
	
;;************************************************************************************

terminar:	

	Andromeda encerrarProcesso

;;************************************************************************************

usoAplicativo:
	
	mov esi, clear.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
clear:

.erro:            db 10, 10, "Erro abrindo um dispositivo de saida.", 10, 10, 0
.uso:             db 10, 10, "Uso: clear", 10, 10
                  db "Limpa o conteudo da saida padrao e vd1.", 10, 10
                  db "clear versao ", versaoCLEAR, 10, 10
                  db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
       
vd0:   db "vd0", 0 ;; Dispositivo de saída padrão do Sistema
vd1:   db "vd1", 0 ;; Dispositivo de saída secundário em memória (Buffer)

parametro: dd ?

