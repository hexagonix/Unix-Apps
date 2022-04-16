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
include "../../../LibAPP/Unix.s"

;;************************************************************************************

inicioAPP:

    push ds
	pop es			
	
	mov	[parametro], edi
	
    mov esi, [parametro]
	
	mov edi, date.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

    mov edi, date.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo
	
	novaLinha
    novaLinha

    call processarBCD ;; Fazer a conversão de BCD para caractere imrprimível

    mov esi, date.hora

    imprimirString

    mov esi, date.sepHora

    imprimirString

    mov esi, date.minuto

    imprimirString

    mov esi, date.sepHora

    imprimirString

    mov esi, date.segundo

    imprimirString

    mov esi, date.espacamento

    imprimirString

    mov esi, date.dia

    imprimirString

    mov esi, date.sepData

    imprimirString

    mov esi, date.mes

    imprimirString

    mov esi, date.sepData

    imprimirString

    mov esi, date.seculo

    imprimirString

    mov esi, date.ano

    imprimirString

match =SIM, DIASEMANA
{
    
;; Vamos verificar agora o dia da semana

    mov eax, date.diaSemana

    cmp byte[eax], '1'
    je .domingo

    cmp byte[eax], '2'
    je .segunda

    cmp byte[eax], '3'
    je .terca

    cmp byte[eax], '4'
    je .quarta

    cmp byte[eax], '5'
    je .quinta

    cmp byte[eax], '6'
    je .sexta

    cmp byte[eax], '7'
    je .sabado

    jmp .desconhecido

.domingo:

    mov esi, date.domingo

    imprimirString

    jmp .continuar

.segunda:

    mov esi, date.segunda

    imprimirString

    jmp .continuar

.terca:

    mov esi, date.terca

    imprimirString

    jmp .continuar

.quarta:

    mov esi, date.quarta

    imprimirString

    jmp .continuar

.quinta:

    mov esi, date.quinta

    imprimirString

    jmp .continuar

.sexta:

    mov esi, date.sexta

    imprimirString

    jmp .continuar

.sabado:

    mov esi, date.sabado

    imprimirString

    jmp .continuar

.desconhecido:

}

.continuar:

    novaLinha

    jmp terminar

;;************************************************************************************

processarBCD:

;; Primeiro, vamos solicitar informações do relógio em tempo real

;; Vamos processar o dia
    
    Hexagonix retornarData

    call BCDParaASCII

    mov word[date.dia], ax
    mov byte[date.dia+15], 0

;; Vamos processar o mês

    Hexagonix retornarData

    mov eax, ebx 

    call BCDParaASCII

    mov word[date.mes], ax
    mov byte[date.mes+15], 0

;; Vamos processar o século (primeiros dois dígitos do ano)

    Hexagonix retornarData

    mov eax, ecx 

    call BCDParaASCII

    mov word[date.seculo], ax
    mov byte[date.seculo+15], 0

;; Vamos processar o ano

    Hexagonix retornarData

    mov eax, edx 

    call BCDParaASCII

    mov word[date.ano], ax
    mov byte[date.ano+15], 0

;; Vamos processar o dia da semana

    Hexagonix retornarData

    mov eax, esi 

    call BCDParaASCII

    mov word[date.diaSemana], ax
    mov byte[date.diaSemana+15], 0

;; Vamos processar a hora

    Hexagonix retornarHora

    mov eax, eax 

    call BCDParaASCII

    mov word[date.hora], ax
    mov byte[date.hora+15], 0

;; Vamos processar os minutos

    Hexagonix retornarHora

    mov eax, ebx

    call BCDParaASCII

    mov word[date.minuto], ax
    mov byte[date.minuto+15], 0

;; Vamos processar os segundos

    Hexagonix retornarHora

    mov eax, ecx

    call BCDParaASCII

    mov word[date.segundo], ax
    mov byte[date.segundo+15], 0

    ret

;;************************************************************************************

;; Realiza a conversão de um número BCD para um caractere ASCII que pode ser
;; imprimível 

BCDParaASCII:
	
    mov ah, al
    and ax, 0xF00F ;; Mascarar bits
    shr ah, 4      ;; Deslocar para direita AH para obter BCD desempacotado
    or ax, 0x3030  ;; Combinar com 30 para obter ASCII
    xchg ah, al    ;; Trocar por convenção ASCII
    
    ret

;;************************************************************************************

usoAplicativo:
	
	mov esi, date.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

terminar:	

	Hexagonix encerrarProcesso

;;************************************************************************************

date:
        
.uso:             db 10, 10, "Uso: date", 10, 10
                  db "Exibe data e hora do sistema.", 10, 10
                  db "date versao ", versaoDATE, 10, 10
                  db "Copyright (C) 2020-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.domingo:         db " (domingo)", 0
.segunda:         db " (segunda-feira)", 0
.terca:           db " (terca-feira)", 0
.quarta:          db " (quarta-feira)", 0
.quinta:          db " (quinta-feira)", 0
.sexta:           db " (sexta-feira)", 0
.sabado:          db " (sabado)", 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
.sepData:         db "/", 0
.sepHora:         db ":", 0
.espacamento:     db " de ", 0
.dia:             dd 0
.mes:             dd 0
.seculo:          dd 0
.ano:             dd 0
.hora:            dd 0
.minuto:          dd 0
.segundo:         dd 0
.diaSemana:       dd 0

parametro:        dd ?