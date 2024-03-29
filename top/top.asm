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

applicationStart: ;; Entry point

    mov [parameters], edi

    hx.syscall hx.getColor

    mov dword[top.fontColor], eax
    mov dword[top.backgroundColor], ebx

    putNewLine

    mov edi, top.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, top.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    jmp displayProcesses

displayProcesses:

    fputs top.start

    call setDefaultColor

    fputs top.memoryUsage

    mov eax, VERDE_FLORESTA

    call setTextColor

    hx.syscall hx.memoryUsage

    printInteger

    call setDefaultColor

    fputs top.bytes

    fputs top.totalMemory

    mov eax, VERDE_FLORESTA

    call setTextColor

    hx.syscall hx.memoryUsage

    mov eax, ecx

    printInteger

    call setDefaultColor

    fputs top.mbytes

    putNewLine

    hx.syscall hx.getProcesses

    mov [remainingList], esi
    mov dword[numbersPID], eax

    push eax

    pop ebx

    xor ecx, ecx
    xor edx, edx

    push eax

    mov edx, eax

    mov dword[processCount], 00h

    fputs top.header

    inc dword[PIDs]

.processLoop:

    push ds ;; User mode data segment (38h selector)
    pop es

    call readProcessList

    fputs [currentProcess]

    call putSpace

    mov eax, [PIDs]

    printInteger

    mov al, 10

    hx.syscall hx.printCharacter

    cmp dword[numbersPID], 01h
    je .continue

    inc dword[processCount]
    inc dword[PIDs]
    dec dword[numbersPID]

    jmp .processLoop

.continue:

    call setDefaultColor

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs top.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;; Function to define the color of the content to be displayed
;;
;; Input:
;;
;; EAX - Text color

setTextColor:

    mov ebx, [top.backgroundColor]

    hx.syscall hx.setColor

    ret

;;************************************************************************************

setDefaultColor:

    mov eax, [top.fontColor]
    mov ebx, [top.backgroundColor]

    hx.syscall hx.setColor

    ret

;;************************************************************************************

putSpace:

    push ecx
    push ebx
    push eax

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, [currentProcess]

    hx.syscall hx.stringSize

    mov ebx, 17

    sub ebx, eax

    mov ecx, ebx

.spaceLoop:

    mov al, ' '

    hx.syscall hx.printCharacter

    dec ecx

    cmp ecx, 0
    je .done

    jmp .spaceLoop

.done:

    pop eax
    pop ebx
    pop ecx

    ret

;;************************************************************************************

;; Get parameters directly from the command line

readProcessList:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, [remainingList]
    mov [currentProcess], esi

    mov al, ' '

    hx.syscall hx.findCharacter

    jc .done

    mov al, ' '

    call findCharacterInList

    hx.syscall hx.trimString

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

findCharacterInList:

    lodsb

    cmp al, ' '
    je .done

    jmp findCharacterInList

.done:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

VERSION equ "1.6.0"

top:

.start:
db "Hexagonix process viewer", 10, 10, 0
.pid:
db "PID of this process: ", 0
.memoryUsage:
db "Memory usage: ", 0
.totalMemory:
db 10, "Total installed memory identified: ", 0
.bytes:
db " bytes used by running processes.", 0
.kbytes:
db " kbytes.", 0
.mbytes:
db " megabytes.", 0
.header:
db 10, "Process        | PID", 10
db "---------------|----", 10, 10, 0
.use:
db "Usage: top", 10, 10
db "Displays processes loaded on the system.", 10, 10
db "Kernel processes are filtered and not displayed in this list.", 10, 10
db "top version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.fontColor:       dd 0
.backgroundColor: dd 0

;;************************************************************************************

remainingList:  dd ?
processCount:   dd 0
PIDs:           dd 0
numbersPID:     dd 0
currentProcess: dd ' '
parameters:     dd ?