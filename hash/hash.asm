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
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, shellStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "errors.s"

;;************************************************************************************

shellStart:

    mov [commandLine], edi

    mov edi, hash.helpParameter
    mov esi, [commandLine]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, hash.helpParameter2
    mov esi, [commandLine]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [commandLine]

    cmp byte[esi], 0
    je .start

.start:

;; Start terminal configuration

    putNewLine

    hx.syscall hx.getConsoleInfo

    mov byte[numberColumns], bl
    mov byte[numberRows], bh

    hx.syscall hx.getCursor

    dec dh

    hx.syscall hx.setCursor

    putNewLine

.processRC:

    mov esi, hash.fileRC

    hx.syscall hx.fileExists

    jc .continue

    jmp .processShellFile

.processShellFile:

    mov esi, hash.fileRC
    mov edi, appFileBuffer

    hx.syscall hx.open

    putNewLine

    fputs appFileBuffer

    jmp .continue

.continue:

.startSession:

    hx.syscall hx.getUser

    cmp eax, 555
    je .commonUser

    cmp eax, 777
    je .rootUser

.commonUser:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, hash.commonUser

    hx.syscall hx.stringSize

    push eax

    mov edi, hash.promptSymbol
    mov esi, hash.commonUser

    pop ecx

    rep movsb

    pop es

    jmp .finishPrompt

.rootUser:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, hash.rootUser

    hx.syscall hx.stringSize

    push eax

    mov edi, hash.promptSymbol
    mov esi, hash.rootUser

    pop ecx

    rep movsb

    pop es

    jmp .finishPrompt

;;************************************************************************************

.finishPrompt:

    mov esi, hash.promptSymbol

    hx.syscall hx.stringSize

    inc eax

    mov byte[hash.promptSymbol+eax], 0

;;************************************************************************************

.getCommandLine:

    clc

    putNewLine

    hx.syscall hx.getCursor

    hx.syscall hx.setCursor

    fputs hash.promptSymbol

    mov al, byte[numberColumns] ;; Maximum characters to get

    sub al, 20

    hx.syscall hx.getString

    hx.syscall hx.trimString ;; Remove extra spaces

    cmp byte[esi], 0 ;; No command entered
    je .getCommandLine

;; Compare with available internal commands

    ;; EXIT command

    mov edi, commands.exit

    hx.syscall hx.compareWordsString

    jc finishShell

    ;; RC command

    mov edi, commands.rc

    hx.syscall hx.compareWordsString

    jc runShellScript ;; Start batch file execution

;; Try to load an image

    call getArguments ;; Separate command and arguments

.entryPointLoadImage:

    push esi
    push edi

    jmp .loadImage

.executionFailure:

;; Now the error sent by the system will be analyzed, so that the shell
;; knows its nature

    cmp eax, Hexagon.processesLimit ;; Limit of running processes reached
    je .limitReached                 ;; If yes, display the appropriate message

    cmp eax, Hexagon.invalidImage
    je .invalidHAPPImage

    push esi

    putNewLine

    pop esi

    printString

    fputs hash.commandNotFound

    jmp .getCommandLine

.limitReached:

    putNewLine

    fputs hash.processLimit

    clc

    jmp .getCommandLine

.invalidHAPPImage:

    push esi

    putNewLine

    pop esi

    printString

    fputs hash.invalidImage

    clc

    jmp .getCommandLine

.loadImage:

    pop edi

    mov esi, edi

    hx.syscall hx.trimString

    pop esi

    mov eax, edi

    stc

    hx.syscall hx.exec

    jc .executionFailure

    jmp .getCommandLine

;;************************************************************************************

;; Other auxiliary functions

runShellScript:

    add esi, 02h

    hx.syscall hx.trimString

    cmp byte[esi], 0
    je .argumentRequired

    mov word[hash.positionBX], 0FFFFh ;; With each execution, reset the counter

    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .shellScriptNotFound

    call searchCommands

    jc .notFound

.loadImage:

    mov esi, hash.diskImage

    hx.syscall hx.fileExists

    jc .nextCommand

    mov eax, 0 ;; Do not pass arguments
    mov esi, hash.diskImage ;; Filename

    stc

    hx.syscall hx.exec ;; Request execution of the first command

    jnc .nextCommand

.nextCommand:

    clc

    call searchCommands

    jmp .loadImage

