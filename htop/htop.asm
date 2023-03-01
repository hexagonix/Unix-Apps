;;*************************************************************************************************
;;
;; 88                                                                                88              
;; 88                                                                                ""              
;; 88                                                                                                
;; 88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8  
;; 88P'    "88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88 88  `P8, ,8P'   
;; 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(     
;; 88       88 "8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88 88  ,d8" "8b,   
;; 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88 88 8P'     `P8  
;;                                               aa,    ,88                                         
;;                                                "P8bbdP"       
;;
;;                    Sistema Operacional Hexagonix® - Hexagonix® Operating System
;;
;;                          Copyright © 2015-2023 Felipe Miguel Nery Lunkes
;;                        Todos os direitos reservados - All rights reserved.
;;
;;*************************************************************************************************
;;
;; Português:
;; 
;; O Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause. Leia abaixo
;; a licença que governa este arquivo e verifique a licença de cada repositório para
;; obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
;; o código deste ou de outros arquivos.
;;
;; English:
;;
;; Hexagonix and its components are licensed under a BSD-3-Clause license. Read below
;; the license that governs this file and check each repository's license for
;; obtain more information about your rights and obligations when using and reusing
;; the code of this or other files.
;;
;;*************************************************************************************************
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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
include "console.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi
    
;;************************************************************************************

    hx.syscall obterCor

    mov dword[htop.corFonte], eax
    mov dword[htop.corFundo], ebx

    novaLinha
    
    mov edi, htop.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, htop.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    jmp exibirProcessos

exibirProcessos:

    fputs htop.inicio
    
    call definirCorPadrao
    
    fputs htop.usoMem
    
    mov eax, VERDE_FLORESTA
    
    call definirCorTexto
    
    hx.syscall usoMemoria
    
    imprimirInteiro
    
    call definirCorPadrao
    
    fputs htop.bytes
    
    fputs htop.memTotal
    
    mov eax, VERDE_FLORESTA
    
    call definirCorTexto
    
    hx.syscall usoMemoria
    
    mov eax, ecx
    
    imprimirInteiro
    
    call definirCorPadrao
    
    fputs htop.mbytes

    novaLinha

    hx.syscall obterProcessos
    
    mov [listaRemanescente], esi
    mov dword[numeroPIDs], eax
    
    push eax

    pop ebx

    xor ecx, ecx
    xor edx, edx

    push eax    

    mov edx, eax
    
    mov dword[numeroProcessos], 00h

    fputs htop.cabecalho

    inc dword[PIDs]

.loopProcessos:

    push ds
    pop es

    call lerListaProcessos

    fputs [processoAtual]

    call colocarEspaco

    mov eax, [PIDs]

    imprimirInteiro

    mov al, 10

    hx.syscall imprimirCaractere

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

    fputs htop.uso

    jmp terminar

;;************************************************************************************  

terminar:   
    
    hx.syscall encerrarProcesso

;;************************************************************************************

;; Função para definir a cor do conteúdo à ser exibido
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorTexto:

    mov ebx, [htop.corFundo]
    
    hx.syscall definirCor
    
    ret

;;************************************************************************************

definirCorPadrao:

    mov eax, [htop.corFonte]
    mov ebx, [htop.corFundo]
    
    hx.syscall definirCor
    
    ret

;;************************************************************************************

colocarEspaco:

    push ecx
    push ebx
    push eax
    
    push ds
    pop es
    
    mov esi, [processoAtual]
    
    hx.syscall tamanhoString
    
    mov ebx, 17
    
    sub ebx, eax
    
    mov ecx, ebx

.loopEspaco:

    mov al, ' '
    
    hx.syscall imprimirCaractere
    
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
    mov [processoAtual], esi
    
    mov al, ' '
    
    hx.syscall encontrarCaractere
    
    jc .pronto

    mov al, ' '
    
    call encontrarCaractereLista
    
    hx.syscall cortarString

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

versaoHTOP equ "1.4.1"

htop:

.inicio:              db "Hexagonix(R) process viewer", 10, 10, 0   
.pid:                 db "PID of this process: ", 0
.usoMem:              db "Memory usage: ", 0
.memTotal:            db 10, "Total installed memory identified: ", 0
.bytes:               db " bytes used by running processes.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.cabecalho:           db 10, "Process        | PID", 10
                      db "---------------|----", 10, 10, 0
.uso:                 db "Usage: htop", 10, 10
                      db "Displays processes loaded on the system.", 10, 10
                      db "Kernel processes are filtered and not displayed in this list.", 10, 10
                      db "htop version ", versaoHTOP, 10, 10
                      db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
                      db "All rights reserved.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--help", 0
.corFonte:            dd 0
.corFundo:            dd 0

listaRemanescente: dd ?
limiteExibicao:    dd 0
numeroProcessos:   dd 0
PIDs:              dd 0
numeroPIDs:        dd 0
processoAtual:      dd ' '