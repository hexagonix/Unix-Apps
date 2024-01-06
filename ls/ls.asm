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

    mov [parameters], edi ;; Save command line parameters for future use

    hx.syscall hx.getColor

    mov dword[ls.fontColor], eax
    mov dword[ls.backgroundColor], ebx

;; The resolution in use will be checked, so the application adapts to the size of the output and
;; the amount of information that can be displayed per line.
;; This way, it can display a smaller number of files with lower resolution and a larger number
;;  per line if the resolution allows it.

checkResolution:

    hx.syscall hx.getResolution

    cmp eax, 1
    je .graphicsMode1

    cmp eax, 2
    je .graphicsMode2

;; (n+1) files can be displayed, as the counter starts counting from zero.
;; Use this information for future implementations in the application.

.graphicsMode1:

    mov dword[displayLimit], 5h ;; 6 files can be displayed per line (n+1)

    jmp checkParameters

.graphicsMode2:

    mov dword[displayLimit], 7h ;; 8 files can be displayed per line (n+1)

    jmp checkParameters

;;************************************************************************************

;; Now the parameters will be checked and necessary actions will be taken

checkParameters:

    mov esi, [parameters]

    mov edi, ls.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, ls.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, ls.parameterAllFiles
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc configureDisplay

    cmp byte[esi], 0
    je list

    jmp checkFile

;;************************************************************************************

configureDisplay:

    mov byte[ls.listAll], 01h

    jmp list

;;************************************************************************************

list:

    putNewLine

    hx.syscall hx.listFiles ;; Get files in ESI

    jc .listError

    mov [remainingList], esi

    push eax

    pop ebx

    xor ecx, ecx
    xor edx, edx

.loopFiles:

    push ds ;; User mode data segment (38h selector)
    pop es

    push ebx
    push ecx

    call readFileList

    push esi

    sub esi, 5

    mov edi, ls.extensionAPP

    hx.syscall hx.compareWordsString ;; Check for .APP extension

    jc .application

    mov edi, ls.extensionSIS

    hx.syscall hx.compareWordsString

    jc .system

    mov edi, ls.extensionASM

    hx.syscall hx.compareWordsString

    jc .fileASM

    mov edi, ls.extensionBIN

    hx.syscall hx.compareWordsString

    jc .fileBIN

    mov edi, ls.extensionUNX

    hx.syscall hx.compareWordsString

    jc .fileUNX

    mov edi, ls.extensionFNT

    hx.syscall hx.compareWordsString

    jc .fileFNT

    mov edi, ls.extensionOCL

    hx.syscall hx.compareWordsString

    jc .fileOCL

    mov edi, ls.extensionMOD

    hx.syscall hx.compareWordsString

    jc .fileMOD

    mov edi, ls.extensionCOW

    hx.syscall hx.compareWordsString

    jc .fileCOW

    mov edi, ls.extensionMAN

    hx.syscall hx.compareWordsString

    jc .fileMAN

    jmp .commonFile

.application:

    pop esi

    mov eax, VERDE_FLORESTA

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.system:

    pop esi

    mov eax, AZUL_MEDIO

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileASM:

    pop esi

    mov eax, VERMELHO

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileBIN:

    pop esi

    mov eax, VIOLETA_ESCURO

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileUNX:

    pop esi

    mov eax, MARROM_PERU

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileOCL: ;; It must not be displayed

    pop esi

    jmp .skipFile

.fileMOD:

    pop esi

    cmp byte[ls.listAll], 01h
    jne .skipFile

    mov eax, HEXAGONIX_BLOSSOM_LAVANDA

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileCOW: ;; It must not be displayed

    pop esi

    cmp byte[ls.listAll], 01h
    jne .skipFile

    mov eax, HEXAGONIX_BLOSSOM_VERDE

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileMAN:

    pop esi

    cmp byte[ls.listAll], 01h
    jne .skipFile

    mov eax, TOMATE

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.fileFNT:

    pop esi

    cmp byte[ls.listAll], 01h
    jne .skipFile

    mov eax, HEXAGONIX_BLOSSOM_AZUL_PO

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.skipFile:

    dec edx

    jmp .withoutSpace

.commonFile:

    pop esi

    mov eax, HEXAGONIX_BLOSSOM_VERDE_CLARO

    call setFileColor

    fputs [currentFile]

    call setDefaultColor

    jmp .continue

.continue:

    call putSpace

.withoutSpace:

    pop ecx
    pop ebx

    cmp ecx, ebx
    je .finished

    cmp edx, [displayLimit]
    je .createNewLine

    inc ecx
    inc edx

    jmp .loopFiles

.createNewLine:

    xor edx, edx

;; Correction to not add more lines

    add ecx, 1

;; Continue

    putNewLine

    jmp .loopFiles

.finished:

    cmp edx, 1h  ;; Checks if there is any lone file in a line
    jl finish

    ;; putNewLine

    jmp finish

.listError:

    fputs ls.listError

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs ls.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;; Function to set the representation color of a given file
;;
;; Input:
;;
;; EAX - Text color

setFileColor:

    mov ebx, dword[ls.backgroundColor]

    hx.syscall hx.setColor

    ret

;;************************************************************************************

setDefaultColor:

    mov eax, dword[ls.fontColor]
    mov ebx, dword[ls.backgroundColor]

    hx.syscall hx.setColor

    ret

;;************************************************************************************

putSpace:

    push ecx
    push ebx
    push eax

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, [currentFile]

    hx.syscall hx.stringSize

    mov ebx, 15

    sub ebx, eax

    mov ecx, ebx

.loopSpace:

    mov al, ' '

    hx.syscall hx.printCharacter

    dec ecx

    cmp ecx, 0
    je .finished

    jmp .loopSpace

.finished:

    pop eax
    pop ebx
    pop ecx

    ret

;;************************************************************************************

;; Get parameters directly from the command line

readFileList:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, [remainingList]
    mov [currentFile], esi

    mov al, ' '

    hx.syscall hx.findCharacter

    jc .done

    mov al, ' '

    call findCharacterFileList

    mov [remainingList], esi

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

findCharacterFileList:

    lodsb

    cmp al, ' '
    je .done

    jmp findCharacterFileList

.done:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

checkFile:

    mov esi, [parameters]

    hx.syscall hx.fileExists

    jc finish

    putNewLine
    putNewLine

    mov esi, [parameters]

    hx.syscall hx.stringToUppercase

    mov [parameters], esi

    printString

    jmp finish

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "3.4.0"

ls:

.extensionAPP:
db ".APP", 0
.extensionSIS:
db ".SIS", 0
.extensionASM:
db ".ASM", 0
.extensionBIN:
db ".BIN", 0
.extensionUNX:
db ".UNX", 0
.extensionFNT:
db ".FNT", 0
.extensionOCL:
db ".OCL", 0
.extensionCOW:
db ".COW", 0
.extensionMAN:
db ".MAN", 0
.extensionMOD:
db ".MOD", 0
.listError:
db 10, "Error listing the files present on the volume.", 0
.use:
db 10, "Usage: ls", 10, 10
db "Lists and displays the files present on the current volume, sorting them by type.", 10, 10
db "Available parameters:", 10, 10
db "-a - List all files available on the volume.", 10, 10
db "ls version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.parameterAllFiles:
db "-a" ,0
.listAll:
db 0
.fontColor:
dd 0
.backgroundColor:
dd 0
.colorAPP: dd 0
.colorSIS: dd 0
.colorASM: dd 0
.colorBIN: dd 0
.colorUNX: dd 0
.colorFNT: dd 0
.colorOCL: dd 0
.colorCOW: dd 0
.colorMAN: dd 0

parameters:    dd ?
remainingList: dd ?
displayLimit:  dd 0
currentFile:   dd ' '
