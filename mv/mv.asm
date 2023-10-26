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

inicioAPP:

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov [parametros], edi

    call obterParametros

    jc  usoAplicativo

    push esi
    push edi

    mov edi, mv.parametroAjuda
    mov esi, [parametros]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, mv.parametroAjuda2
    mov esi, [parametros]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    pop edi
    pop esi

    mov esi, [arquivoEntrada]

    hx.syscall arquivoExiste

    jc fonteNaoEncontrado

    mov esi, [arquivoSaida]

    hx.syscall arquivoExiste

    jnc destinoPresente

    mov esi, [arquivoEntrada]
    mov edi, [arquivoSaida]

    hx.syscall rename

    jc erroRenomear

;; Sucesso ao renomear

    jmp terminar

;;************************************************************************************

erroRenomear:

    fputs mv.erroRenomeando

    jmp terminar

;;************************************************************************************

fonteNaoEncontrado:

    fputs mv.fonteIndisponivel

    jmp terminar

;;************************************************************************************

destinoPresente:

    fputs mv.destinoExistente

    jmp terminar

;;************************************************************************************

terminar:

    hx.syscall encerrarProcesso

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

    mov esi, [parametros]
    mov [arquivoEntrada], esi

    cmp byte[esi], 0
    je usoAplicativo

    mov al, ' '

    hx.syscall encontrarCaractere

    jc usoAplicativo

    mov al, ' '

    call encontrarCaractereMV

    mov [arquivoSaida], esi

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

encontrarCaractereMV:

    lodsb

    cmp al, ' '
    je .pronto

    jmp encontrarCaractereMV

.pronto:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

usoAplicativo:

    fputs mv.uso

    jmp terminar

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoMV equ "0.0.2"

mv:

.naoEncontrado:
db 10, "File not found. Please check filename and try again.", 0
.uso:
db 10, "Usage: mv [file1] [file2]", 10, 10
db "Renames file1 into file2.", 10, 10
db "mv version ", versaoMV, 10, 10
db "Copyright (C) 2023-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.fonteIndisponivel:
db 10, "The source file cannot be found on this volume.", 0
.destinoExistente:
db 10, "A file with the given name already exists for the destination. Please remove the file and try again.", 0
.erroRenomeando:
db 10, "An error occurred while requesting to rename the file.", 10
db "This could be due to write protection, volume removal, out of storage or because the system is busy.", 10
db "Please try again later.", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0

parametros:     dd 0
arquivoEntrada: dd ?
arquivoSaida:   dd ?
