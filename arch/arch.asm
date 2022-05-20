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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 9, 00, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/hexagon.s"

;;************************************************************************************

inicioAPP:

    push ds
	pop es			
	
	mov	[parametro], edi
	
    mov esi, [parametro]
		
	cmp byte[esi], 0
	jne usoAplicativo
	
	mov edi, arch.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov edi, arch.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

.solicitarHexagon:

    novaLinha
    novaLinha

    Hexagonix retornarVersao

;; Em EDX temos a arquitetura
	
    cmp edx, 01
    je .i386

    cmp edx, 02
    je .x86_64 

    mov esi, arch.naoSuportado

    imprimirString

    jmp .terminar 

.i386:

    mov esi, arch.i386

    imprimirString

    novaLinha
    
    jmp .terminar

.x86_64:

    mov esi, arch.x86_64

    imprimirString

    novaLinha

    jmp .terminar

.terminar:

	jmp terminar
	
;;************************************************************************************

usoAplicativo:

	mov esi, arch.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

terminar:	

	Hexagonix encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoARCH equ "1.0"

arch:

.uso:             db 10, 10, "Uso: arch", 10
                  db "Este utilitario nao aceita argumentos.", 10, 10
                  db "Exibe a arquitetura deste sistema e dispositivo.", 10, 10
                  db "arch versao ", versaoARCH, 10, 10
                  db "Copyright (C) 2021-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.naoSuportado:    db 10, 10, "Arquitetura nao identificada.", 10, 0
.i386:            db "i386", 0
.x86_64:          db "x86_64", 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
     
parametro: dd ?

regES:	dw 0
