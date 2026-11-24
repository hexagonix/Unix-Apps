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

;;************************************************************************************
;;
;;                     Unix utility script for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************


use32

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Architecture | Version | Subversion | Entry point | Image type | BSS size
headerHAPP HAPP.Architectures.i386, 1, 8, applicationStart, 01h, HAPP.bss.none

;;************************************************************************************

include "hexagon.s"
include "tty.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"

;;************************************************************************************

;; Two instances share the work, as the script of BSD did with fork. The first
;; starts the shell and copies the keyboard to the manager. The second copies the
;; manager to the screen and the file, and ends the session with the shell

applicationStart:

    push ds
    pop es

    mov [parameters], edi

    mov edi, script.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, script.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov esi, [parameters]

    call isRelay

    jnc relayStart

    mov esi, [parameters]

    call trimString

    cmp byte[esi], 0

    jne .fileGiven

    mov esi, script.defaultFile

.fileGiven:

    mov [fileName], esi

;; The file is created now, so a name that cannot be written fails before the
;; session instead of after it

    mov esi, [fileName]

    hx.syscall hx.unlink

    mov esi, [fileName]

    hx.syscall hx.touch

    jc cannotCreate

    call openPair

    jc noFreePair

;; The shell's window is the terminal script runs on

    ttyGetSize

    mov ecx, eax
    mov edx, ebx
    mov eax, [managerFD]
    mov ebx, 7

    hx.syscall hx.ioctl

    fputs script.started
    fputs [fileName]

    putNewLine

    call startShell

    jc shellFailed

    ttyGetMode

    mov [savedMode], eax

    call startRelay

    jc relayFailed

;; Every key as it comes, unseen and with no Ctrl+C of its own, so the line,
;; the echo and Ctrl+C are the subsidiary's to handle

    ttySetMode 0

.forward:

    mov eax, 0
    mov edi, keyBuffer
    mov ecx, keyBuffer.size

    hx.syscall hx.read

    jc .readFailed

    cmp eax, 0

    je .forward

    mov ecx, eax
    mov eax, [managerFD]
    mov esi, keyBuffer

    hx.syscall hx.write

    jmp .forward

.readFailed:

    ttySetMode [savedMode]

    jmp finish

;;************************************************************************************

;; Opens the first free pair, its manager and then its subsidiary
;;
;; Output:
;;
;; CF set if every pair is in use

openPair:

    mov byte[pairDigit], '0'

.tryPair:

    mov al, byte[pairDigit]

    mov byte[script.manager + 4], al
    mov byte[script.subsidiary + 4], al

    mov esi, script.manager

    xor ecx, ecx

    hx.syscall hx.open

    jnc .managerOpened

    inc byte[pairDigit]

    cmp byte[pairDigit], '3'

    jbe .tryPair

    stc

    ret

.managerOpened:

    mov [managerFD], eax

    mov esi, script.subsidiary

    xor ecx, ecx

    hx.syscall hx.open

    jc .noSubsidiary

    mov [subsidiaryFD], eax

    clc

    ret

.noSubsidiary:

    mov eax, [managerFD]

    hx.syscall hx.close

    stc

    ret

;;************************************************************************************

;; Starts the shell with 0, 1 and 2 on the subsidiary. They are pointed there
;; only for the spawn, which copies them into the shell, and then put back. The
;; manager and the terminal's copy are kept from the shell, so it holds nothing
;; but its terminal, and ends the session's input once script is gone
;;
;; Output:
;;
;; CF set if the shell could not be started

startShell:

    mov eax, 0
    mov ebx, script.savedFD

    hx.syscall hx.dup2

    jc .failed

    xor ebx, ebx

