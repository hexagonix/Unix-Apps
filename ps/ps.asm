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
;;                         Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2026, Felipe Miguel Nery Lunkes
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
appHeader headerHAPP HAPP.Architectures.i386, 1, 6, applicationStart, 01h

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

    hx.syscall hx.getProcesses ;; EAX = record count, ESI = record size (dd) + records

    mov dword[remainingCount], eax

    mov eax, dword[esi] ;; Record size, read from the message itself

    mov dword[processRecordSize], eax

    add esi, 4 ;; Skip past the record size

    mov [recordsPointer], esi

.processLoop:

    cmp dword[remainingCount], 0
    je .continue

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, [recordsPointer]

    mov eax, dword[esi] ;; PID

    printInteger

    call putSpace

    mov edx, esi

    add edx, 9 ;; Process name field

    mov [currentProcess], edx

    fputs [currentProcess]

    mov esi, [recordsPointer]

    mov al, byte[esi+8] ;; State

    call putStatus

    mov esi, [recordsPointer]

    mov ebx, dword[esi+4] ;; Parent PID

    call putParent

    mov eax, dword[processRecordSize]

    add dword[recordsPointer], eax

    dec dword[remainingCount]

    cmp dword[remainingCount], 0
    je .continue

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

    gotoxy 6, dh

    ret

;;************************************************************************************

;; Prints the status text for a process at a fixed column
;;
;; Input:
;;
;; AL - State byte, as returned by hx.getProcesses

putStatus:

    push eax

    hx.syscall hx.getCursor

    gotoxy 20, dh

    pop eax

    cmp al, 1
    je .ready

    cmp al, 2
    je .running

    cmp al, 3
    je .blocked

    cmp al, 4
    je .zombie

    cmp al, 5
    je .sleeping

    fputs ps.statusUnknown

    ret

.ready:

    fputs ps.statusReady

    ret

.running:

    fputs ps.statusRunning

    ret

.blocked:

    fputs ps.statusBlocked

    ret

.zombie:

    fputs ps.statusZombie

    ret

.sleeping:

    fputs ps.statusSleeping

    ret

;;************************************************************************************

;; Prints the parent PID at a fixed column, or KERNEL if the process was
;; launched directly by the kernel rather than by another process
;;
;; Input:
;;
;; EBX - Parent PID, as returned by hx.getProcesses (0 = no parent)

putParent:

    push ebx

    hx.syscall hx.getCursor

    gotoxy 30, dh

    pop ebx

    cmp ebx, 0
    je .kernel

    mov eax, ebx

    printInteger

    ret

.kernel:

    fputs ps.statusKernel

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

VERSION equ "3.2.0"

ps:

.header:
db "PID   NAME          STATUS    PARENT", 10, 0
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
.statusReady:
db "READY", 0
.statusRunning:
db "RUNNING", 0
.statusBlocked:
db "BLOCKED", 0
.statusZombie:
db "ZOMBIE", 0
.statusSleeping:
db "SLEEPING", 0
.statusUnknown:
db "UNKNOWN", 0
.statusKernel:
db "KERNEL", 0
.positionY: db 0

;;************************************************************************************

processRecordSize: dd 0 ;; Read from the hx.getProcesses response itself

recordsPointer: dd ?
remainingCount: dd 0
currentProcess: dd ' '
parameters:     dd ?