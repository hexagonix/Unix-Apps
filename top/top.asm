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

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi

;;************************************************************************************

    hx.syscall obterCor

    mov dword[top.corFonte], eax
    mov dword[top.corFundo], ebx

;;************************************************************************************

    novaLinha

    mov edi, top.parametroAjuda
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, top.parametroAjuda2
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    jmp exibirProcessos

exibirProcessos:

    fputs top.inicio

    fputs top.processosCarregados

    hx.syscall obterProcessos

    push eax

    mov eax, VERMELHO

    call definirCorTexto

    imprimirString

    call definirCorPadrao

    novaLinha

    fputs top.numeroProcessos

    mov eax, VERMELHO

    call definirCorTexto

    pop eax

    imprimirInteiro

    call definirCorPadrao

    fputs top.usoMem

    mov eax, VERDE_FLORESTA

    call definirCorTexto

    hx.syscall usoMemoria

    imprimirInteiro

    call definirCorPadrao

    fputs top.bytes

    fputs top.memTotal

    mov eax, VERDE_FLORESTA

    call definirCorTexto

    hx.syscall usoMemoria

    mov eax, ecx

    imprimirInteiro

    call definirCorPadrao

    fputs top.mbytes

    jmp terminar

;;************************************************************************************

usoAplicativo:

    fputs top.uso

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

    mov ebx, [top.corFundo]

    hx.syscall definirCor

    ret

;;************************************************************************************

definirCorPadrao:

    mov eax, [top.corFonte]
    mov ebx, [top.corFundo]

    hx.syscall definirCor

    ret

;;************************************************************************************

parametro: dd ?

versaoTOP equ "1.2.4"

top:

.inicio:
db "Hexagonix process viewer", 10, 10, 0
.pid:
db "PID of this process: ", 0
.usoMem:
db 10, 10, "Memory usage: ", 0
.memTotal:
db 10, "Total installed memory identified: ", 0
.bytes:
db " bytes used by running processes.", 0
.kbytes:
db " kbytes.", 0
.mbytes:
db " megabytes.", 0
.uso:
db "Usage: top", 10, 10
db "Displays the processes loaded in the Hexagonix execution stack.", 10, 10
db "Kernel processes are filtered and not displayed in this list.", 10, 10
db "top version ", versaoTOP, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.processos:
db " processes on the execution stack.", 0
.processosCarregados:
db "Processes present in the system execution stack: ", 10, 10, 0
.numeroProcessos:
db 10, "Number of processes present in the execution stack: ", 0
.corFonte: dd 0
.corFundo: dd 0