.toSubsidiary:

    push ebx

    mov eax, [subsidiaryFD]

    hx.syscall hx.dup2

    pop ebx

    inc ebx

    cmp ebx, 3

    jb .toSubsidiary

    mov eax, [subsidiaryFD]

    hx.syscall hx.close

    hx.setCloseOnSpawn script.savedFD, 1
    hx.setCloseOnSpawn [managerFD], 1

    mov esi, script.shell
    xor eax, eax

    hx.syscall hx.spawn

    mov [shellPID], eax

    setc byte[shellFailedFlag]

    hx.setCloseOnSpawn [managerFD], 0 ;; The second instance needs it

    xor ebx, ebx

.toTerminal:

    push ebx

    mov eax, script.savedFD

    hx.syscall hx.dup2

    pop ebx

    inc ebx

    cmp ebx, 3

    jb .toTerminal

    mov eax, script.savedFD

    hx.syscall hx.close

    cmp byte[shellFailedFlag], 0

    jne .failed

    clc

    ret

.failed:

    stc

    ret

;;************************************************************************************

;; Starts the second instance, which inherits the manager under the same
;; descriptor, with what it needs to end the session
;;
;; Output:
;;
;; CF set if it could not be started

startRelay:

    mov edi, relayArguments
    mov esi, script.relayParameter

    call appendString

    mov eax, [managerFD]

    call appendNumber

    hx.syscall hx.pid

    call appendNumber

    mov eax, [savedMode]

    call appendNumber

    mov esi, [fileName]

    call appendString

    mov byte[edi], 0

    mov esi, script.self
    mov edi, relayArguments
    mov eax, 1

    hx.syscall hx.spawn

    ret

;;************************************************************************************

;; The second instance. Its arguments are the manager's descriptor, the PID of
;; the first instance, the mode of the terminal to put back and the file

relayStart:

    call readNumber

    mov [managerFD], eax

    call readNumber

    mov [callerPID], eax

    call readNumber

    mov [savedMode], eax

    call trimString

    mov [fileName], esi

    mov ebx, script.recordStart

    call malloc

    cmp eax, 0

    je .relay ;; The session still runs, only unrecorded

    mov [recordBuffer], ebx
    mov dword[recordSize], script.recordStart

.relay:

    mov eax, [managerFD]
    mov edi, outputBuffer
    mov ecx, outputBuffer.size

    hx.syscall hx.read

    jc .ended

    cmp eax, 0

    je .ended ;; The shell and every subsidiary descriptor are gone

    mov [outputCount], eax

    mov ecx, eax
    mov eax, 1
    mov esi, outputBuffer

    hx.syscall hx.write

    call record

    jmp .relay

.ended:

    ttySetMode [savedMode]

    cmp dword[recordUsed], 0

    je .saved

    mov esi, [fileName]

    hx.syscall hx.unlink

    mov esi, [fileName]
    mov edi, [recordBuffer]
    mov eax, [recordUsed]

    hx.syscall hx.create

    jnc .saved

    fputs script.notSaved

.saved:

    cmp byte[recordLost], 0

    je .done

    fputs script.recordFull

.done:

    fputs script.finished
    fputs [fileName]

    putNewLine

;; The first instance waits on the keyboard and never sees the end by itself

    mov ebx, [callerPID]

    hx.syscall hx.kill

    jmp finish

;;************************************************************************************

;; Keeps a copy of what was just shown, doubling the buffer when it fills. Once
;; there is no memory for a bigger one, what was kept so far stays and the rest
;; goes unrecorded

record:

    cmp dword[recordBuffer], 0

    je .end

    cmp byte[recordLost], 0

    jne .end

    mov eax, [recordUsed]
    add eax, [outputCount]

    cmp eax, [recordSize]

    jbe .copy

    mov ebx, [recordSize]
    shl ebx, 1

    cmp ebx, eax

    jae .grow

    mov ebx, eax

.grow:

    mov [newSize], ebx

    call malloc

    cmp eax, 0

    je .lost

    push ebx

    mov edi, ebx
    mov esi, [recordBuffer]
    mov ecx, [recordUsed]

    cld

    rep movsb

    mov ebx, [recordBuffer]

    call free

    pop ebx

    mov [recordBuffer], ebx

    mov eax, [newSize]
    mov [recordSize], eax

