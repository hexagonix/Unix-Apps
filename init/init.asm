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

;;************************************************************************************
;;
;;                       Unix utility init for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 5, initHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"
include "log.s"
include "dev.s"

;;************************************************************************************

VERSION equ "3.0.0"

searchSizeLimit = 32768 ;; Maximum /rc size read while parsing: 32 kbytes

lineBufferSize = 64 ;; Big enough for "respawn=" plus a 12 character name

respawnTable.limit = 8 ;; How many respawn= services init can supervise at once

defaultShell: ;; Name of the file containing the default Unix shell
db "sh", 0
rcFile: ;; init configuration file name
db "rc", 0

keyStart:
db "start", 0
keySpawn:
db "spawn", 0
keyRespawn:
db "respawn", 0

init:

.startInit:
db "init version ", VERSION, ".", 0
.startingSystem:
db "The system is coming up. Please wait.", 0
.searchFile:
db "Looking for /rc...", 0
.fileFound:
db "Configuration file (/rc) found.", 0
.fileNotFound:
db "Configuration file (/rc) not found. The default shell will be executed (sh).", 0
.setupConsole:
db "Setting up consoles (tty0, tty1)...", 0
.willStart:
db "Process will be started and will block until it exits (start):", 0
.startFailed:
db "Process failed to start (start):", 0
.spawnOK:
db "Process started successfully (spawn), not monitored:", 0
.spawnFailed:
db "Process failed to start (spawn):", 0
.respawnOK:
db "Process started and is being monitored (respawn):", 0
.respawnFailed:
db "Process failed to start (respawn):", 0

;;************************************************************************************

initHexagonix: ;; Entry point

;; First, we must check the PID of the process. By default, init should only be run directly by
;; Hexagon. If the PID is different from 1, init must be terminated.
;; If 1, continue with the Hexagonix user environment initialization process

    hx.syscall hx.pid

    cmp eax, 01h
    je .configureConsole ;; Is PID 1? Proceed

    hx.syscall hx.exit ;; It is not? Finish now

;; Configure the Hexagonix terminal

.configureConsole:

    systemLog init.startInit, 0, Log.Priorities.p5
    systemLog init.startingSystem, 0, Log.Priorities.p5

;; Now the double buffering memory buffer must be cleared.
;; This prevents polluted memory from being used as the basis for display when an application is
;; forcefully closed.
;; In this situation, the system updates the memory buffer, updating the console with its content.
;; This step can also be performed by the session manager later.

    call clearConsole

;; Hexagonix configuration routines can be added here

startProcessing:

    hx.syscall hx.lock ;; Prevents the user from killing the current foreground process with a special key

;; Read /rc line by line. Each recognized "key=value" line either blocks
;; (start=), fires and forgets (spawn=), or fires and gets supervised from
;; then on (respawn=). Once the whole file has been processed, init falls
;; into monitorLoop and never returns

    systemLog init.searchFile, 0, Log.Priorities.p4

    mov esi, rcFile
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .rcNotFound

    systemLog init.fileFound, 0, Log.Priorities.p4

    call parseConfig

    jmp monitorLoop

.rcNotFound:

;; No /rc at all. Fall back to supervising the default shell directly, the
;; same way a lone "respawn=sh" line would

    systemLog init.fileNotFound, 0, Log.Priorities.p4

    mov esi, defaultShell

    hx.syscall hx.spawn

    jc monitorLoop ;; Nothing could be started at all, just idle

    call registerRespawn

    jmp monitorLoop

;;************************************************************************************

clearConsole:

    systemLog init.setupConsole, 0, Log.Priorities.p5

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open the first virtual console

    hx.syscall hx.open ;; Open the device

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopen the default console

    hx.syscall hx.open ;; Open the device

    ret

;;************************************************************************************

;; Walks appFileBuffer (already opened by initHexagonix) one line at a time,
;; up to searchSizeLimit bytes, handing each line to processLine

