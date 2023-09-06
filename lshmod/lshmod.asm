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
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoLSHMOD equ "0.6.6"

lshmod:

.uso:
db 10, "Usage: lshmod [file]", 10, 10
db "Retrieve information from an HBoot image or module.", 10, 10
db "lshmod version ", versaoLSHMOD, 10, 10
db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.arquivoInvalido:
db 10, "The file name is invalid. Please enter a valid filename.", 0
.infoArquivo:
db 10, "Filename: ", 0
.tamanhoArquivo:
db 10, "File size: ", 0
.bytes:
db " bytes.", 10, 0
.imagemInvalida:
db 10, "<!> This is not an HBoot module image. Try another file.", 0
.semArquivo:
db 10, "<!> The requested file is not available on this volume.", 10, 10
db "<!> Check the filename and try again.", 0
.tipoArquitetura:
db 10, 10, "> Target architecture: ", 0
.verModulo:
db 10, "> Module version: ", 0
.ponto:
db ".", 0
.cabecalho:
db 10, "<+> This file contains a valid HBoot image or HBoot module.", 0
.i386:
db "i386", 0
.amd64:
db "amd64", 0
.arquiteturaInvalida:
db "unknown", 0
.entradaCodigo:
db 10, "> Internal name of the HBoot image or module: ", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.nomeMod:     dd 0
.arquitetura: db 0
.verMod:      db 0
.subverMod:   db 0

parametro:            dd ?
nomeArquivo: times 13 db 0
regES:                dw 0
nomeModulo: times 8   db 0

;;************************************************************************************

inicioAPP:

    push ds
    pop es

    mov [parametro], edi

    mov esi, [parametro]

    cmp byte[esi], 0
    je usoAplicativo

    mov edi, lshmod.parametroAjuda
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, lshmod.parametroAjuda2
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov esi, [parametro]

    hx.syscall cortarString

    hx.syscall tamanhoString

    cmp eax, 13
    jl .obterInformacoes

    fputs lshmod.arquivoInvalido

    jmp .fim

.obterInformacoes:

    hx.syscall arquivoExiste

    jc .semArquivo

    push eax
    push esi

    fputs lshmod.infoArquivo

    pop esi

    call manterArquivo

    imprimirString

    fputs lshmod.tamanhoArquivo

    pop eax

    imprimirInteiro

    fputs lshmod.bytes

;; Vamos verificar se a imagem é de fato uma imagem HBoot

    call verificarArquivoHBootMod

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

    jmp .fim

.semArquivo:

    fputs lshmod.semArquivo

    jmp .fim

.fim:

    jmp terminar

;;************************************************************************************

verificarArquivoHBootMod:

    mov esi, nomeArquivo
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc inicioAPP.semArquivo

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHBootMod

    cmp byte[edi+1], "B"
    jne .naoHBootMod

    cmp byte[edi+2], "O"
    jne .naoHBootMod

    cmp byte[edi+3], "O"
    jne .naoHBootMod

    cmp byte[edi+4], "T"
    jne .naoHBootMod

    mov dh, byte[edi+5]
    mov byte[lshmod.arquitetura], dh

    mov dh, byte[edi+6]
    mov byte[lshmod.verMod], dh

    mov dh, byte[edi+7]
    mov byte[lshmod.subverMod], dh

    mov esi, dword[edi+8]
    mov dword[nomeModulo+0], esi

    mov esi, dword[edi+12]
    mov dword[nomeModulo+4], esi

    mov dword[nomeModulo+8], 0

    mov esi, nomeModulo

    hx.syscall cortarString

    fputs lshmod.cabecalho

    fputs lshmod.tipoArquitetura

    cmp byte[lshmod.arquitetura], 01h
    je .i386

    cmp byte[lshmod.arquitetura], 02h
    je .amd64

    cmp byte[lshmod.arquitetura], 02h
    jg .arquiteturaInvalida

.i386:

    fputs lshmod.i386

    jmp .continuar

.amd64:

    fputs lshmod.amd64

    jmp .continuar

.arquiteturaInvalida:

    fputs lshmod.arquiteturaInvalida

    jmp .continuar

.continuar:

    fputs lshmod.ponto

    fputs lshmod.verModulo

    mov dh, byte[lshmod.verMod]
    movzx eax, dh

    imprimirInteiro

    fputs lshmod.ponto

    mov dh, byte[lshmod.subverMod]
    movzx eax, dh

    imprimirInteiro

    fputs lshmod.ponto

    fputs lshmod.entradaCodigo

    fputs nomeModulo

    fputs lshmod.ponto

    ret

.naoHBootMod:

    fputs lshmod.imagemInvalida

    ret

;;************************************************************************************

usoAplicativo:

    fputs lshmod.uso

    jmp terminar

;;************************************************************************************

manterArquivo:

    push esi
    push eax

    hx.syscall cortarString

    hx.syscall tamanhoString

    mov ecx, eax

    mov edi, nomeArquivo

    rep movsb ;; Copiar (ECX) caracteres de ESI para EDI

    pop eax

    pop esi

    ret

;;************************************************************************************

terminar:

    hx.syscall encerrarProcesso

;;************************************************************************************

bufferArquivo:
