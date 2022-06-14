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

include "../../../lib/HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 9, 00, inicioAPP, 01h

;;************************************************************************************

include "../../../lib/hexagon.s"

;;************************************************************************************

inicioAPP:
	
	push ds
	pop es			
	
	mov	[parametro], edi
	
    mov esi, [parametro]
		
	cmp byte[esi], 0
	je usoAplicativo
	
	mov edi, fileUnix.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov edi, fileUnix.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo
	
	mov esi, [parametro]
	
	Hexagonix cortarString
	
	Hexagonix tamanhoString
	
	cmp eax, 13
	jl .obterInformacoes
	
	mov esi, fileUnix.arquivoInvalido
	
	imprimirString
	
	jmp .fim
	
.obterInformacoes:

    Hexagonix arquivoExiste

    jc .semArquivo
    
	push eax
	push esi

    mov esi, fileUnix.infoArquivo
	
	imprimirString
	
	pop esi

	call manterArquivo

	imprimirString

    mov esi, fileUnix.tamanhoArquivo
	
	imprimirString
	
	pop eax	
	
	imprimirInteiro
	
	mov esi, fileUnix.bytes
	
	imprimirString

;; Primeiro vamos ver se se trata de uma imagem executável. Se sim, podemos pular todo o
;; restante do processamento. Isso garante que imagens executáveis sejam relatadas como
;; tal mesmo se tiverem diferentes extensões, visto que cada shell pode procurar por um
;; tipo de extensão específico/preferido além de .APP. Imagens acessórias que necessitam
;; de ser chamadas por outro processo no âmbito de sua execução podem apresentar outra extensão.
;; O próprio Hexagon® é uma imagem HAPP mas apresenta extensão .SIS

	call verificarArquivoHAPP 
	
	call verificarArquivoHBoot

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

.continuar:

	mov esi, nomeArquivo

	Hexagonix stringParaMaiusculo    ;; Iremos checar com base na extensão em maiúsculo
	
	Hexagonix tamanhoString

	add esi, eax                     ;; Adicionar o tamanho do nome

	sub esi, 4                       ;; Subtrair 4 para manter apenas a extensão

	mov edi, fileUnix.extensaoUNX
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .UNX
	
	jc .arquivoUNX

	mov edi, fileUnix.extensaoSIS
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .SIS
	
	jc .arquivoSIS

	mov edi, fileUnix.extensaoTXT
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .TXT
	
	jc .arquivoTXT

	mov edi, fileUnix.extensaoASM
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .ASM
	
	jc .arquivoASM

	mov edi, fileUnix.extensaoCOW
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .COW
	
	jc .arquivoCOW

	mov edi, fileUnix.extensaoMAN
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .MAN
	
	jc .arquivoMAN

	mov edi, fileUnix.extensaoFNT
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .FNT
	
	jc .arquivoFNT

	mov edi, fileUnix.extensaoCAN
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .CAN
	
	jc .arquivoCAN

;; Checar agora com duas letras de extensão

;; Checar agora com uma única letra de extensão

	add esi, 2 ;; Adicionar 2 (seria uma remoção de 2) para manter apenas a extensão

	mov edi, fileUnix.extensaoS
	
	Hexagonix compararPalavrasString  ;; Checar por extensão .S
	
	jc .arquivoS

	jmp .fim

.aplicativo:

	mov esi, fileUnix.appValido

	imprimirString

	jmp .fim

.arquivoHBoot:

	mov esi, fileUnix.arquivoHBoot

	imprimirString

	jmp .fim

.arquivoUNX:

	mov esi, fileUnix.arquivoUnix

	imprimirString

	jmp .fim

.arquivoTXT:

	mov esi, fileUnix.arquivoTXT

	imprimirString

	jmp .fim

.arquivoFNT:

	mov esi, fileUnix.arquivoFNT

	imprimirString

	jmp .fim

.arquivoCAN:

	mov esi, fileUnix.arquivoCAN

	imprimirString

	jmp .fim

.arquivoCOW:

	mov esi, fileUnix.arquivoCOW

	imprimirString

	jmp .fim

.arquivoMAN:

	mov esi, fileUnix.arquivoMAN

	imprimirString

	jmp .fim

.arquivoSIS:

	mov esi, fileUnix.arquivoSIS

	imprimirString

	jmp .fim

.arquivoASM:

	mov esi, fileUnix.arquivoASM

	imprimirString

	jmp .fim

.arquivoS:

	mov esi, fileUnix.arquivoLibASM

	imprimirString

	jmp .fim

.semArquivo:

    mov esi, fileUnix.semArquivo
   
    imprimirString

    jmp .fim	
	
.fim:
	
	jmp terminar

;;************************************************************************************

verificarArquivoHAPP:

	mov esi, nomeArquivo
	mov edi, bufferArquivo

	Hexagonix abrir

	jc inicioAPP.semArquivo

	mov edi, bufferArquivo

	cmp byte[edi+0], "H"
	jne .naoHAPP

	cmp byte[edi+1], "A"
	jne .naoHAPP

	cmp byte[edi+2], "P"
	jne .naoHAPP

	cmp byte[edi+3], "P"
	jne .naoHAPP

	jmp inicioAPP.aplicativo

.naoHAPP:

	ret

;;************************************************************************************

verificarArquivoHBoot:

	mov esi, nomeArquivo
	mov edi, bufferArquivo

	Hexagonix abrir

	jc inicioAPP.semArquivo

	mov edi, bufferArquivo

	cmp byte[edi+0], "H"
	jne .naoHBoot

	cmp byte[edi+1], "B"
	jne .naoHBoot

	cmp byte[edi+2], "O"
	jne .naoHBoot

	cmp byte[edi+3], "O"
	jne .naoHBoot

	cmp byte[edi+4], "T"
	jne .naoHBoot

	jmp inicioAPP.arquivoHBoot

.naoHBoot:

	ret

;;************************************************************************************

usoAplicativo:

	mov esi, fileUnix.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

manterArquivo:

	push esi
	push eax

	Hexagonix cortarString

	Hexagonix tamanhoString

	mov ecx, eax

	mov edi, nomeArquivo

	rep movsb		;; Copiar (ECX) caracteres de ESI para EDI
	
	pop eax

	pop esi

	ret

;;************************************************************************************

terminar:	

	Hexagonix encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
versaoFILE equ "1.7"

fileUnix:

.uso:             db 10, 10, "Uso: file [arquivo]", 10, 10
                  db "Recupera as informacoes do arquivo e envia para o console principal.", 10, 10
                  db "file versao ", versaoFILE, 10, 10
                  db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.arquivoInvalido: db 10, 10, "O nome de arquivo e invalido. Digite um nome de arquivo valido.", 10, 0
.infoArquivo:     db 10, 10, "Nome do arquivo: ", 0
.tamanhoArquivo:  db 10, 10, "Tamanho deste arquivo: ", 0
.bytes:           db " bytes.", 10, 0
.semArquivo:      db 10, 10, "O arquivo solicitado nao esta disponivel neste disco.", 10, 10
                  db "Verifique a ortografia e tente novamente.", 10, 0  
.appValido:       db 10, "Este parece ser um executavel Unix do Hexagon(R).", 10, 0
.arquivoHBoot:    db 10, "Este parece ser um executavel no formato HBoot (HBoot ou modulo HBoot).", 10, 0
.arquivoASM:      db 10, "Este parece ser um arquivo fonte em Assembly.", 10, 0
.arquivoLibASM:   db 10, "Este parece ser um arquivo fonte que contem uma biblioteca Assembly para desenvolvimento.", 10, 0
.arquivoSIS:      db 10, "Este parece ser um arquivo de sistema.", 10, 0
.arquivoUnix:     db 10, "Este parece ser um arquivo de configuracao ou de dados de ambiente Unix.", 10, 0               
.arquivoMAN:      db 10, "Este parece ser um arquivo de manual de ambiente Unix.", 10, 0
.arquivoCOW:      db 10, "Este parece ser um arquivo de banco de dados do utilitario Unix cowsay.", 10, 0
.arquivoTXT:      db 10, "Este parece ser um arquivo de texto UTF-8.", 10, 0
.arquivoFNT:      db 10, "Este parece ser um arquivo de fonte de exibicao do Hexagon(R).", 10, 0
.arquivoCAN:      db 10, "Este parece ser um arquivo de plug-in do Configuracoes do Andromeda(R).", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
.extensaoSIS:     db ".SIS", 0
.extensaoASM:     db ".ASM", 0
.extensaoBIN:     db ".BIN", 0
.extensaoUNX:     db ".UNX", 0
.extensaoFNT:     db ".FNT", 0
.extensaoOCL:     db ".OCL", 0
.extensaoMAN:     db ".MAN", 0
.extensaoCOW:     db ".COW", 0
.extensaoTXT:     db ".TXT", 0
.extensaoCAN:     db ".CAN", 0
.extensaoS:       db ".S", 0

parametro: dd ?

nomeArquivo: times 13 db 0

regES:	   dw 0

bufferArquivo: