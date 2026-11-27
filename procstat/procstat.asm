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
headerHAPP HAPP.Architectures.i386, 1, 10, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"
include "sysctl.s"

;;************************************************************************************

;; The blocks of memory a process holds, as procstat -v in FreeBSD

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    putNewLine

    mov esi, [parameters]

    cmp esi, 0

    je applicationUsage

    cmp byte[esi], 0

    je applicationUsage

    mov edi, procstat.helpParameter

    call compareWordsInString

    jc applicationUsage

    mov edi, procstat.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov esi, [parameters]

    call stringToInteger

    jc applicationUsage

    mov [pid], eax

    mov dword[blocksBufferSize], 512 ;; Arbitrary starting guess

.allocateBuffer:

    mov ebx, dword[blocksBufferSize]

    call malloc

    cmp eax, 0

    je mallocError

    mov dword[blocksBuffer], ebx

    mov esi, ebx
    mov ecx, dword[blocksBufferSize]
    mov edx, [pid]
    mov ebx, hx.sysctl.getProcessBlocks

    hx.syscall hx.sysctl ;; EAX = record count, or the size needed if CF is set

    jnc .haveBlocks

    cmp eax, 0

    je noProcess

;; The buffer was too small, and EAX is the size needed

    push eax

    mov ebx, dword[blocksBuffer]
    mov ecx, dword[blocksBufferSize]

    call free

    pop eax

    mov dword[blocksBufferSize], eax
    mov dword[blocksBuffer], 0

    jmp .allocateBuffer

.haveBlocks:

    mov dword[remainingCount], eax

    mov esi, dword[blocksBuffer]
    mov eax, dword[esi] ;; Record size, read from the message itself
    mov dword[recordSize], eax

    add esi, 4

    mov [recordsPointer], esi

    fputs procstat.header

.blockLoop:

    cmp dword[remainingCount], 0

    je .total

    mov esi, [recordsPointer]
    mov eax, dword[esi + hx.sysctl.block.address]

    printHexadecimal

    gotoColumn procstat.sizeColumn

    mov esi, [recordsPointer]
    mov eax, dword[esi + hx.sysctl.block.size]

    add dword[totalBytes], eax

    printInteger

    gotoColumn procstat.kindColumn

    mov esi, [recordsPointer]
    mov eax, dword[esi + hx.sysctl.block.kind]

    cmp eax, hx.sysctl.blockKinds.heap

    jbe .kindKnown

    xor eax, eax

.kindKnown:

    mov esi, dword[kindNames + eax * 4]

    printString

    putNewLine

    mov eax, dword[recordSize]

    add dword[recordsPointer], eax

    dec dword[remainingCount]

    jmp .blockLoop

.total:

    fputs procstat.total

    mov eax, dword[totalBytes]

    printInteger

    fputs procstat.bytes

    jmp finish

;;************************************************************************************

noProcess:

    fputs procstat.noProcess

    jmp finish

mallocError:

    fputs procstat.mallocError

    jmp finish

applicationUsage:

    fputs procstat.use

    jmp finish

;;************************************************************************************

finish:

    cmp dword[blocksBuffer], 0

    je .noBufferToFree

    mov ebx, dword[blocksBuffer]
    mov ecx, dword[blocksBufferSize]

    call free

.noBufferToFree:

    hx.syscall hx.exit

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "1.0.0"

procstat.sizeColumn = 12
procstat.kindColumn = 24

procstat:

.use:
db "Usage: procstat PID", 10, 10
db "Displays the blocks of memory a process holds, their address in", 10
db "physical memory, their size in bytes and what each one is for.", 10, 10
db "procstat version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.header:
db "ADDRESS     BYTES       KIND", 10, 0
.total:
db "Total: ", 0
.bytes:
db " bytes", 0
.noProcess:
db "procstat: no process with that PID.", 0
.mallocError:
db "procstat: failed to allocate a buffer for the blocks.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.kindUnknown:
db "unknown", 0
.kindImage:
db "image (code, data and stack)", 0
.kindPaging:
db "page tables and kernel stack", 0
.kindArguments:
db "arguments", 0
.kindEnvironment:
db "environment", 0
.kindHeap:
db "heap (hx.malloc)", 0

align 4

kindNames: dd procstat.kindUnknown, procstat.kindImage, procstat.kindPaging, \
              procstat.kindArguments, procstat.kindEnvironment, procstat.kindHeap

parameters:       dd 0
pid:              dd 0
blocksBuffer:     dd 0
blocksBufferSize: dd 0
recordSize:       dd 0
recordsPointer:   dd 0
remainingCount:   dd 0
totalBytes:       dd 0
