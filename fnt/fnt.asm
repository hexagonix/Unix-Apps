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
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.8.0"

fnt:

.use:
db 10, "Usage: fnt [graphic font file]", 10, 10
db "Changes the system font.", 10, 10
db "fnt version ", VERSION, 10, 10
db "Copyright (C) 2022-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.fileName:
db 10, "Font filename: ", 0
.fontFileName:
db "Filename: ", 0
.invalidFormat:
db 10, "The file does not contain a font in Hexagon format.", 0
.success:
db 10, 10, "Font changed successfully.", 0
.error:
db 10, "File not found.", 0
.testIntro:
db 10, "Font preview: ", 0
.fontTest:
db 10, 10
db "Hexagonix Operating System", 10, 10
db "1234567890-=", 10
db "!@#$%^&*()_+", 10
db "QWERTYUIOP{}", 10
db "qwertyuiop[]", 10
db 'ASDFGHJKL:"|', 10
db "asdfghjkl;'\", 10
db "ZXCVBNM<>?", 10
db "zxcvbnm,./", 10, 10
db "Hexagonix Operating System", 10, 0
.biggerSize:
db 10, "This font file exceeds the maximum size of 2 Kb.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0

parameters: dd 0

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, [parameters]

    cmp byte[esi], 0
    je applicationUsage

    mov edi, fnt.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, fnt.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    fputs fnt.fileName

    fputs [parameters]

    mov esi, [parameters]

    hx.syscall hx.trimString ;; Remove extra spaces

    call validateFont

    jc .formatError

    hx.syscall hx.changeConsoleFont

    jc .textError

    fputs fnt.success

    fputs fnt.testIntro

    fputs fnt.fontTest

    mov ebx, 00h

    hx.syscall hx.exit

.textError:

    fputs fnt.error

    jmp .endError

.formatError:

    fputs fnt.invalidFormat

    jmp .endError

.endError:

    mov ebx, 00h

    jmp finish

;;************************************************************************************

finish:

    mov ebx, 00h

    hx.syscall hx.exit

;;************************************************************************************

applicationUsage:

    fputs fnt.use

    jmp finish

;;************************************************************************************

validateFont:

    mov esi, [parameters]
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .withoutFontError

    mov edi, appFileBuffer

    cmp byte[edi+0], "H"
    jne .notHFNT

    cmp byte[edi+1], "F"
    jne .notHFNT

    cmp byte[edi+2], "N"
    jne .notHFNT

    cmp byte[edi+3], "T"
    jne .notHFNT

.validateSize:

    hx.syscall hx.fileExists

;; In EAX, the file size. It must not be larger than 2000 bytes

    mov ebx, 2000

    cmp eax, ebx
    jng .continue

    jmp .biggerSize

.continue:

    clc

    ret

.withoutFontError:

    fputs fnt.error

    jmp finish

.notHFNT:

    stc

    ret

.biggerSize:

    fputs fnt.biggerSize

    jmp finish

;;************************************************************************************

appFileBuffer:
