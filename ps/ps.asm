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

;; Architecture | Version | Subversion | Entry point | Image type | BSS size
headerHAPP HAPP.Architectures.i386, 1, 8, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"
include "memory.s"
include "process.s"

;;************************************************************************************

applicationStart: ;; Entry point

    mov [parameters], edi

    putNewLine

    mov edi, ps.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, ps.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, ps.parameterProcesses
    mov esi, [parameters]

    call compareWordsInString

    jc displayProcesses

    mov edi, ps.parameterMemory
    mov esi, [parameters]

    call compareWordsInString

    jc parameterMemory

    mov edi, ps.parameterOtherProcesses
    mov esi, [parameters]

    call compareWordsInString

    jc parameterOtherProcesses

    jmp displayProcesses

;;************************************************************************************

displayProcesses:

    fputs ps.header

    mov dword[processesBufferSize], 2048 ;; Arbitrary starting guess

.allocateBuffer:

    mov ebx, dword[processesBufferSize]

    call malloc

    cmp eax, 0
    je processesMallocError

    mov dword[processesBuffer], ebx
    mov esi, ebx
    mov ecx, dword[processesBufferSize]

    hx.syscall hx.getProcesses ;; EAX = record count, or exact size needed if CF is set

    jnc .haveProcesses

;; The buffer was too small. EAX already holds the exact size needed,
;; reported by the kernel before it wrote anything

    push eax

    mov ebx, dword[processesBuffer]
    mov ecx, dword[processesBufferSize]

    call free

    pop eax

    mov dword[processesBufferSize], eax

    jmp .allocateBuffer

.haveProcesses:

    mov dword[remainingCount], eax
    mov esi, dword[processesBuffer]
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
    mov eax, dword[esi + hx.process.record.pid]

    printInteger

    call putSpace

    mov edx, esi

    add edx, hx.process.record.name

    mov [currentProcess], edx

    fputs [currentProcess]

    mov esi, [recordsPointer]
    mov al, byte[esi + hx.process.record.state]

    call putStatus

    mov esi, [recordsPointer]
    mov ebx, dword[esi + hx.process.record.parentPID]

    call putParent

    mov esi, [recordsPointer]

    mov al, byte[esi + hx.process.record.tty]

    call putTTY

    mov esi, [recordsPointer]
    mov ecx, dword[esi + hx.process.record.memory]

    call putMemory

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

processesMallocError:

    fputs ps.mallocError

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs ps.use

    jmp finish

;;************************************************************************************

finish:

    cmp dword[processesBuffer], 0
    je .noBufferToFree

    mov ebx, dword[processesBuffer]
    mov ecx, dword[processesBufferSize]

    call free

.noBufferToFree:

    hx.syscall hx.exit

;;************************************************************************************

putSpace:

    hx.syscall hx.getCursor

    gotoxy 6, dh

    ret

;;************************************************************************************

;; Pads the cursor to at least the given column. A name long enough to
;; already be past it gets a single space instead of an overlap
;;
;; Input:
;;
;; AL - Target column

padToColumn:

    push eax

    hx.syscall hx.getCursor

    pop eax

    cmp dl, al
    jae .gapOnly

    gotoxy al, dh

    ret

.gapOnly:

    fputs ps.gap

    ret

;;************************************************************************************

;; Prints the state text for a process, lined up under the row above via
;; padToColumn
;;
;; Input:
;;
;; AL - State byte, as returned by hx.getProcesses

putStatus:

    push eax

    mov al, ps.statusColumn

    call padToColumn

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

    fputs ps.stateUnknown

    ret

.ready:

    fputs ps.stateReady

    ret

.running:

    fputs ps.stateRunning

    ret

.blocked:

    fputs ps.stateBlocked

    ret

.zombie:

    fputs ps.stateZombie

    ret

.sleeping:

    fputs ps.stateSleeping

    ret

.idle:

    fputs ps.stateIdle

    ret

;;************************************************************************************

;; Prints the parent PID lined up under the row above via padToColumn, or
;; KERNEL if the process was launched directly by the kernel rather than
;; by another process
;;
;; Input:
;;
;; EBX - Parent PID, as returned by hx.getProcesses (0 = no parent)

putParent:

    push ebx

    mov al, ps.parentColumn

    call padToColumn

    pop ebx

    cmp ebx, 0
    je .kernel

    mov eax, ebx

    printInteger

    ret

.kernel:

    fputs ps.stateKernel

    ret

;;************************************************************************************

;; Prints the VT index lined up under the row above via padToColumn
;;
;; Input:
;;
;; AL - VT index, as returned by hx.getProcesses

putTTY:

    push eax

    mov al, ps.ttyColumn

    call padToColumn

    pop eax

    fputs ps.tty

    movzx eax, al

    printInteger

    ret

;;************************************************************************************

;; Prints how much memory a process is holding, in kilobytes, lined up under
;; the row above via padToColumn
;;
;; Input:
;;
;; ECX - Bytes held, as returned by hx.getProcesses

putMemory:

    push ecx

    mov al, ps.memoryColumn

    call padToColumn

    pop ecx

    call convertToKbytes

    printInteger

    fputs ps.kbytesSuffix

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

VERSION equ "3.4.0"

ps.statusColumn = 30
ps.parentColumn = 42
ps.ttyColumn    = 54
ps.memoryColumn = 62

ps:

.header:
db "PID   NAME                    STATUS      PARENT      TTY     MEMORY", 10, 0
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
.kbytesSuffix:
db " kB", 0
.gap: ;; Fallback when a name already ran past the target column
db " ", 0
.mallocError:
db 10, "Failed to allocate a buffer for the process listing.", 0
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
.stateIdle:
db "IDLE", 0
.stateUnknown:
db "UNKNOWN", 0
.stateKernel:
db "KERNEL", 0
.tty:
db "tty", 0
.positionY: db 0

;;************************************************************************************

processRecordSize: dd 0 ;; Read from the hx.getProcesses response itself

recordsPointer: dd ?
remainingCount: dd 0
currentProcess: dd ' '
parameters:     dd ?

processesBuffer:     dd 0
processesBufferSize: dd ?