parseConfig:

    mov esi, appFileBuffer

    mov dword[rcPosition], 0

.lineLoop:

    mov edi, lineBuffer

.copyChar:

    lodsb

    inc dword[rcPosition]

    cmp dword[rcPosition], searchSizeLimit
    jae .done

    cmp al, 0
    je .lastLine

    cmp al, 10
    je .lineComplete

;; Skip CR outright rather than copying it. /rc is generated by configure.sh
;; from rc.conf via "echo -e", which produces real CRLF line endings, and
;; hx.trimString only strips spaces, not carriage returns

    cmp al, 13
    je .copyChar

    mov byte[edi], al

    inc edi

    cmp edi, lineBuffer+lineBufferSize - 1
    jae .lineComplete ;; Line too long for the buffer, process what fits

    jmp .copyChar

.lineComplete:

    mov byte[edi], 0

    push esi ;; processLine uses ESI internally (trimString, compareWordsString,
             ;; systemLog, ...) and never restores our read position in
             ;; appFileBuffer, so it has to be saved across the call

    call processLine

    pop esi

    jmp .lineLoop

.lastLine: ;; End of the file, possibly without a trailing newline

    mov byte[edi], 0

    call processLine

.done:

    ret

;;************************************************************************************

;; Logs a static prefix followed by the current process name (dword[valuePtr])
;; as a single line. systemLog always ends its own output with a newline, so
;; logging the prefix and the name as two separate calls would print them as
;; two separate lines instead of one. This function builds them into one buffer first
;;
;; Input:
;;
;; ESI - Prefix message (NUL terminated)

logWithName:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov edi, logBuffer

.copyPrefix:

    lodsb

    cmp al, 0
    je .addSpace

    stosb

    jmp .copyPrefix

.addSpace:

    mov al, ' '

    stosb

    mov esi, dword[valuePtr]

.copyName:

    lodsb

    stosb

    cmp al, 0
    jne .copyName

    pop es

    systemLog logBuffer, 0, Log.Priorities.p4

    ret

;;************************************************************************************

;; Parses one NUL terminated line from lineBuffer and dispatches it. Blank
;; lines, lines starting with '#', and lines without a real "key=value"
;; shape are silently ignored

processLine:

    mov esi, lineBuffer

    hx.syscall hx.trimString

    cmp byte[esi], 0
    je .ignore

    cmp byte[esi], '#'
    je .ignore

    mov dword[keyPtr], esi

.findEquals:

    lodsb

    cmp al, 0
    je .ignore ;; No '=' on this line, nothing to do with it

    cmp al, '='
    jne .findEquals

    mov byte[esi - 1], 0 ;; Split the line in place, terminating the key here

    mov dword[valuePtr], esi

    hx.syscall hx.trimString

    mov dword[valuePtr], esi

    mov esi, dword[keyPtr]
    mov edi, keyStart

    hx.syscall hx.compareWordsString

    jc .doStart

    mov esi, dword[keyPtr]
    mov edi, keyRespawn

    hx.syscall hx.compareWordsString

    jc .doRespawn

    mov esi, dword[keyPtr]
    mov edi, keySpawn

    hx.syscall hx.compareWordsString

    jc .doSpawn

    ret ;; Unknown key, ignore

.doStart:

    mov esi, init.willStart

    call logWithName

    mov esi, dword[valuePtr]

    mov eax, 0

    stc

    hx.syscall hx.exec

    jc .startFailed

    ret

.startFailed:

    mov esi, init.startFailed

    call logWithName

    ret

.doSpawn:

    mov esi, dword[valuePtr]

    hx.syscall hx.spawn

    jc .spawnFailed

    mov esi, init.spawnOK

    call logWithName

    ret

.spawnFailed:

    mov esi, init.spawnFailed

    call logWithName

    ret

.doRespawn:

    mov esi, dword[valuePtr]

    hx.syscall hx.spawn

    jc .respawnFailed

    mov esi, dword[valuePtr]

    call registerRespawn

    mov esi, init.respawnOK

    call logWithName

    ret

