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
;;                     Sistema Operacional Hexagonix - Hexagonix Operating System
;;
;;                         Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
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

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo.

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioAPP, 01h

;;************************************************************************************

align 4

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

inicioAPP:

    push ds
    pop es

    mov [parametro], edi ;; Salvar os parâmetros da linha de comando para uso futuro

;;************************************************************************************

    hx.syscall obterCor

    mov dword[ls.corFonte], eax
    mov dword[ls.corFundo], ebx

;; A resolução em uso será verificada, para que o aplicativo se adapte ao tamanho da saída e à quantidade de informações
;; que podem ser exibidas por linha. Desta forma, ele pode exibir um número menor de arquivos com menor resolução e um
;; número maior por linha caso a resolução permita.

verificarResolucao:

    hx.syscall obterResolucao

    cmp eax, 1
    je .modoGrafico1

    cmp eax, 2
    je .modoGrafico2

;; Podem ser exibidos (n+1) arquivos, visto que o contador inicia a contagem de zero. Utilizar essa informação
;; para implementações futuras no aplicativo.

.modoGrafico1:

    mov dword[limiteExibicao], 5h ;; Podem ser exibidos 6 arquivos por linha (n+1)

    jmp verificarParametros

.modoGrafico2:

    mov dword[limiteExibicao], 7h ;; Podem ser exibidos 8 arquivos por linha (n+1)

    jmp verificarParametros

;;************************************************************************************

;; Agora os parâmetros serão verificados e as ações necessárias serão tomadas

verificarParametros:

    mov esi, [parametro]

    mov edi, ls.parametroAjuda
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, ls.parametroAjuda2
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, ls.parametroTudo
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc configurarExibicao

    cmp byte[esi], 0
    je listar

    jmp verificarArquivo

;;************************************************************************************

configurarExibicao:

    mov byte[ls.exibirTudo], 01h

    jmp listar

;;************************************************************************************

listar:

    novaLinha

    hx.syscall listarArquivos ;; Obter arquivos em ESI

    jc .erroLista

    mov [listaRemanescente], esi

    push eax

    pop ebx

    xor ecx, ecx
    xor edx, edx

.loopArquivos:

    push ds
    pop es

    push ebx
    push ecx

    call lerListaArquivos

    push esi

    sub esi, 5

    mov edi, ls.extensaoAPP

    hx.syscall compararPalavrasString ;; Checar por extensão .APP

    jc .aplicativo

    mov edi, ls.extensaoSIS

    hx.syscall compararPalavrasString

    jc .sistema

    mov edi, ls.extensaoASM

    hx.syscall compararPalavrasString

    jc .fonteASM

    mov edi, ls.extensaoBIN

    hx.syscall compararPalavrasString

    jc .arquivoBIN

    mov edi, ls.extensaoUNX

    hx.syscall compararPalavrasString

    jc .arquivoUNX

    mov edi, ls.extensaoFNT

    hx.syscall compararPalavrasString

    jc .arquivoFNT

    mov edi, ls.extensaoOCL

    hx.syscall compararPalavrasString

    jc .arquivoOCL

    mov edi, ls.extensaoMOD

    hx.syscall compararPalavrasString

    jc .arquivoMOD

    mov edi, ls.extensaoCOW

    hx.syscall compararPalavrasString

    jc .arquivoCOW

    mov edi, ls.extensaoMAN

    hx.syscall compararPalavrasString

    jc .arquivoMAN

    jmp .arquivoComum

.aplicativo:

    pop esi

    mov eax, VERDE_FLORESTA

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.sistema:

    pop esi

    mov eax, AZUL_MEDIO

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.fonteASM:

    pop esi

    mov eax, VERMELHO

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.arquivoBIN:

    pop esi

    mov eax, VIOLETA_ESCURO

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.arquivoUNX:

    pop esi

    mov eax, MARROM_PERU

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.arquivoOCL: ;; Obrigatoriamente, não deve ser exibido

    pop esi

    jmp .pularExibicao

