;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Andromeda®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
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

include "../../LibAPP/HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 40, inicioAPP, 01h

;;************************************************************************************

include "../../LibAPP/andrmda.s"
include "../../LibAPP/Estelar/estelar.s"
include "../../LibAPP/Unix.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov	[parametro], edi
	
;;************************************************************************************

	Andromeda obterCor

	mov dword[top.corFonte], eax
	mov dword[top.corFundo], ebx

;;************************************************************************************

	novaLinha
	novaLinha
	
	mov edi, top.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, top.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	jmp exibirProcessos

exibirProcessos:

	mov esi, top.inicio
	
	imprimirString
	
	mov esi, top.processosCarregados
	
	imprimirString
	
	Andromeda obterProcessos
	
	push eax
	
	mov eax, VERMELHO
	
	call definirCorTexto
	
	imprimirString
	
	call definirCorPadrao
	
	novaLinha
	
	mov esi, top.numeroProcessos
	
	imprimirString
	
	mov eax, VERMELHO
	
	call definirCorTexto
	
	pop eax
	
	imprimirInteiro
	
	call definirCorPadrao
	
	mov esi, top.usoMem
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
	
	call definirCorTexto
	
    Andromeda usoMemoria
	
	imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, top.bytes
    
    imprimirString
    
    mov esi, top.memTotal
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
	
	call definirCorTexto
	
    Andromeda usoMemoria
	
	mov eax, ecx
	
	imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, top.mbytes
    
    imprimirString
    
	jmp terminar
	
;;************************************************************************************
	
usoAplicativo:

	mov esi, top.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************	

terminar:	

	novaLinha
	
	Andromeda encerrarProcesso

;;************************************************************************************

;; Função para definir a cor do conteúdo à ser exibido
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorTexto:

	mov ebx, [top.corFundo]
	
	Andromeda definirCor
	
	ret

;;************************************************************************************

definirCorPadrao:

	mov eax, [top.corFonte]
	mov ebx, [top.corFundo]
	
	Andromeda definirCor
	
	ret

;;************************************************************************************

parametro: dd ?

top:

.inicio:              db "Visualizador de processos do Sistema Operacional Andromeda(R)", 10, 10, 0   
.pid:                 db "PID deste processo: ", 0
.usoMem:              db 10, 10, "Uso de memoria: ", 0
.memTotal:            db 10, "Total de memoria instalada identificada: ", 0
.bytes:               db " bytes utilizados pelos processos em execucao.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.uso:                 db "Uso: top", 10, 10
                      db "Exibe os processos carregados na pilha de execucao do Andromeda(R).", 10, 10 
                      db "Processos do Kernel sao filtrados e nao exibidos nesta lista.", 10, 10            
                      db "top versao ", versaoTOP, 10, 10
                      db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--ajuda", 0
.processos:           db " processos na pilha de execucao.", 0
.processosCarregados: db "Processos presentes na pilha de execucao do Sistema: ", 10, 10, 0
.numeroProcessos:     db 10, "Numero de processos presentes na pilha de execucao: ", 0 
.corFonte:            dd 0
.corFundo:            dd 0