.notFound: ;; The service could not be find

    jmp shellStart.getCommandLine

.shellScriptNotFound:

    fputs hash.shellScriptNotFound

    jmp shellStart.getCommandLine

.argumentRequired:

    fputs hash.argumentRequired

    jmp shellStart.getCommandLine

;;************************************************************************************

;; Components for shell batch command execution

searchCommands:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov si, appFileBuffer ;; Points to the buffer with the file contents
    mov bx, word[hash.positionBX]

    jmp .searchBetweenDelimiters

.searchBetweenDelimiters:

    inc bx

    mov word[hash.positionBX], bx

    cmp bx, searchSizeLimit
    je shellStart.getCommandLine

    mov al, [ds:si+bx]

    cmp al, '>'
    jne .searchBetweenDelimiters ;; The initial delimiter has been found

;; BX now points to the first character of the command name retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, hash.diskImage ;; The command name will be copied to ES:DI

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getCommandLine:

    inc bx

    cmp bx, 13
    je .invalidCommandName ;; If file name greater than 11, the name is invalid

    mov al, [ds:si+bx]

;; Now let's look for the final limiters of a command name, which could be:
;;
;; EOL - new line (10)
;; Space - a space after the last character
;; # - If used after the last character of the service name, mark as a comment

    cmp al, 10 ;; If another delimiter is found, the name was loaded successfully
    je .commandNameObtained

    cmp al, ' ' ;; If another delimiter is found, the name was loaded successfully
    je .commandNameObtained

    cmp al, '#' ;; If another delimiter is found, the name was loaded successfully
    je .commandNameObtained

;; If not ready, store the obtained character

    stosb

    jmp .getCommandLine

.commandNameObtained:

    pop es

    popa

    ret

.invalidCommandName:

    pop es

    popa

    stc

    ret

;;************************************************************************************

;; Separate command name and arguments
;;
;; Input:
;;
;; ESI - Command address
;;
;; Output:
;;
;; ESI - Command address
;; EDI - Command arguments
;; CF - Set in case of lack of extension

getArguments:

    push esi

.loop:

    lodsb ;; mov AL, byte[ESI] & inc ESI

    cmp al, 0
    je .notFound

    cmp al, ' '
    je .spaceFound

    jmp .loop

.notFound:

    pop esi

    mov edi, 0

    stc

    jmp .end

.spaceFound:

    mov byte[esi-1], 0
    mov ebx, esi

    hx.syscall hx.stringSize

    mov ecx, eax

    inc ecx ;; Including the last character (NULL)

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, ebx
    mov edi, appFileBuffer

    rep movsb ;; Copy (ECX) string characters from ESI to EDI

    pop es

    mov edi, appFileBuffer

    pop esi

    clc

.end:

    ret

;;************************************************************************************

applicationUsage:

    fputs hash.use

    jmp finishShell

;;************************************************************************************

finishShell:

    mov ebx, 00h

    hx.syscall hx.exit

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

;; TODO: improve shell scripting support

VERSION equ "0.11.1"

searchSizeLimit = 32768

hash:

.commandNotFound:
db ": command not found.", 0
.fileRC:
db "shrc", 0
.invalidImage:
db ": unable to load image. Unsupported executable format.", 0
.processLimit:
db "There is no available process slot to run the requested application.", 10
db "First try to terminate applications or their instances, and try again.", 0
.dot:
db ".", 0
.commonUser:
db "$ ", 0
.rootUser:
db "# ", 0
.use:
db 10, 10, "Usage: hash", 10, 10
db "Start a Unix shell for the current user.", 10, 10
db "hash version ", VERSION, 10, 10
db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.shellScriptNotFound:
db 10, "Shell script not found.", 0
.argumentRequired:
db 10, "An argument is necessary.", 0

.positionBX: dw 0 ;; Marking the search position in the file content

.diskImage: ;; Stores the name of the image to be used
times 12 db 0
.promptSymbol: ;; Stores # or $
times 8  db 0

;;**************************

commands:

.exit:
db "exit", 0
.rc:
db "rc", 0

;;**************************

numberColumns: db 0 ;; Total columns available in the video at the current resolution
numberRows:    db 0 ;; Total rows available in the video at the current resolution
commandLine:   dd 0

;;************************************************************************************

appFileBuffer: ;; Address for opening files
