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

headerHAPP HAPP.Architectures.i386, 1, 8, applicationStart, 01h, HAPP.bss.none

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"
include "shell.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi
    mov esi, edi

    cmp byte[esi], 0
    je argumentRequired

    mov edi, sudo.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, sudo.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    hx.syscall hx.getUser ;; EBX = real user id, the identity sudoers checks

    mov [realUserId], ebx

    call checkSudoers

    jc notAuthorized

;; Split the command line into the target program name and its own
;; arguments, at the first space. sudo never touches its own identity:
;; being setuid already made it root on exec, and the target inherits
;; that the same way any other child process inherits its parent's identity

    mov esi, [parameters]
    mov edi, esi

.findSpace:

    mov al, byte[edi]

    cmp al, 0
    je .noArgs

    cmp al, ' '
    je .hasArgs

    inc edi

    jmp .findSpace

.hasArgs:

    mov byte[edi], 0

    inc edi

    mov [argsPointer], edi
    mov dword[hasArguments], 1

    jmp .resolveAndExec

.noArgs:

    mov dword[argsPointer], 0
    mov dword[hasArguments], 0

.resolveAndExec:

    call Shell.resolveCommandPath

    mov edi, dword[argsPointer]
    mov eax, dword[hasArguments]

    hx.syscall hx.exec

    jc execFailed

    jmp finish

;;************************************************************************************

;; Reads /etc/sudoers, one numeric user id per line (blank lines and
;; lines starting with '#' ignored), and checks whether [realUserId]
;; appears in it. Root is always authorized, without needing an entry.
;; A missing /etc/sudoers authorizes nobody
;;
;; Output:
;;
;; CF set if not authorized

checkSudoers:

    cmp dword[realUserId], 0
    je .rootAuthorized

    mov dword[authorized], 0
    mov ebx, sudo.sudoersBufferSize

    call malloc

    cmp eax, 0

    je .denied ;; Can't allocate the buffer, fail closed

    mov [sudoersBuffer], ebx
    mov esi, sudo.sudoersPath
    mov edi, ebx

    xor ecx, ecx

    hx.syscall hx.open

    jc .noSudoersFile

    mov esi, ebx

.lineLoop:

    mov edi, sudo.lineBuffer

.copyChar:

    lodsb

    cmp al, 0
    je .lastLine

    cmp al, 10
    je .lineComplete

;; /etc/sudoers may carry CRLF line endings, so the CR is skipped outright instead of copied

    cmp al, 13
    je .copyChar

    mov byte[edi], al

    inc edi

    cmp edi, sudo.lineBuffer + sudo.lineBufferSize - 1
    jae .lineComplete ;; Line too long for the buffer, process what fits

    jmp .copyChar

.lineComplete:

    mov byte[edi], 0

    push esi

    call .checkLine

    pop esi

    jmp .lineLoop

.lastLine:

    mov byte[edi], 0

    call .checkLine

.noSudoersFile:

    mov ebx, [sudoersBuffer]
    mov ecx, sudo.sudoersBufferSize

    call free

    cmp dword[authorized], 0
    je .denied

.rootAuthorized:

    clc

    ret

.denied:

    stc

    ret

;; Parses one NUL terminated /etc/sudoers line

.checkLine:

    mov esi, sudo.lineBuffer

    call trimString

    cmp byte[esi], 0
    je .checkLineDone

    cmp byte[esi], '#'
    je .checkLineDone

    call stringToInteger

    jc .checkLineDone ;; Not a valid number, ignore the line

    cmp eax, [realUserId]
    jne .checkLineDone

    mov dword[authorized], 1

.checkLineDone:

    ret

;;************************************************************************************

notAuthorized:

    fputs sudo.notAuthorized

    jmp finish

;;************************************************************************************

execFailed:

    fputs sudo.execFailed

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

applicationUsage:

    fputs sudo.use

    jmp finish

;;************************************************************************************

argumentRequired:

    fputs sudo.argumentRequired

    jmp finish


;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.1.0"

sudo:

.use:
db 10, "Usage: sudo <command> [arguments]", 10, 10
db "Runs a command as root, if the real user running sudo is listed in /etc/sudoers.", 10, 10
db "sudo version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.notAuthorized:
db 10, "sudo: the real user running this is not listed in /etc/sudoers.", 0
.execFailed:
db 10, "sudo: the requested command could not be found or executed.", 0
.sudoersPath:
db "/etc/sudoers", 0
.argumentRequired:
db 10, "An argument ir required. Use --help for more information.", 0

sudo.sudoersBufferSize = 4 * 1024
sudo.lineBufferSize    = 128

parameters:   dd 0
realUserId:   dd ?
authorized:   dd ?
argsPointer:  dd ?
hasArguments: dd ?

sudoersBuffer: dd ?

sudo.lineBuffer:
times sudo.lineBufferSize db 0
