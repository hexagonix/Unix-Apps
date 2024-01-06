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
;;                         Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
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

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    call getParameters

    jc  applicationUsage

    push esi
    push edi

    mov edi, cp.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, cp.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    pop edi
    pop esi

    mov esi, [inputFile]

    hx.syscall hx.fileExists

    jc inputFileNotFound

    mov esi, [outputFile]

    hx.syscall hx.fileExists

    jnc outputPresent

;; Now let's open the source file for copying

    mov esi, [inputFile]
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc openError

    mov esi, [inputFile]

    hx.syscall hx.fileExists

;; Save file

    mov esi, [outputFile]
    mov edi, appFileBuffer

    hx.syscall hx.create

    jc saveError

;; Saving success

    jmp finish

;;************************************************************************************

saveError:

    fputs cp.saveError

    jmp finish

;;************************************************************************************

openError:

    fputs cp.openError

    jmp finish

;;************************************************************************************

inputFileNotFound:

    fputs cp.sourceNotFound

    jmp finish

;;************************************************************************************

outputPresent:

    fputs cp.outputAlreadyExists

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;; Get the necessary parameters directly from the command line

getParameters:

    mov esi, [parameters]
    mov [inputFile], esi

    cmp byte[esi], 0
    je applicationUsage

    mov al, ' '

    hx.syscall hx.findCharacter

    jc applicationUsage

    mov al, ' '

    call findCharacterCP

    mov [outputFile], esi

    jmp .done

.done:

    clc

    ret

;;************************************************************************************

;; Searches for a specific character in the given String
;;
;; Input:
;;
;; ESI - String to be checked
;; AL  - Character to search for
;;
;; Output:
;;
;; ESI - Character position in the given String

findCharacterCP:

    lodsb

    cmp al, ' '
    je .done

    jmp findCharacterCP

.done:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

applicationUsage:

    fputs cp.use

    jmp finish

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "2.4.0"

cp:

db 10, "File not found. Please check filename and try again.", 0
.use:
db 10, "Usage: cp [input file] [output file]", 10, 10
db "Performs a copy of a given file into another. Two file names are required, one being", 10
db "for input and another for output.", 10, 10
db "cp version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.sourceNotFound:
db 10, "The source file cannot be found on this volume.", 0
.outputAlreadyExists:
db 10, "A file with the given name already exists for the destination. Please remove the file and try again.", 0
.openError:
db 10, "An error occurred while trying to open the source file.", 0
.saveError:
db 10, "An error occurred while requesting to save the file.", 10
db "This could be due to write protection, volume removal, out of storage or because the system is busy.", 10
db "Please try again later.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0

parameters: dd 0
inputFile:  dd ?
outputFile: dd ?

;;************************************************************************************

appFileBuffer:
