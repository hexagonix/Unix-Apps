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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 58, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/andrmda.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
lshmod:

.uso:                 db 10, 10, "Uso: lshmod [arquivo]", 10, 10
                      db "Recupera as informacoes de uma imagem ou modulo HBoot.", 10, 10
                      db "lshmod versao ", versaoLSHMOD, 10, 10
                      db "Copyright (C) 2022 Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 10, 0
.arquivoInvalido:     db 10, 10, "O nome de arquivo e invalido. Digite um nome de arquivo valido.", 10, 0
.infoArquivo:         db 10, 10, "Nome do arquivo: ", 0
.tamanhoArquivo:      db 10, "Tamanho deste arquivo: ", 0
.bytes:               db " bytes.", 10, 0
.imagemInvalida:      db 10, "<!> Esta nao e uma imagem de modulo HBoot. Tente outro arquivo.", 10, 0
.semArquivo:          db 10, 10, "<!> O arquivo solicitado nao esta disponivel neste disco.", 10, 10
                      db "<!> Verifique a ortografia e tente novamente.", 10, 0  
.tipoArquitetura:     db 10, 10, "> Arquitetura de destino: ", 0
.verModulo:           db 10, "> Versao do modulo: ", 0
.ponto:               db ".", 0
.cabecalho:           db 10, "<+> Este arquivo contem uma imagem HBoot ou modulo HBoot valida.", 0
.i386:                db "i386", 0
.amd64:               db "amd64", 0
.arquiteturaInvalida: db "desconhecida", 0
.entradaCodigo:       db 10, "> Nome interno da imagem do HBoot ou modulo: ", 0
.parametroAjuda:      db "?", 0
.parametroAjuda2:     db "--ajuda", 0
.nomeMod:             dd 0
.arquitetura:         db 0
.verMod:              db 0
.subverMod:           db 0

parametro:            dd ?
nomeArquivo: times 13 db 0
regES:	              dw 0
nomeModulo: times 8   db 0

;;************************************************************************************

inicioAPP:
	
	push ds
	pop es			
	
	mov	[parametro], edi
	
    mov esi, [parametro]
		
	cmp byte[esi], 0
	je usoAplicativo
	
	mov edi, lshmod.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, lshmod.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov esi, [parametro]
	
	Andromeda cortarString
	
	Andromeda tamanhoString
	
	cmp eax, 13
	jl .obterInformacoes
	
	mov esi, lshmod.arquivoInvalido
	
	imprimirString
	
	jmp .fim
	
.obterInformacoes:

    Andromeda arquivoExiste

    jc .semArquivo
    
	push eax
	push esi

    mov esi, lshmod.infoArquivo
	
	imprimirString
	
	pop esi

	call manterArquivo

	imprimirString

    mov esi, lshmod.tamanhoArquivo
	
	imprimirString
	
	pop eax	
	
	imprimirInteiro
	
	mov esi, lshmod.bytes
	
	imprimirString

;; Primeiro vamos ver se se trata de uma imagem executável. Se sim, podemos pular todo o
;; restante do processamento. Isso garante que imagens executáveis sejam relatadas como
;; tal mesmo se tiverem diferentes extensões, visto que cada shell pode procurar por um
;; tipo de extensão específico/preferido além de .APP. Imagens acessórias que necessitam
;; de ser chamadas por outro processo no âmbito de sua execução podem apresentar outra extensão.
;; O próprio Hexagon® é uma imagem HAPP mas apresenta extensão .SIS

	call verificarArquivoHBootMod

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

    jmp .fim

.semArquivo:

    mov esi, lshmod.semArquivo
   
    imprimirString

    jmp .fim	
	
.fim:
	
	novaLinha

	jmp terminar

;;************************************************************************************

verificarArquivoHBootMod:

	mov esi, nomeArquivo
	mov edi, bufferArquivo

	Andromeda abrir

	jc inicioAPP.semArquivo

	mov edi, bufferArquivo

	cmp byte[edi+0], "H"
	jne .naoHBootMod

	cmp byte[edi+1], "B"
	jne .naoHBootMod

	cmp byte[edi+2], "O"
	jne .naoHBootMod

	cmp byte[edi+3], "O"
	jne .naoHBootMod

	cmp byte[edi+4], "T"
	jne .naoHBootMod

	mov dh, byte[edi+5]
    mov byte[lshmod.arquitetura], dh

    mov dh, byte[edi+6]
    mov byte[lshmod.verMod], dh

    mov dh, byte[edi+7]
    mov byte[lshmod.subverMod], dh

	mov esi, dword[edi+8]
	mov dword[nomeModulo+0], esi

	mov esi, dword[edi+12]
	mov dword[nomeModulo+4], esi

	mov dword[nomeModulo+8], 0

	mov esi, nomeModulo

	Andromeda cortarString

    mov esi, lshmod.cabecalho
    
    imprimirString

    mov esi, lshmod.tipoArquitetura

    imprimirString

    cmp byte[lshmod.arquitetura], 01h
    je .i386

    cmp byte[lshmod.arquitetura], 02h
    je .amd64

    cmp byte[lshmod.arquitetura], 02h
    jg .arquiteturaInvalida

.i386:

    mov esi, lshmod.i386

    imprimirString

    jmp .continuar

.amd64:

    mov esi, lshmod.amd64

    imprimirString

    jmp .continuar

.arquiteturaInvalida:

    mov esi, lshmod.arquiteturaInvalida

    imprimirString

    jmp .continuar

.continuar:

	mov esi, lshmod.ponto

	imprimirString

    mov esi, lshmod.verModulo

    imprimirString

    mov dh, byte[lshmod.verMod]
    movzx eax, dh

    imprimirInteiro

    mov esi, lshmod.ponto

    imprimirString

    mov dh, byte[lshmod.subverMod]
    movzx eax, dh

    imprimirInteiro

	mov esi, lshmod.ponto

	imprimirString

	mov esi, lshmod.entradaCodigo

   	imprimirString

	mov esi, nomeModulo
	
   	imprimirString

   	mov esi, lshmod.ponto

   	imprimirString

    ret

.naoHBootMod:

	mov esi, lshmod.imagemInvalida

    imprimirString

    ret

;;************************************************************************************

usoAplicativo:

	mov esi, lshmod.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

manterArquivo:

	push esi
	push eax

	Andromeda cortarString

	Andromeda tamanhoString

	mov ecx, eax

	mov edi, nomeArquivo

	rep movsb		;; Copiar (ECX) caracteres de ESI para EDI
	
	pop eax

	pop esi

	ret

;;************************************************************************************

terminar:	

	Andromeda encerrarProcesso

;;************************************************************************************

bufferArquivo:
