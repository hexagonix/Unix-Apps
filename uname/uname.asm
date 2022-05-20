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
include "../../../LibAPP/verUtils.s"
	
;;************************************************************************************			

align 8

versaoUNAME equ "2.1"

uname:

;; Parâmetros (novos) POSIX.2 e compatível com o uname do Linux:
;;
;; -a: tudo
;; -s: nome do kernel
;; -n: hostname
;; -r: lançamento do kernel
;; -v: versão do kernel
;; -m: tipo de máquina
;; -p: tipo de processador
;; -i: plataforma de hardware
;; -o: sistema operacional

.uso:                       db 10, 10, "Uso: uname [parametro]", 10, 10
                            db "Exibe informacoes do Sistema.", 10, 10 
                            db "Parametros possiveis (em caso de falta de parametros, a opcao '-s' sera selecionada):", 10, 10
                            db " -a: Exibe todas as informacoes possiveis do Sistema, do Kernel e da maquina.", 10
                            db " -s: Nome do kernel em execucao.", 10
							db " -n: Exibe o nome de host da maquina executando o Sistema.", 10
						    db " -r: Lancamento do kernel em execucao.", 10
						    db " -v: Versao do kernel em execucao.", 10
						    db " -m: Tipo de maquina.", 10
						    db " -p: Arquitetura do processador do sistema.", 10
						    db " -i: Plataforma de hardware do sistema.", 10
						    db " -o: Nome do sistema operacional em execucao.", 10, 10                                
                            db "uname versao ", versaoUNAME, 10, 10
                            db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                            db "Todos os direitos reservados.", 0
.parametrosSistema:         db " Unix" , 0 
.sistemaOperacional:        db "Hexagonix", 0
.usuario:                   db " ", 0
.espaco:                    db " ", 0
.maquina:                   db "Hexagonix-PC", 0
.colcheteEsquerdo:          db "[", 0
.colcheteDireito:           db "]", 0
.pontoVirgula:              db "; ", 0
.nucleo:                    db " Kernel ", 0
.versao:                    db " versao ", 0 
.arquiteturai386:           db "i386", 0
.arquiteturaamd64:          db "amd64", 0
.hexagonix:                 db "Hexagonix", 0
.parametroAjuda:            db "?", 0  
.parametroAjuda2:           db "--ajuda", 0
.parametroExibirTudo:       db "-a", 0
.parametroExibirNomeKernel: db "-s", 0
.parametroExibirHostname:   db "-n", 0
.parametroExibirLancamento: db "-r", 0
.parametroExibirTipo:       db "-m", 0
.parametroExibirArch:       db "-p", 0
.parametroExibirPlataforma: db "-i", 0
.parametroExibirVersao:     db "-v", 0   
.parametroExibirSO:         db "-o", 0   
.arquivoUnix:               db "host.unx", 0
.naoSuportado:              db "Arquitetura nao identificada.", 0      
.plataformaPC:              db "PC", 0  

ponto: db ".", 0
parametro: dd ?

;;************************************************************************************

align 32

inicioAPP: ;; Ponto de entrada do aplicativo

    mov	[parametro], edi
	
	mov edi, uname.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov edi, uname.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

;; -a

	mov edi, uname.parametroExibirTudo
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirTudo

;; -s

	mov edi, uname.parametroExibirNomeKernel
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirNomeKernel

;; -n

	mov edi, uname.parametroExibirHostname
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirHostname

;; -r

	mov edi, uname.parametroExibirLancamento
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirLancamento

;; -m

	mov edi, uname.parametroExibirTipo
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirArquitetura

;; -p

	mov edi, uname.parametroExibirArch
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirArquitetura

;; -i 

	mov edi, uname.parametroExibirPlataforma
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirPlataforma

;; -v

	mov edi, uname.parametroExibirVersao
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirVersaoApenas

;; -o

	mov edi, uname.parametroExibirSO
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc exibirInfoSistemaOperacional

	jmp exibirNomeKernel

;;************************************************************************************

exibirNomeKernel:

	call espacoPadrao 
	
	Hexagonix retornarVersao
	
	imprimirString

	jmp terminar 

;;************************************************************************************

exibirHostname:

	call espacoPadrao

	call obterHostname

	jmp terminar 

;;************************************************************************************

exibirLancamento:

	call espacoPadrao

	call versaoHexagon

	jmp terminar 

;;************************************************************************************

exibirArquitetura:

	call espacoPadrao

	Hexagonix retornarVersao

;; Em EDX temos a arquitetura
	
    cmp edx, 01
    je .i386

    cmp edx, 02
    je .x86_64 

    mov esi, uname.naoSuportado

    imprimirString

    jmp .terminar 

.i386:

    mov esi, uname.arquiteturai386

    imprimirString
    
    jmp .terminar

.x86_64:

    mov esi, uname.arquiteturaamd64

    imprimirString

    jmp .terminar

.terminar:

	jmp terminar

;;************************************************************************************

exibirPlataforma:

	call espacoPadrao

	mov esi, uname.plataformaPC

	imprimirString

	jmp terminar 

;;************************************************************************************

exibirTudo:

	call espacoPadrao 
	
	mov esi, uname.sistemaOperacional

	imprimirString

	mov esi, uname.espaco
	
	imprimirString

	call obterHostname

.continuarHost:

	mov esi, uname.espaco
	
	imprimirString
	
	Hexagonix retornarVersao
	
	imprimirString
	
	mov esi, uname.versao
	
	imprimirString
	
	call versaoHexagon
	
	cmp edx, 01h 
	je .i386

	cmp edx, 02h
	je .amd64

.i386:

	mov al, " "

	Hexagonix imprimirCaractere

	mov esi, uname.arquiteturai386

	imprimirString

	jmp .continuar

.amd64:

	mov al, " "

	Hexagonix imprimirCaractere

	mov esi, uname.arquiteturaamd64

	imprimirString

	jmp .continuar

.continuar:
	
	mov al, " "

	Hexagonix imprimirCaractere

	mov esi, uname.hexagonix
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

exibirInfoSistemaOperacional:

	call espacoPadrao 
	
	mov esi, uname.sistemaOperacional
	
	imprimirString
	
	jmp terminar
	
;;************************************************************************************

exibirVersaoApenas:

	call espacoPadrao 
	
	Hexagonix retornarVersao
	
	imprimirString
	
	mov esi, uname.espaco

	imprimirString

	call versaoHexagon

	jmp terminar

;;************************************************************************************
	
;; Solicita a versão do Kernel, a decodifica e exibe para o usuário
 	
versaoHexagon:

	Hexagonix retornarVersao
	
	push ecx
	push ebx
	
	imprimirInteiro
	
	mov esi, ponto
	
	imprimirString
	
	pop eax
	
	imprimirInteiro
	
	pop ecx
	
	mov al, ch
	
	Hexagonix imprimirCaractere
	
	ret

;;************************************************************************************

usoAplicativo:

	mov esi, uname.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************	

terminar:	

	novaLinha 

	Hexagonix encerrarProcesso
	
;;*****************************************************************************

espacoPadrao:

	novaLinha
	novaLinha

	ret

;;*****************************************************************************

obterHostname:

;; Vamos agora exibir o nome de host 

	mov edi, enderecoCarregamento
	mov esi, uname.arquivoUnix
	
	Hexagonix abrir
	
	jc .arquivoNaoEncontrado ;; Se não for encontrado, exibir o padrão

;; Se encontrado, exibir o nome de host definido 

	clc 

	mov esi, enderecoCarregamento

	Hexagonix tamanhoString

	mov edx, eax 
	dec edx

	mov al, 0
	
	Hexagonix inserirCaractere

	mov esi, enderecoCarregamento
	
	imprimirString

	jmp .retornar 

.arquivoNaoEncontrado:

	stc 

	mov esi, uname.maquina
	
	imprimirString

.retornar:

	ret

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

enderecoCarregamento: