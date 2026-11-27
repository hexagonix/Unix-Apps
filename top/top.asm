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
headerHAPP HAPP.Architectures.i386, 1, 9, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"
include "memory.s"
include "process.s"
include "sysctl.s"

;;************************************************************************************

applicationStart: ;; Entry point

    mov [parameters], edi

    putNewLine

    mov edi, top.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, top.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    jmp displayProcesses

displayProcesses:

    fputs top.start

    call setDefaultColor

    mov esi, top.memoryDescription

    call makeDescriptionBanner

    hx.syscall hx.memoryUsage

;; Save memory used by processes

    push eax

    mov eax, ecx

    printInteger

    gotoColumn 13

    hx.syscall hx.memoryUsage

    printInteger

    gotoColumn 40

    hx.syscall hx.memoryUsage

;; Save memory used by kernel

    push edx

    mov eax, edx

    printInteger

    gotoColumn 64

    pop eax
    pop ebx

    add eax, ebx

    printInteger

    call setDefaultColor

    putNewLine

    mov dword[processesBufferSize], 2048 ;; Arbitrary starting guess

;; Two readings a second apart, as the share of the processor is what changed
;; between them

    mov edi, cpuBefore

    call readCPUTime

    call readProcesses

    jc processesMallocError

    call rememberTicks

    mov ecx, dword[cpuBefore + hx.sysctl.cpuTime.frequency]

    jecxz .secondReading

    hx.syscall hx.sleep

.secondReading:

    mov edi, cpuAfter

    call readCPUTime

    call readProcesses

    jc processesMallocError

    call putCPULine

    call putMemoryLine

    putNewLine

    mov esi, top.header

    call makeDescriptionBanner

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

    mov esi, [currentProcess]

    call putTracked

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

    call putCPU

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

processesMallocError:

    fputs top.mallocError

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs top.use

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

;; Function to define the color of the content to be displayed
;;
;; Input:
;;
;; EAX - Text color

setTextColor:

    setConsoleForeground eax

    ret

;;************************************************************************************

setDefaultColor:

    resetConsoleColor

    ret

;;************************************************************************************

putSpace:

    gotoColumn top.nameColumn

    mov dword[column], top.nameColumn

    ret

;;************************************************************************************

;; Pads the line to at least the given column, counting what putTracked
;; printed, as no terminal is asked where its cursor is. A name long enough to
;; already be past it gets a single space instead of an overlap
;;
;; Input:
;;
;; AL - Target column

padToColumn:

    movzx eax, al

    cmp dword[column], eax

    jae .gapOnly

    mov dword[column], eax

    gotoColumn al

    ret

.gapOnly:

    mov esi, top.gap

    call putTracked

    ret

;;************************************************************************************

;; Prints ESI and counts the columns it takes
;;
;; Input:
;;
;; ESI - String

putTracked:

    push eax

    fputs esi

    call stringSize

    add dword[column], eax

    pop eax

    ret

;; Input: EAX - Number to print, counted like putTracked

putNumberTracked:

    push edi

    mov edi, numberBuffer

    call integetToString

    mov esi, numberBuffer

    call putTracked

    pop edi

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

    mov al, top.statusColumn

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

    mov esi, top.stateUnknown

    call putTracked

    ret

.ready:

    mov esi, top.stateReady

    call putTracked

    ret

.running:

    mov esi, top.stateRunning

    call putTracked

    ret

.blocked:

    mov esi, top.stateBlocked

    call putTracked

    ret

.zombie:

    mov esi, top.stateZombie

    call putTracked

    ret

.sleeping:

    mov esi, top.stateSleeping

    call putTracked

    ret

.idle:

    mov esi, top.stateIdle

    call putTracked

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

    mov al, top.parentColumn

    call padToColumn

    pop ebx

    cmp ebx, 0
    je .kernel

    mov eax, ebx

    call putNumberTracked

    ret

.kernel:

    mov esi, top.stateKernel

    call putTracked

    ret

;;************************************************************************************

;; Prints the VT index lined up under the row above via padToColumn
;;
;; Input:
;;
;; AL - VT index, as returned by hx.getProcesses

putTTY:

    push eax

    mov al, top.ttyColumn

    call padToColumn

    pop eax

    mov esi, top.tty

    call putTracked

    movzx eax, al

    call putNumberTracked

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

    mov al, top.memoryColumn

    call padToColumn

    pop ecx

    call convertToKbytes

    printInteger

    fputs top.kbytesSuffix

    ret

;;************************************************************************************

;; Reads the processes into processesBuffer, made larger when the kernel asks
;; for more, and points recordsPointer and remainingCount at them
;;
;; Output: CF set if there was no memory for the buffer

readProcesses:

    cmp dword[processesBuffer], 0

    jne .read

.allocate:

    mov ebx, dword[processesBufferSize]

    call malloc

    cmp eax, 0

    je .failed

    mov dword[processesBuffer], ebx

.read:

    mov esi, dword[processesBuffer]
    mov ecx, dword[processesBufferSize]

    hx.syscall hx.getProcesses ;; EAX = record count, or exact size needed if CF is set

    jnc .done

;; The buffer was too small. EAX already holds the exact size needed,
;; reported by the kernel before it wrote anything

    push eax

    mov ebx, dword[processesBuffer]
    mov ecx, dword[processesBufferSize]

    call free

    pop eax

    mov dword[processesBufferSize], eax
    mov dword[processesBuffer], 0

    jmp .allocate

.done:

    mov dword[remainingCount], eax
    mov esi, dword[processesBuffer]
    mov eax, dword[esi] ;; Record size, read from the message itself
    mov dword[processRecordSize], eax

    add esi, 4 ;; Skip past the record size

    mov [recordsPointer], esi

    clc

    ret

.failed:

    stc

    ret

;;************************************************************************************

;; Reads function 2 of hx.sysctl, with a frequency of 0 from a kernel that
;; does not count ticks
;;
;; Input: EDI - Where it goes, hx.sysctl.cpuTime.size bytes

readCPUTime:

    push edi

    mov ebx, hx.sysctl.getCPUTime
    mov esi, edi
    mov ecx, hx.sysctl.cpuTime.size

    hx.syscall hx.sysctl

    pop edi

    jnc .done

    mov dword[edi + hx.sysctl.cpuTime.frequency], 0

.done:

    ret

;;************************************************************************************

;; Keeps the ticks of each process in the first reading, by PID

rememberTicks:

    mov dword[firstCount], 0

    cmp dword[processRecordSize], hx.process.record.withTicks

    jb .done

    mov esi, [recordsPointer]
    mov ecx, [remainingCount]
    mov edi, firstTicks

.next:

    cmp ecx, 0

    je .done

    cmp dword[firstCount], top.maxSamples

    jae .done

    mov eax, dword[esi + hx.process.record.pid]
    mov dword[edi], eax

    mov eax, dword[esi + hx.process.record.userTicks]
    add eax, dword[esi + hx.process.record.systemTicks]
    mov dword[edi + 4], eax

    add edi, 8
    add esi, dword[processRecordSize]

    inc dword[firstCount]

    dec ecx

    jmp .next

.done:

    ret

;;************************************************************************************

;; The ticks of the processor between the two readings, by what it was doing
;;
;; Output: CF set, with totalDelta at 0, if there is nothing to compare

cpuDeltas:

    cmp dword[cpuBefore + hx.sysctl.cpuTime.frequency], 0

    je .none

    cmp dword[cpuAfter + hx.sysctl.cpuTime.frequency], 0

    je .none

    mov eax, dword[cpuAfter + hx.sysctl.cpuTime.user]
    sub eax, dword[cpuBefore + hx.sysctl.cpuTime.user]
    mov dword[userDelta], eax

    mov eax, dword[cpuAfter + hx.sysctl.cpuTime.system]
    sub eax, dword[cpuBefore + hx.sysctl.cpuTime.system]
    mov dword[systemDelta], eax

    mov eax, dword[cpuAfter + hx.sysctl.cpuTime.idle]
    sub eax, dword[cpuBefore + hx.sysctl.cpuTime.idle]
    mov dword[idleDelta], eax

    add eax, dword[userDelta]
    add eax, dword[systemDelta]

    mov dword[totalDelta], eax

    cmp eax, 0

    je .none

    clc

    ret

.none:

    mov dword[totalDelta], 0

    stc

    ret

;; CPU: N.N% user, N.N% system, N.N% idle, as the line of top in BSD

putCPULine:

    call cpuDeltas

    jc .done

    fputs top.cpuLabel

    mov eax, dword[userDelta]

    call putPercent

    fputs top.cpuUser

    mov eax, dword[systemDelta]

    call putPercent

    fputs top.cpuSystem

    mov eax, dword[idleDelta]

    call putPercent

    fputs top.cpuIdle

    putNewLine

.done:

    ret

;; Mem: N kB wired, N kB processes, N kB free, as the line of top in BSD

