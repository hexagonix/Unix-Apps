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

include "../../../LibAPP/andrmda.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov	[parametro], edi
	
	novaLinha
	novaLinha
	
	mov edi, ps.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, ps.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	mov edi, ps.parametroPID
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc parametroPID
	
	mov edi, ps.parametroMemoria
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc parametroMemoria
	
	mov edi, ps.parametroOutros
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc parametroOutrosProcessos
	
	jmp parametroMemoria

;;************************************************************************************			

parametroPID:
    
    Andromeda obterPID
    
    push eax
    
    mov esi, ps.pid
    
    imprimirString
    
    pop eax
    
    imprimirInteiro
    
    novaLinha
    novaLinha
    
    jmp parametroMemoria.linha

;;************************************************************************************			

parametroMemoria:

.linha:
	
    mov esi, ps.usoMem
    
    imprimirString
    
    Andromeda usoMemoria
	
	imprimirInteiro
    
    mov esi, ps.kbytes
    
    imprimirString
    
    novaLinha
	
	Andromeda encerrarProcesso
    
    jmp terminar

;;************************************************************************************

parametroOutrosProcessos:

	Andromeda obterPID
	
	push eax
	
	mov esi, ps.numeroProcessos
	
	imprimirString
	
	pop eax
	
	imprimirInteiro
	
	mov esi, ps.processos
	
	imprimirString
	
	jmp terminar
	
;;************************************************************************************
	
usoAplicativo:

	mov esi, ps.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************	

terminar:	

	novaLinha
	
	Andromeda encerrarProcesso

;;************************************************************************************

parametro: dd ?

ps:
    
.pid:              db "PID deste processo: ", 0
.usoMem:           db "Uso de memoria: ", 0
.kbytes:           db " bytes utilizados por processos em execucao.", 0
.uso:              db "Uso: ps [parametro]", 10, 10
                   db "Exibe informacoes de processos e uso de memoria e recursos do Sistema.", 10, 10 
                   db "Parametros possiveis (em caso de falta de parametros, a opcao '-v' sera selecionada):", 10, 10
                   db "-t - Exibe todas as informacoes possiveis de processos e recursos do Sistema.", 10
                   db "-v - Exibe apenas o uso de memoria dos processos em execucao.", 10, 10  
                   db "-o - Exibe o numero de processos na fila de execucao.", 10, 10            
                   db "ps versao ", versaoPS, 10, 10
                   db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                   db "Todos os direitos reservados.", 0
.parametroAjuda:   db "?", 0  
.parametroAjuda2:  db "--ajuda", 0
.parametroPID:     db "-t", 0
.parametroOutros:  db "-o", 0
.parametroMemoria: db "-v", 0     
.numeroProcessos:  db "Existem atualmente ", 0
.processos:        db " processos na pilha de execucao do Andromeda(R).", 0
    
