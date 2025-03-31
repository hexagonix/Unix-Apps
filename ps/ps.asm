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
include "memory.s"

;;************************************************************************************

applicationStart: ;; Entry point

    mov [parameters], edi

    putNewLine

    mov edi, ps.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, ps.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, ps.parameterProcesses
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc displayProcesses

    mov edi, ps.parameterMemory
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc parameterMemory

    mov edi, ps.parameterOtherProcesses
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc parameterOtherProcesses

    jmp displayProcesses

;;************************************************************************************

displayProcesses:

    fputs ps.header

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

    inc dword[PIDs]

.processLoop:

    push ds ;; User mode data segment (38h selector)
    pop es

    call readProcessList

    mov eax, [PIDs]

    printInteger

    call putSpace

    fputs [currentProcess]

    cmp dword[numbersPID], 01h
    je .continue

    inc dword[processCount]
    inc dword[PIDs]
    dec dword[numbersPID]

    putNewLine

    jmp .processLoop

.continue:

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs ps.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

putSpace:

    hx.syscall hx.getCursor

    mov al, dh

    gotoxy 5, dh

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

parameterMemory:

    fputs ps.memoryUsage

    hx.syscall hx.memoryUsage

    printInteger

    fputs ps.kbytes

    jmp finish

;;************************************************************************************

parameterOtherProcesses:

    hx.syscall hx.pid

    push eax

    fputs ps.numberOfProcesses

    pop eax

    printInteger

    fputs ps.processes

    jmp finish

;;************************************************************************************

VERSION equ "2.0.0"

ps:

.header:
db "PID  PROCESS", 10, 0
.use:
db "Usage: ps [parameter]", 10, 10
db "Displays process information and usage of memory and system resources.", 10, 10
db "Possible parameters (in case of missing parameters, the '-a' option will be selected):", 10, 10
db "-a - Display user processes running on device.", 10
db "-m - Display all memory usage (user+kernel).", 10
db "-o - Displays the number of processes currently running.", 10, 10
db "ps version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.memoryUsage:
db "Memory usage: ", 0
.kbytes:
db " bytes used by running processes (user+kernel).", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.parameterOtherProcesses:
db "-o", 0
.parameterProcesses:
db "-a", 0
.parameterMemory:
db "-m", 0
.numberOfProcesses:
db "There are currently ", 0
.processes:
db " processes running.", 0
.positionY: db 0

;;************************************************************************************

remainingList:  dd ?
processCount:   dd 0
PIDs:           dd 0
numbersPID:     dd 0
currentProcess: dd ' '
parameters:     dd ?