.copy:

    mov edi, [recordBuffer]
    add edi, [recordUsed]
    mov esi, outputBuffer
    mov ecx, [outputCount]

    cld

    rep movsb

    mov eax, [outputCount]
    add [recordUsed], eax

.end:

    ret

.lost:

    mov byte[recordLost], 1

    ret

;;************************************************************************************

;; Output: CF clear if ESI starts with the relay argument, and ESI past it

isRelay:

    mov edi, script.relayParameter

.compare:

    mov al, byte[edi]

    cmp al, 0

    je .found

    cmp al, byte[esi]

    jne .notFound

    inc esi
    inc edi

    jmp .compare

.found:

    clc

    ret

.notFound:

    stc

    ret

;; Input: ESI - Text. Output: EAX - The number at its start, ESI past it and its space

readNumber:

    xor eax, eax

.nextDigit:

    movzx ebx, byte[esi]

    sub ebx, '0'

    cmp ebx, 9

    ja .end

    imul eax, eax, 10
    add eax, ebx

    inc esi

    jmp .nextDigit

.end:

    cmp byte[esi], ' '

    jne .done

    inc esi

.done:

    ret

;; Input: ESI - NUL terminated text, EDI - Where it goes. Output: EDI past it

appendString:

    mov al, byte[esi]

    cmp al, 0

    je .end

    mov byte[edi], al

    inc esi
    inc edi

    jmp appendString

.end:

    ret

;; Input: EAX - Number, EDI - Where it goes. Output: EDI past it and a space

appendNumber:

    push edi

    mov edi, numberBuffer

    call integetToString

    pop edi

    mov esi, numberBuffer

    call appendString

    mov byte[edi], ' '

    inc edi

    ret

;;************************************************************************************

cannotCreate:

    fputs script.cannotCreate
    fputs [fileName]

    jmp finish

noFreePair:

    fputs script.noFreePair

    jmp finish

shellFailed:

    fputs script.shellFailed

    jmp finish

;; With no second instance there is no session, so the shell goes too

relayFailed:

    mov ebx, [shellPID]

    hx.syscall hx.kill

    fputs script.relayFailed

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs script.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.1.0"

script:

.use:
db 10, "Usage: script [file]", 10, 10
db "Starts a shell on a pseudoterminal and records everything it shows into", 10
db "file, ", 22h, "script.out", 22h, " by default. The recording ends when the shell exits.", 10, 10
db "script version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.relayParameter:
db "--relay ", 0
.defaultFile:
db "script.out", 0
.shell:
db "/bin/sh", 0
.self:
db "/bin/script", 0
.manager:
db "ptyp0", 0
.subsidiary:
db "ttyp0", 0
.started:
db 10, "Script started, output file is ", 0
.finished:
db 10, "Script done, output file is ", 0
.cannotCreate:
db 10, "script: cannot create ", 0
.noFreePair:
db 10, "script: no pseudoterminal is free.", 0
.shellFailed:
db 10, "script: could not start the shell.", 0
.relayFailed:
db 10, "script: could not start its second instance.", 0
.notSaved:
db 10, "script: the recording could not be saved.", 0
.recordFull:
db 10, "script: out of memory, the end of the session was not recorded.", 0

script.savedFD     = 7 ;; The terminal's copy while 0, 1 and 2 are lent to the shell
script.recordStart = 4096

keyBuffer:    times 64 db 0
keyBuffer.size = 64
outputBuffer: times 256 db 0
outputBuffer.size = 256

relayArguments: times 128 db 0
numberBuffer:   times 12 db 0

parameters:      dd ?
fileName:        dd 0
managerFD:       dd 0
subsidiaryFD:    dd 0
shellPID:        dd 0
callerPID:       dd 0
savedMode:       dd 0
pairDigit:       db 0
shellFailedFlag: db 0

recordBuffer: dd 0
recordSize:   dd 0
recordUsed:   dd 0
outputCount:  dd 0
newSize:      dd 0
recordLost:   db 0

;;************************************************************************************
