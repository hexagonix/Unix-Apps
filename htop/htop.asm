;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
;;              ┌─┘│                 Licenciado sob licença BSD-3-Clause
;;              └──┘          
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2022, Felipe Miguel Nery Lunkes
;; All rights reserved.
;; 
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;; 
;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.
;; 
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; $HexagonixOS$

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
include "Estelar/estelar.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi
    
;;************************************************************************************

    Hexagonix obterCor

    mov dword[htop.corFonte], eax
    mov dword[htop.corFundo], ebx

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
    
    mov edi, htop.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, htop.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    jmp exibirProcessos

exibirProcessos:

    mov esi, htop.inicio
    
    imprimirString
    
     call definirCorPadrao
    
    mov esi, htop.usoMem
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
    
    call definirCorTexto
    
    Hexagonix usoMemoria
    
    imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, htop.bytes
    
    imprimirString
    
    mov esi, htop.memTotal
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
    
    call definirCorTexto
    
    Hexagonix usoMemoria
    
    mov eax, ecx
    
    imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, htop.mbytes
    
    imprimirString

    novaLinha

    Hexagonix obterProcessos
    
    mov [listaRemanescente], esi
    mov dword[numeroPIDs], eax
    
    push eax

    pop ebx

    xor ecx, ecx
    xor edx, edx

    push eax    

    mov edx, eax
    
    mov dword[numeroProcessos], 00h

    mov esi, htop.cabecalho

    imprimirString

    inc dword[PIDs]

.loopProcessos:

    push ds
    pop es

    call lerListaProcessos

    mov esi, [arquivoAtual]

    imprimirString

    call colocarEspaco

    mov eax, [PIDs]

    imprimirInteiro

    mov al, 10

    Hexagonix imprimirCaractere

    cmp dword[numeroPIDs], 01h
    je .continuar

    inc dword[numeroProcessos]
    inc dword[PIDs]
    dec dword[numeroPIDs]  

    jmp .loopProcessos

.continuar:

    call definirCorPadrao
    
    jmp terminar
    
;;************************************************************************************
    
usoAplicativo:

    mov esi, htop.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************  

terminar:   
    
    Hexagonix encerrarProcesso

;;************************************************************************************

;; Função para definir a cor do conteúdo à ser exibido
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorTexto:

    mov ebx, [htop.corFundo]
    
    Hexagonix definirCor
    
    ret

;;************************************************************************************

definirCorPadrao:

    mov eax, [htop.corFonte]
    mov ebx, [htop.corFundo]
    
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
    
    mov ebx, 17
    
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

VERSAOHTOP equ "1.1"

htop:

.inicio:              db "Visualizador de processos do Hexagonix(R)", 10, 10, 0   
.pid:                 db "PID deste processo: ", 0
.usoMem:              db "Uso de memoria: ", 0
.memTotal:            db 10, "Total de memoria instalada identificada: ", 0
.bytes:               db " bytes utilizados pelos processos em execucao.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.cabecalho:           db 10, "Processo       | PID", 10, 10, 0
.uso:                 db "Uso: htop", 10, 10
                      db "Exibe os processos carregados no sistema.", 10, 10 
                      db "Processos do kernel sao filtrados e nao exibidos nesta lista.", 10, 10            
                      db "htop versao ", VERSAOHTOP, 10, 10
                      db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--ajuda", 0
.corFonte:            dd 0
.corFundo:            dd 0

listaRemanescente: dd ?
limiteExibicao:    dd 0
numeroProcessos:   dd 0
PIDs:              dd 0
numeroPIDs:        dd 0
arquivoAtual:      dd ' '