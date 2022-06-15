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

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioAPP, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"

;;************************************************************************************
;;
;; Dados do aplicativo
;;
;;************************************************************************************

versaoFNT equ "0.1"

fnt:

.uso:             db 10, 10, "Uso: fnt [arquivo de fonte]", 10, 10
                  db "Solicita a alteracao da fonte grafica do sistema.", 10, 10
                  db "fnt versao ", versaoFNT, 10, 10
                  db "Copyright (C) 2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.nomeArquivo:     db 10, 10, "Nome do arquivo de fonte: ", 0	
.nomeFonte:       db "Nome do arquivo: ", 0
.sucesso:         db 10, 10, "Fonte alterada com sucesso.", 10, 10
                  db "Pressione qualquer tecla para continuar...", 10, 10, 0
.falha:           db 10, 10, "O arquivo nao pode ser localizado.", 10, 10
                  db 10, 10, "Pressione qualquer tecla para continuar...", 10, 10, 0
.falhaFormato:    db 10, 10, "O arquivo fornecido nao contem uma fonte no formato Hexagon(R).", 10, 10
                  db "Pressione qualquer tecla para continuar...", 10, 10, 0
.falhaFormatoT:   db 10, 10, "O arquivo fornecido nao contem uma fonte no formato Hexagon(R).", 10, 0
.sucessoTexto:    db 10, 10, "Fonte alterada com sucesso.", 10, 0
.falhaTexto:      db 10, 10, "O arquivo nao pode ser localizado.", 10, 0
.introducaoTeste: db 10, "Pre-visualizacao da fonte e dos caracteres: ", 0
.testeFonte:      db 10, 10, "Sistema Operacional Hexagonix(R)", 10, 10
                  db "1234567890-=", 10
                  db "!@#$%^&*()_+", 10
                  db "QWERTYUIOP{}", 10
                  db "qwertyuiop[]", 10
                  db 'ASDFGHJKL:"|', 10
                  db "asdfghjkl;'\", 10
                  db "ZXCVBNM<>?", 10
                  db "zxcvbnm,./", 10, 10
                  db "Sistema Operacional Hexagonix(R)", 10, 0
.tamanhoSuperior: db 10, 10, "Este arquivo de fonte excede o tamanho maximo de 2 Kb.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0

parametro:        dd 0
arquivoFonte:     dd ?
regES:	          dw 0

;;************************************************************************************

inicioAPP:

	mov [regES], es
	
	push ds
	pop es			
	
	mov	[parametro], edi

	mov esi, [parametro]

	cmp byte[esi], 0
	je usoAplicativo
	
	mov edi, fnt.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov edi, fnt.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo
	
	mov esi, fnt.nomeArquivo
	
	imprimirString
	
	mov esi, [parametro]
	
	imprimirString
	
	mov esi, [parametro]
	
	Hexagonix cortarString			;; Remover espaços em branco extras
	
	call validarFonte

	jc .erroFormato

	Hexagonix alterarFonte
	
	jc .erroTexto
	
	mov esi, fnt.sucessoTexto
	
	imprimirString

	mov esi, fnt.introducaoTeste

	imprimirString

	mov esi, fnt.testeFonte

	imprimirString
	
	mov ebx, 00h
	
	Hexagonix encerrarProcesso
	
.erroTexto:

	mov esi, fnt.falhaTexto
	
	imprimirString

	jmp .erroFim

.erroFormato:
	
	mov esi, fnt.falhaFormatoT
	
	imprimirString

	jmp .erroFim

.erroFim:
	
	mov ebx, 00h
	
	jmp terminar
	
;;************************************************************************************

terminar:

	mov ebx, 00h

	Hexagonix encerrarProcesso
	
;;************************************************************************************

usoAplicativo:

	mov esi, fnt.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

validarFonte:

	mov esi, [parametro]
	mov edi, bufferArquivo

	Hexagonix abrir

	jc .erroSemFonte

	mov edi, bufferArquivo

	cmp byte[edi+0], "H"
	jne .naoHFNT

	cmp byte[edi+1], "F"
	jne .naoHFNT

	cmp byte[edi+2], "N"
	jne .naoHFNT

	cmp byte[edi+3], "T"
	jne .naoHFNT

.verificarTamanho:

	Hexagonix arquivoExiste

;; Em EAX, o tamanho do arquivo. Ele não deve ser maior que 2000 bytes, o que poderia
;; sobrescrever dados na memória do Hexagon

	mov ebx, 2000

	cmp eax, ebx
	jng .continuar

	jmp .tamanhoSuperior

.continuar:

	clc 
	
	ret

.erroSemFonte:
	
	mov esi, fnt.falhaTexto
	
	imprimirString

	jmp terminar

.naoHFNT:

	stc

	ret

.tamanhoSuperior:

	mov esi, fnt.tamanhoSuperior
	
	imprimirString

	jmp terminar

;;************************************************************************************

bufferArquivo:
