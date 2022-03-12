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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 40, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/hexagon.s"
include "../../../LibAPP/Estelar/estelar.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov	[parametro], edi
	
;;************************************************************************************

	Hexagonix obterCor

	mov dword[atop.corFonte], eax
	mov dword[atop.corFundo], ebx

;;************************************************************************************

;; A resolução em uso será verificada, para que o aplicativo se adapte ao tamanho da saída e à quantidade de informações 
;; que podem ser exibidas por linha. Desta forma, ele pode exibir um número menor de arquivos com menor resolução e um 
;; número maior por linha caso a resolução permita.

verificarResolucao:

    Hexagonix obterResolucao
    
    cmp eax, 1
    je .modoGrafico1

    cmp eax, 2
    je .modoGrafico2

;; Podem ser exibidos (n+1) arquivos, visto que o contador inicia a contagem de zero. Utilizar essa informação
;; para implementações futuras no aplicativo.
 
.modoGrafico1:

	mov dword[limiteExibicao], 5h ;; Podem ser exibidos 6 arquivos por linha (n+1)
	
	jmp continuarExecucao
	
.modoGrafico2:

	mov dword[limiteExibicao], 7h ;; Podem ser exibidos 8 arquivos por linha (n+1)

	jmp continuarExecucao

continuarExecucao:

	novaLinha
	novaLinha
	
	mov edi, atop.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov edi, atop.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo
	
	jmp exibirProcessos

exibirProcessos:

	mov esi, atop.inicio
	
	imprimirString
	
	mov esi, atop.processosCarregados
	
	imprimirString
	
	Hexagonix obterProcessos
	
	mov [listaRemanescente], esi
	mov dword[numeroPIDs], eax
	
	push eax

	pop ebx

	xor ecx, ecx
	xor edx, edx
	
	push eax
	
	mov eax, VERMELHO
	
	call definirCorTexto

	pop eax 

	push eax 	

	mov edx, eax
	
	mov dword[numeroProcessos], 00h

.loopProcessos:

	push ds
	pop es

	call lerListaProcessos

	mov esi, [arquivoAtual]

	imprimirString

	mov ebx, [limiteExibicao]
	
	cmp dword[numeroProcessos], ebx
	je .criarNovaLinha

	cmp dword[numeroPIDs], 01h
	je .continuar

	inc dword[numeroProcessos]
	dec dword[numeroPIDs]  

	call colocarEspaco
	
	jmp .loopProcessos

.criarNovaLinha:

	mov dword[numeroProcessos], 00h
	
	novaLinha
	
	jmp .loopProcessos

.continuar:

	call definirCorPadrao
	
	novaLinha
	
	mov esi, atop.numeroProcessos
	
	imprimirString
	
	mov eax, VERMELHO
	
	call definirCorTexto
	
	pop eax
	
	imprimirInteiro
	
	call definirCorPadrao
	
	mov esi, atop.usoMem
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
	
	call definirCorTexto
	
    Hexagonix usoMemoria
	
	imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, atop.bytes
    
    imprimirString
    
    mov esi, atop.memTotal
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
	
	call definirCorTexto
	
    Hexagonix usoMemoria
	
	mov eax, ecx
	
	imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, atop.mbytes
    
    imprimirString
    
	jmp terminar
	
;;************************************************************************************
	
usoAplicativo:

	mov esi, atop.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************	

terminar:	

	novaLinha
	
	Hexagonix encerrarProcesso

;;************************************************************************************

;; Função para definir a cor do conteúdo à ser exibido
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorTexto:

	mov ebx, [atop.corFundo]
	
	Hexagonix definirCor
	
	ret

;;************************************************************************************

definirCorPadrao:

	mov eax, [atop.corFonte]
	mov ebx, [atop.corFundo]
	
	Hexagonix definirCor
	
	ret

;;************************************************************************************

colocarEspaco:

	push ecx
	push ebx
	push eax
	
	push ds
	pop es
	
	mov esi, [arquivoAtual]
	
	Hexagonix tamanhoString
	
	mov ebx, 15
	
	sub ebx, eax
	
	mov ecx, ebx

.loopEspaco:

	mov al, ' '
	
	Hexagonix imprimirCaractere
	
	dec ecx
	
	cmp ecx, 0
	je .terminado
	
	jmp .loopEspaco
	
.terminado:

	pop eax
	pop ebx
	pop ecx
	
	ret
	
;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

lerListaProcessos:

	push ds
	pop es
	
	mov esi, [listaRemanescente]
	mov [arquivoAtual], esi
	
	mov al, ' '
	
	Hexagonix encontrarCaractere
	
	jc .pronto

	mov al, ' '
	
	call encontrarCaractereLista
	
	Hexagonix cortarString

	mov [listaRemanescente], esi
	
	jmp .pronto
	
.pronto:

	clc
	
	ret

;;************************************************************************************	

;; Realiza a busca de um caractere específico na String fornecida
;;
;; Entrada:
;;
;; ESI - String à ser verificada
;; AL  - Caractere para procurar
;;
;; Saída:
;;
;; ESI - Posição do caractere na String fornecida

encontrarCaractereLista:

	lodsb
	
	cmp al, ' '
	je .pronto
	
	jmp encontrarCaractereLista
	
.pronto:

	mov byte[esi-1], 0
	
	ret

;;************************************************************************************

parametro: dd ?

atop:

.inicio:              db "Visualizador de processos do Sistema Operacional Hexagonix(R)", 10, 10, 0   
.pid:                 db "PID deste processo: ", 0
.usoMem:              db 10, 10, "Uso de memoria: ", 0
.memTotal:            db 10, "Total de memoria instalada identificada: ", 0
.bytes:               db " bytes utilizados pelos processos em execucao.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.uso:                 db "Uso: atop", 10, 10
                      db "Exibe os processos carregados na pilha de execucao do Hexagonix(R).", 10, 10 
                      db "Processos do Kernel sao filtrados e nao exibidos nesta lista.", 10, 10            
                      db "atop versao ", versaoATOP, 10, 10
                      db "Copyright (C) 2020-2022 Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--ajuda", 0
.processos:           db " processos em execucao.", 0
.processosCarregados: db "Processos em execucao: ", 10, 10, 0
.numeroProcessos:     db 10, "Numero de processos (PIDs) em execucao: ", 0 
.corFonte:            dd 0
.corFundo:            dd 0

listaRemanescente: dd ?
limiteExibicao:    dd 0
numeroProcessos:   dd 0
numeroPIDs:        dd 0
arquivoAtual:      dd ' '