.arquivoMOD:

    pop esi

    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, LAVANDA_SURPRESA

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.arquivoCOW: ;; Obrigatoriamente, não deve ser exibido

    pop esi

    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, VERDE_PASTEL

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.arquivoMAN:

    pop esi

    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, TOMATE

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.arquivoFNT:

    pop esi

    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, TURQUESA_ESCURO

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.pularExibicao:

    dec edx

    jmp .semEspaco

.arquivoComum:

    pop esi

    mov eax, VERDE_FLORESTA

    call definirCorArquivo

    fputs [arquivoAtual]

    call definirCorPadrao

    jmp .continuar

.continuar:

    call colocarEspaco

.semEspaco:

    pop ecx
    pop ebx

    cmp ecx, ebx
    je .terminado

    cmp edx, [limiteExibicao]
    je .criarNovaLinha

    inc ecx
    inc edx

    jmp .loopArquivos

.criarNovaLinha:

    xor edx, edx

;; Correção para não adicionar linhas a mais

    add ecx, 1

;; Continuar

    novaLinha

    jmp .loopArquivos

.terminado:

    cmp edx, 1h  ;; Verifica se existe algum arquivo solitário em uma linha
    jl terminar

    ;; novaLinha

    jmp terminar

.erroLista:

    fputs ls.erroLista

    jmp terminar

;;************************************************************************************

usoAplicativo:

    fputs ls.uso

    jmp terminar

;;************************************************************************************

terminar:

    hx.syscall encerrarProcesso

;;************************************************************************************

;; Função única para definir a cor de representação de determinado arquivo
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorArquivo:

    mov ebx, dword[ls.corFundo]

    hx.syscall definirCor

    ret

;;************************************************************************************

definirCorPadrao:

    mov eax, dword[ls.corFonte]
    mov ebx, dword[ls.corFundo]

    hx.syscall definirCor

    ret

;;************************************************************************************

colocarEspaco:

    push ecx
    push ebx
    push eax

    push ds
    pop es

    mov esi, [arquivoAtual]

    hx.syscall tamanhoString

    mov ebx, 15

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

lerListaArquivos:

    push ds
    pop es

    mov esi, [listaRemanescente]
    mov [arquivoAtual], esi

    mov al, ' '

    hx.syscall encontrarCaractere

    jc .pronto

    mov al, ' '

    call encontrarCaractereListaArquivos

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

encontrarCaractereListaArquivos:

    lodsb

    cmp al, ' '
    je .pronto

    jmp encontrarCaractereListaArquivos

.pronto:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

verificarArquivo:

    mov esi, [parametro]

    hx.syscall arquivoExiste

    jc terminar

    novaLinha
    novaLinha

    mov esi, [parametro]

    hx.syscall stringParaMaiusculo

    mov [parametro], esi

    imprimirString

    jmp terminar

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoLS equ "3.2.3.2"

ls:

.extensaoAPP:
db ".APP", 0
.extensaoSIS:
db ".SIS", 0
.extensaoASM:
db ".ASM", 0
.extensaoBIN:
db ".BIN", 0
.extensaoUNX:
db ".UNX", 0
.extensaoFNT:
db ".FNT", 0
.extensaoOCL:
db ".OCL", 0
.extensaoCOW:
db ".COW", 0
.extensaoMAN:
db ".MAN", 0
.extensaoMOD:
db ".MOD", 0
.erroLista:
db 10, "Error listing the files present on the volume.", 0
.uso:
db 10, "Usage: ls", 10, 10
db "Lists and displays the files present on the current volume, sorting them by type.", 10, 10
db "Available parameters:", 10, 10
db "-a - List all files available on the volume.", 10, 10
db "ls version ", versaoLS, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.parametroTudo:
db "-a" ,0
.exibirTudo: db 0
.corFonte:   dd 0
.corFundo:   dd 0
.corAPP:     dd 0
.corSIS:     dd 0
.corASM:     dd 0
.corBIN:     dd 0
.corUNX:     dd 0
.corFNT:     dd 0
.corOCL:     dd 0
.corCOW:     dd 0
.corMAN:     dd 0

parametro:         dd ?
listaRemanescente: dd ?
limiteExibicao:    dd 0
arquivoAtual:      dd ' '