putMemoryLine:

    mov ebx, hx.sysctl.getVMStats
    mov esi, vmStats
    mov ecx, hx.sysctl.vmStats.size

    hx.syscall hx.sysctl

    jc .done

    fputs top.memoryLabel

    mov eax, dword[vmStats + hx.sysctl.vmStats.wiredStatic]

    add eax, dword[vmStats + hx.sysctl.vmStats.wiredDynamic]

    call putPagesInKbytes

    fputs top.memoryWired

    mov eax, dword[vmStats + hx.sysctl.vmStats.processes]

    call putPagesInKbytes

    fputs top.memoryProcesses

    mov eax, dword[vmStats + hx.sysctl.vmStats.free]

    call putPagesInKbytes

    fputs top.memoryFree

    putNewLine

.done:

    ret

;; Input: EAX - Pages, printed as kilobytes

putPagesInKbytes:

    mov ecx, dword[vmStats + hx.sysctl.vmStats.pageSize]

    shr ecx, 10

    mul ecx

    printInteger

    ret

;; The share of the processor the process at recordsPointer had between the
;; two readings, lined up under the row above via padToColumn

putCPU:

    cmp dword[totalDelta], 0

    je .done

    cmp dword[processRecordSize], hx.process.record.withTicks

    jb .done

    mov al, top.cpuColumn

    call padToColumn

    mov esi, [recordsPointer]
    mov eax, dword[esi + hx.process.record.userTicks]
    add eax, dword[esi + hx.process.record.systemTicks]
    mov edx, dword[esi + hx.process.record.pid]

;; Less what it had in the first reading, if it was there

    mov edi, firstTicks
    mov ecx, [firstCount]

.find:

    cmp ecx, 0

    je .known

    cmp dword[edi], edx

    je .found

    add edi, 8

    dec ecx

    jmp .find

.found:

    sub eax, dword[edi + 4]

.known:

    call putPercent

.done:

    ret

;; Prints a part of totalDelta as N.N%, counted like putTracked
;;
;; Input: EAX - Ticks of the part

putPercent:

    mov ecx, 1000

    mul ecx

    div dword[totalDelta] ;; Tenths of a percent

    xor edx, edx

    mov ecx, 10

    div ecx

    push edx

    call putNumberTracked

    mov esi, top.point

    call putTracked

    pop eax

    call putNumberTracked

    mov esi, top.percent

    call putTracked

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

    reverseConsoleColor

    clearConsoleLine ;; The whole row in the swapped colors

    pop esi

    fputs esi

    call setDefaultColor

    putNewLine

    ret

;;************************************************************************************

VERSION equ "4.5.0"

top.nameColumn   = 6
top.statusColumn = 30
top.parentColumn = 42
top.ttyColumn    = 54
top.memoryColumn = 62
top.cpuColumn    = 72
top.maxSamples   = 64 ;; Processes kept from the first reading

top:

.start:
db "top version ", VERSION, 10, 0
.memoryDescription:
db "Total (MB) | User memory used (bytes) | Kernel memory (bytes) | Total used (bytes, kernel+user)", 0
.header:
db "PID   NAME                    STATUS      PARENT      TTY     MEMORY    CPU", 0
.use:
db "Usage: top", 10, 10
db "Displays processes loaded on the system.", 10, 10
db "Kernel processes are displayed in this list.", 10, 10
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
.tty:
db "tty", 0
.cpuLabel:
db "CPU: ", 0
.cpuUser:
db " user, ", 0
.cpuSystem:
db " system, ", 0
.cpuIdle:
db " idle", 0
.memoryLabel:
db "Mem: ", 0
.memoryWired:
db " kB wired, ", 0
.memoryProcesses:
db " kB processes, ", 0
.memoryFree:
db " kB free", 0
.point:
db ".", 0
.percent:
db "%", 0
.kbytesSuffix:
db " kB", 0
.gap: ;; Fallback when a name already ran past the target column
db " ", 0
.mallocError:
db 10, "Failed to allocate a buffer for the process listing.", 0

;;************************************************************************************

processRecordSize: dd 0 ;; Read from the hx.getProcesses response itself

recordsPointer: dd ?
remainingCount: dd 0
currentProcess: dd ' '
column:         dd 0 ;; Of the line being printed, as putTracked counts it
numberBuffer:   times 12 db 0
parameters:     dd ?

processesBuffer:     dd 0

cpuBefore:   times hx.sysctl.cpuTime.size db 0
cpuAfter:    times hx.sysctl.cpuTime.size db 0
userDelta:   dd 0
systemDelta: dd 0
idleDelta:   dd 0
totalDelta:  dd 0
firstCount:  dd 0
firstTicks:  times top.maxSamples * 2 dd 0 ;; PID and ticks of each
vmStats:     times hx.sysctl.vmStats.size db 0
processesBufferSize: dd ?