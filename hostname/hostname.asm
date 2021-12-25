;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
;;              ┌─┘│          
;;              └──┘          
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 55, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/andrmda.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************

inicioAPP:

    push ds
	pop es			
	
	mov	[parametro], edi
	
    mov esi, [parametro]
		
	cmp byte[esi], 0
	jne usoAplicativo
	
	mov edi, hostname.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, hostname.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	mov edi, bufferArquivo
	mov esi, hostname.arquivoUnix
	
	Andromeda abrir
	
	jc .arquivoNaoEncontrado
	
	novaLinha
	novaLinha
	
	mov esi, bufferArquivo

	Andromeda tamanhoString

	mov edx, eax 
	dec edx

	mov al, 0
	
	Andromeda inserirCaractere

	mov esi, bufferArquivo
	
	imprimirString
	
	novaLinha

	jmp terminar
	
.arquivoNaoEncontrado:

	mov esi, hostname.naoEncontrado
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

usoAplicativo:

	mov esi, hostname.uso
	
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
	
hostname:

.naoEncontrado:   db 10, 10, "Arquivo de host nao encontrado. Verifique se ele foi definido.", 10, 0
.uso:             db 10, 10, "Uso: hostname", 10, 10
                  db "Exibe o nome de host definido para este dispositivo.", 10, 10
                  db "hostname versao ", versaoHOSTNAME, 10, 10
                  db "Copyright (C) 2021-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
.arquivoUnix:     db "host.unx", 0
     
parametro: dd ?

regES:	dw 0
     
bufferArquivo:


