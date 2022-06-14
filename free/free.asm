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
	
	mov edi, free.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

    mov edi, free.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo
	
	novaLinha
	novaLinha

    mov esi, free.memoria

    imprimirString
	
	Hexagonix usoMemoria
	
	mov eax, ecx
	
	imprimirInteiro

    mov esi, free.megabytes

    imprimirString

    Hexagonix usoMemoria
	
	imprimirInteiro

    mov esi, free.kbytes

    imprimirString

    Hexagonix usoMemoria

;; Agora vaos transformar bytes em megabytes

    mov ecx, edx

    shr ecx, 10
    shr ecx, 10

;; Pronto, agora imprimir este valor em megabytes

    mov eax, ecx

    imprimirInteiro

    mov esi, free.megabytes

    imprimirString

    novaLinha

    jmp terminar

;;************************************************************************************

usoAplicativo:

	mov esi, free.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

terminar:	

	Hexagonix encerrarProcesso

;;************************************************************************************

versaoFREE equ "0.1"

free:

.uso:             db 10, 10, "Uso: free", 10, 10
                  db "Exibe informacoes sobre uso da memoria do sistema instalada.", 10, 10
                  db "free versao ", versaoFREE, 10, 10
                  db "Copyright (C) 2020-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.memoria:         db "Memoria instalada | Memoria utilizada | Memoria reservada para o Hexagon", 10, 0
.kbytes:          db " bytes           ", 0
.megabytes:       db " megabytes        ", 0
.reservado:       db "16", 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
     
parametro: dd ?

regES:	   dw 0
