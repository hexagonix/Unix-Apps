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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 5, inicioAPP, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

versaoUNAME equ "2.6.7.0"

uname:

;; Parâmetros (novos) POSIX.2 e compatível com o uname do BSD:
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

.sistemaOperacional:
db "Hexagonix", 0
.espaco:
db " ", 0
.maquina:
db "Hexagonix-PC", 0
.buildHexagon:
db "(build ", 0
.fecharParenteses:
db ")", 0
.versao:
db " version ", 0
.arquiteturai386:
db "i386", 0
.arquiteturaamd64:
db "amd64", 0
.hexagonix:
db "Hexagonix", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.parametroExibirTudo:
db "-a", 0
.parametroExibirNomeKernel:
db "-s", 0
.parametroExibirHostname:
db "-n", 0
.parametroExibirLancamento:
db "-r", 0
.parametroExibirTipo:
db "-m", 0
.parametroExibirArch:
db "-p", 0
.parametroExibirPlataforma:
db "-i", 0
.parametroExibirVersao:
db "-v", 0
.parametroExibirSO:
db "-o", 0
.arquivoUnix:
db "host", 0
.naoSuportado:
db "Unknown architecture.", 0
.plataformaPC:
db "PC", 0
.uso:
db 10, "Usage: uname [parameter]", 10, 10
db "Displays system information.", 10, 10
db "Possible parameters (in case of missing parameters, the '-s' option will be selected):", 10, 10
db " -a: Displays all possible system, kernel and machine information.", 10
db " -s: Running kernel name.", 10
db " -n: Display the hostname of the machine running the system.", 10
db " -r: Release of the running kernel.", 10
db " -v: Running kernel version.", 10
db " -m: Machine type.", 10
db " -p: System processor architecture.", 10
db " -i: System hardware platform.", 10
db " -o: Name of running operating system.", 10, 10
db "uname version ", versaoUNAME, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
ponto:
db ".", 0

parametro: dd ?

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi

    mov edi, uname.parametroAjuda
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, uname.parametroAjuda2
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

;; -a

    mov edi, uname.parametroExibirTudo
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirTudo

;; -s

    mov edi, uname.parametroExibirNomeKernel
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirNomeKernel

;; -n

    mov edi, uname.parametroExibirHostname
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirHostname

;; -r

    mov edi, uname.parametroExibirLancamento
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirLancamento

;; -m

    mov edi, uname.parametroExibirTipo
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirArquitetura

;; -p

    mov edi, uname.parametroExibirArch
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirArquitetura

;; -i

    mov edi, uname.parametroExibirPlataforma
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirPlataforma

;; -v

    mov edi, uname.parametroExibirVersao
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirVersaoApenas

;; -o

    mov edi, uname.parametroExibirSO
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc exibirInfoSistemaOperacional

    jmp exibirNomeKernel

;;************************************************************************************

exibirNomeKernel:

    call espacoPadrao

    hx.syscall hx.uname

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

    hx.syscall hx.uname

;; Em EDX temos a arquitetura

    cmp edx, 01
    je .i386

    cmp edx, 02
    je .x86_64

    fputs uname.naoSuportado

    jmp .terminar

.i386:

    fputs uname.arquiteturai386

    jmp .terminar

.x86_64:

    fputs uname.arquiteturaamd64

    jmp .terminar

.terminar:

    jmp terminar

;;************************************************************************************

exibirPlataforma:

    call espacoPadrao

    fputs uname.plataformaPC

    jmp terminar

;;************************************************************************************

exibirTudo:

    call espacoPadrao

    fputs uname.sistemaOperacional

    fputs uname.espaco

    call obterHostname

.continuarHost:

    fputs uname.espaco

    hx.syscall hx.uname

    imprimirString

;; Para ficar de acordo com o padrão do FreeBSD, a mensagem "versao" não é exibida

    ;; fputs uname.versao

    fputs uname.espaco

    call versaoHexagon

    fputs uname.espaco

    cmp edx, 01h
    je .i386

    cmp edx, 02h
    je .amd64

.i386:

    fputs uname.arquiteturai386

    jmp .continuar

.amd64:

    fputs uname.arquiteturaamd64

    jmp .continuar

.continuar:

    fputs uname.espaco

    fputs uname.hexagonix

    jmp terminar

;;************************************************************************************

exibirInfoSistemaOperacional:

    call espacoPadrao

    fputs uname.sistemaOperacional

    jmp terminar

;;************************************************************************************

exibirVersaoApenas:

    call espacoPadrao

    hx.syscall hx.uname

    imprimirString

    fputs uname.espaco

    call versaoHexagon

    jmp terminar

;;************************************************************************************

;; Solicita a versão do kernel, a decodifica e exibe para o usuário

versaoHexagon:

    hx.syscall hx.uname

    push ecx
    push ebx

    imprimirInteiro

    fputs ponto

    pop eax

    imprimirInteiro

    pop ecx

    cmp ecx, 0
    je .continuar

    push ecx

    fputs ponto

    pop eax

    imprimirInteiro

.continuar:

    fputs uname.espaco

    fputs uname.buildHexagon

    hx.syscall hx.uname

    fputs edi

    fputs uname.fecharParenteses

    ret

;;************************************************************************************

usoAplicativo:

    fputs uname.uso

    jmp terminar

;;************************************************************************************

terminar:

    hx.syscall encerrarProcesso

;;*****************************************************************************

espacoPadrao:

    novaLinha

    ret

;;*****************************************************************************

obterHostname:

;; Vamos agora exibir o nome de host

    mov edi, enderecoCarregamento
    mov esi, uname.arquivoUnix

    hx.syscall hx.open

    jc .arquivoNaoEncontrado ;; Se não for encontrado, exibir o padrão

;; Se encontrado, exibir o nome de host definido

    clc

    mov esi, enderecoCarregamento

    hx.syscall tamanhoString

    mov edx, eax
    dec edx

    mov al, 0

    hx.syscall inserirCaractere

    fputs enderecoCarregamento

    jmp .retornar

.arquivoNaoEncontrado:

    stc

    fputs uname.maquina

.retornar:

    ret

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

enderecoCarregamento: