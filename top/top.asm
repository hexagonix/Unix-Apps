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

    mov esi, top.memoryDescription

    call makeDescriptionBanner

    hx.syscall hx.getCursor

    mov byte[top.positionY], dh

    hx.syscall hx.memoryUsage

;; Save memory used by processes

    push eax

    mov eax, ecx

    printInteger

    gotoxy 13, [top.positionY]

    hx.syscall hx.memoryUsage

    printInteger

    gotoxy 40, [top.positionY]

    hx.syscall hx.memoryUsage

;; Save memory used by kernel

    push edx

    mov eax, edx

    printInteger

    gotoxy 64, [top.positionY]

    pop eax
    pop ebx

    add eax, ebx

    printInteger

    call setDefaultColor

    putNewLine

    hx.syscall hx.getProcesses ;; EAX = record count, ESI = record size (dd) + records

    mov dword[remainingCount], eax

    mov eax, dword[esi] ;; Record size, read from the message itself

    mov dword[processRecordSize], eax

    add esi, 4 ;; Skip past the record size

    mov [recordsPointer], esi

    putNewLine

    mov esi, top.header

    call makeDescriptionBanner

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

    hx.syscall hx.getCursor

    gotoxy 6, dh

    ret

;;************************************************************************************

;; Prints the state text for a process at a fixed column
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

    cmp al, 6
    je .idle

    fputs top.stateUnknown

    ret

.ready:

    fputs top.stateReady

    ret

.running:

    fputs top.stateRunning

    ret

.blocked:

    fputs top.stateBlocked

    ret

.zombie:

    fputs top.stateZombie

    ret

.sleeping:

    fputs top.stateSleeping

    ret

.idle:

    fputs top.stateIdle

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

    fputs top.stateKernel

    ret

;;************************************************************************************

;; Create a banner for memory usage description
;;
;; Input:
;;
;; ESI - Text to show
;;
;; Output:
;;
;; Nothing

makeDescriptionBanner:

    push esi

    mov eax, [top.backgroundColor]
    mov ebx, [top.fontColor]

    hx.syscall hx.setColor

    ;; Get and set position on screen

    hx.syscall hx.getCursor

    mov al, dh

    hx.syscall hx.clearLine

    pop esi

    fputs esi

    call setDefaultColor

    putNewLine

    ret

;;************************************************************************************

VERSION equ "4.3.0"

top:

.start:
db "top version ", VERSION, 10, 0
.memoryDescription:
db "Total (MB) | User memory used (bytes) | Kernel memory (bytes) | Total used (bytes, kernel+user)", 0
.header:
db "PID   NAME          STATUS    PARENT", 0
.use:
db "Usage: top", 10, 10
db "Displays processes loaded on the system.", 10, 10
db "Kernel processes are filtered and not displayed in this list.", 10, 10
db "top version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.stateReady:
db "READY", 0
.stateRunning:
db "RUNNING", 0
.stateBlocked:
db "BLOCKED", 0
.stateZombie:
db "ZOMBIE", 0
.stateSleeping:
db "SLEEPING", 0
.stateUnknown:
db "UNKNOWN", 0
.stateIdle:
db "IDLE", 0
.stateKernel:
db "KERNEL", 0
.fontColor:       dd 0
.backgroundColor: dd 0
.positionY: db 0

;;************************************************************************************

processRecordSize: dd 0 ;; read from the hx.getProcesses response itself

recordsPointer: dd ?
remainingCount: dd 0
currentProcess: dd ' '
parameters:     dd ?