.respawnFailed:

    mov esi, init.respawnFailed

    call logWithName

    ret

.ignore:

    ret

;;************************************************************************************

;; Records a newly (re)spawned process for supervision
;;
;; Input:
;;
;; EAX - PID of the process
;; ESI - Name of the service (NUL terminated)

registerRespawn:

    push eax
    push esi

    xor ecx, ecx

.findSlot:

    cmp ecx, respawnTable.limit
    jae .noSlot ;; Table full, this one just won't be supervised

    cmp byte[respawnTable.used+ecx], 0
    je .slotFound

    inc ecx

    jmp .findSlot

.slotFound:

    pop esi
    pop eax

    mov dword[respawnTable.pid+ecx*4], eax

    mov byte[respawnTable.used+ecx], 1

    imul edi, ecx, 13
    add edi, respawnTable.name

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov ecx, 12

.copyName:

    lodsb

    cmp al, 0
    je .namePadded

    stosb

    loop .copyName

.namePadded:

    mov byte[edi], 0

    pop es

    ret

.noSlot:

    pop esi
    pop eax

    ret

;;************************************************************************************

;; Never returns. Once a second, checks every supervised PID against the
;; current process table and relaunches whichever one has disappeared,
;; remembering its new PID

monitorLoop:

    mov ecx, 100 ;; ~1 second, at the kernel's 100 Hz timer rate

    hx.syscall hx.sleep

    hx.syscall hx.getProcesses ;; EAX = record count, ESI = record size (dd) + records

    mov dword[procCount], eax

    mov ecx, dword[esi]
    mov dword[procRecordSize], ecx

    add esi, 4

    mov dword[procRecords], esi

    xor ebx, ebx

.checkSlot:

    cmp ebx, respawnTable.limit
    jae monitorLoop

    cmp byte[respawnTable.used+ebx], 0
    je .nextSlot

    mov eax, dword[respawnTable.pid+ebx*4]

    call isPidAlive

    jnc .nextSlot ;; Still running

;; Gone. Relaunch it and remember the new PID

    push ebx

    imul esi, ebx, 13
    add esi, respawnTable.name

    hx.syscall hx.spawn

    pop ebx

    jc .nextSlot ;; Relaunch failed, try again on the next tick

    mov dword[respawnTable.pid+ebx*4], eax

.nextSlot:

    inc ebx

    jmp .checkSlot

;;************************************************************************************

;; Checks whether a PID is present in the process table snapshot taken by
;; the current monitorLoop tick (procCount/procRecords/procRecordSize)
;;
;; Input:
;;
;; EAX - PID to look for
;;
;; Output:
;;
;; CF - Set if the PID is not present (the process has exited)

isPidAlive:

    push ebx
    push ecx
    push esi

    mov ebx, eax

    mov ecx, dword[procCount]
    mov esi, dword[procRecords]

.scan:

    cmp ecx, 0
    je .notFound

    cmp dword[esi], ebx ;; PID field, at offset 0 of each record

    je .found

    add esi, dword[procRecordSize]

    dec ecx

    jmp .scan

.found:

    pop esi
    pop ecx
    pop ebx

    clc

    ret

.notFound:

    pop esi
    pop ecx
    pop ebx

    stc

    ret

;;************************************************************************************

rcPosition:     dd 0
keyPtr:         dd ?
valuePtr:       dd ?
procCount:      dd 0
procRecordSize: dd 0
procRecords:    dd ?

respawnTable.pid: 
times respawnTable.limit dd 0
respawnTable.used: 
times respawnTable.limit    db 0
respawnTable.name: 
times respawnTable.limit*13 db 0

lineBuffer:
times lineBufferSize db 0

logBuffer: ;; Scratch space for logWithName, prefix + " " + a 12 character name
times 96 db 0

;;************************************************************************************

appFileBuffer: ;; Location where the configuration file will be opened
