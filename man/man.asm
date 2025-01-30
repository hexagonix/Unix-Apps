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
;;                         Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2025, Felipe Miguel Nery Lunkes
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
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

VERSION equ "2.5.0"

CoreUtilsVersion equ "System I-RELEASE-9.0"
UnixUtilsVersion equ "System I-RELEASE-9.0"

man:

.helpParameter:
db "?", 0
.helpParameter2:
db "--help",0
.man:
db "Hexagonix manual", 0
.use:
db 10, "Usage: man [utility]", 10, 10
db "Display detailed help for installed Unix utilities.", 10, 10
db "CoreUtils version: ", CoreUtilsVersion, 10
db "UnixUtils Version: ", UnixUtilsVersion, 10, 10
db "man version ", VERSION, 10, 10
db "Copyright (C) 2018-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 10
db "Hexagonix is distributed under the BSD-3-Clause license.", 0
.waitKeyPress:
db "Press <q> to exit.", 0
.manNotFound:
db ": manual not found for this utility.", 0
.manFileExtension:
db ".man", 0

utility: dd ?

;;************************************************************************************

applicationStart:

    mov [utility], edi

    cmp byte[edi], 0
    je applicationUsage

    mov edi, man.helpParameter
    mov esi, [utility]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, man.helpParameter2
    mov esi, [utility]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [utility]

    hx.syscall hx.stringSize

    mov ebx, eax

    mov al, byte[man.manFileExtension+0]

    mov byte[esi+ebx+0], al

    mov al, byte[man.manFileExtension+1]

    mov byte[esi+ebx+1], al

    mov al, byte[man.manFileExtension+2]

    mov byte[esi+ebx+2], al

    mov al, byte[man.manFileExtension+3]

    mov byte[esi+ebx+3], al

    mov byte[esi+ebx+4], 0 ;; End of string

    hx.syscall hx.fileExists

    jc manNotFound

    mov edi, appFileBuffer

    mov esi, [utility]

    hx.syscall hx.open

    jc manNotFound

;; Environment preparation

    call buildInterface

    fputs appFileBuffer

    jmp finish

;;************************************************************************************

buildInterface:

    hx.syscall hx.clearConsole

    fputs man.man

    xyfputs 40, 0, [utility]

    putNewLine
    putNewLine

    ret

;;************************************************************************************

manNotFound:

    putNewLine

    fputs [utility]

    fputs man.manNotFound

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs man.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;*****************************************************************************

appFileBuffer:
