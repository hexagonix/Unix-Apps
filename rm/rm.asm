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

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "erros.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, [parameters]

    cmp byte[esi], 0
    je withoutParameter

    mov edi, rm.helpParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    mov edi, rm.helpParameter2
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    mov esi, [parameters]

    hx.syscall arquivoExiste

    jc .fileNotFound

    putNewLine

    fputs rm.confimation

.getConfirmationKeys:

    hx.syscall aguardarTeclado

    cmp al, 'y'
    je .safeDelete

    cmp al, 'Y'
    je .safeDelete

    cmp al, 'n'
    je .cancel

    cmp al, 'N'
    je .cancel

    jmp .getConfirmationKeys

.fileNotFound:

    fputs rm.fileNotFound

    jmp finish

.safeDelete:

    hx.syscall imprimirCaractere

    mov esi, [parameters]

    hx.syscall hx.unlink

    jc .unlinkError

    ;; fputs rm.unlinking

    jmp finish

.cancel:

    hx.syscall imprimirCaractere

    fputs rm.cancel

    jmp finish

.unlinkError:

    push eax

    fputs rm.unlinkError

    pop eax

    cmp eax, IO.operacaoNegada
    je .permissionDenied

    jmp finish

.permissionDenied:

    fputs rm.permissionDenied

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs rm.use

    jmp finish

;;************************************************************************************

withoutParameter:

    fputs rm.withoutParameter

    jmp finish

;;************************************************************************************

finish:

    hx.syscall encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "1.2.0"

rm:

.fileNotFound:
db 10, "File not found.", 0
.use:
db 10, "Usage: rm [file]", 10, 10
db "Requests to delete a file on the current volume.", 10, 10
db "rm version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.confimation:
db "Are you sure you want to delete this file (y/N)? ", 0
.unlinking:
db 10, "The requested file was successfully removed.", 0
.unlinkError:
db 10, "An error occurred during the request. No files were removed.", 0
.cancel:
db 10, "The operation was aborted by the user.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.withoutParameter:
db 10, "A required filename is missing.", 10
db "Use 'rm ?' for help with this utility.", 0
.permissionDenied:
db "Only an administrative (or root) user can complete this action.", 10
db "Login in this user to perform the desired operation.", 0

parameters: dd ?
