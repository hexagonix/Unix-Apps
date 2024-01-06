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

;;************************************************************************************
;;
;;                       Utilitário Unix init para Hexagonix
;;
;;                 Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
;;                          Todos os direitos reservados.
;;
;;************************************************************************************

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, initHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"
include "log.s"
include "dev.s"

;;************************************************************************************

VERSION equ "2.8.0"

searchSizeLimit = 32768 ;; Maximum file size: 32 kbytes

defaultShell: ;; Name of the file containing the default Unix shell
db "sh", 0
rcFile: ;; init configuration file name
db "rc", 0
tryDefaultShell: ;; Signals an attempt to load the default shell
db 0
positionBX: ;; Marking the search position in the file content
dw 0
hexagonixService: ;; Stores the name of the shell to be used by the system
times 12 db 0

init:

.startInit:
db "init version ", VERSION, ".", 0
.startingSystem:
db "The system is coming up. Please wait.", 0
.systemReady:
db "The system is ready.", 0
.searchFile:
db "Looking for /rc...", 0
.fileFound:
db "Configuration file (/rc) found.", 0
.fileNotFound:
db "Configuration file (/rc) not found. The default shell will be executed (sh).", 0
.generalError:
db "An unhandled error was encountered.", 0
.registeringComponents:
db "Starting service...", 0
.setupConsole:
db "Setting up consoles (tty0, tty1)...", 0

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

    hx.syscall hx.lock ;; Prevents the user from killing the login process with a special key

;; Now init will check the existence of the rc configuration file.
;; If this file is present, init will look for the declaration of an image to be used with the
;; system, as well as Hexagonix configuration declarations.
;; If this file is not found, init will load the default shell. The default is the Hexagonix login
;; utility.

    systemLog init.searchFile, 0, Log.Priorities.p4

    mov word[positionBX], 0FFFFh ;; Starts at position -1, so you can find the delimiters

    call findConfigurationFile

    systemLog init.systemReady, 0, Log.Priorities.p5

.loadService:

    systemLog init.registeringComponents, 0, Log.Priorities.p4

    mov esi, hexagonixService

    hx.syscall hx.fileExists

    jc .nextService

    mov eax, 0 ;; Do not pass arguments
    mov esi, hexagonixService ;; Service name

    stc

    hx.syscall hx.exec ;; Request loading of the service

    jnc .nextService

.nextService:

    clc

    call findConfigurationFile

    jmp .loadService

.serviceNotFound: ;; The service could not be located

;; Check if you have already tried to load the default Hexagonix shell

    cmp byte[tryDefaultShell], 0
    je .tryDefaultShell          ;; If not, try loading the default Hexagonix shell

    hx.syscall hx.exit ;; If yes, the default shell cannot be run either

.tryDefaultShell: ;; Try loading the default Hexagonix shell

    call findDefaultShell ;; Configure Hexagonix default shell name

    mov byte[tryDefaultShell], 1 ;; Try loading the default Hexagonix shell

    hx.syscall hx.unlock ;; The shell can be terminated using a special key

    jmp .loadService ;; Try loading the default Hexagonix shell

;;************************************************************************************

clearConsole:

    systemLog init.setupConsole, 0, Log.Priorities.p5

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open the first virtual console

    hx.syscall hx.open ;; Open the device

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopen the default console

    hx.syscall hx.open ;; Open the device

    ret

;;************************************************************************************

findConfigurationFile:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, rcFile
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .rcFileNotFound

    mov si, appFileBuffer ;; Points to the buffer with the file contents
    mov bx, word[positionBX]

    jmp .searchBetweenDelimiters

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

;; If nothing is found within the size limit, cancel the search

    cmp bx, searchSizeLimit
    je startProcessing.tryDefaultShell

    mov al, [ds:si+bx]

    cmp al, ':'
    jne .searchBetweenDelimiters ;; The initial delimiter has been found

;; BX now points to the first character of the shell name retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, hexagonixService ;; The shell name will be copied to ES:DI - hexagonixService

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getServiceName:

    inc bx

    cmp bx, 13
    je .invalidServiceName ;; If file name greater than 11, the name is invalid

    mov al, [ds:si+bx]

;; Now let's look for the final delimiters of a service name, which could be:
;;
;; EOL - new line (10)
;; Space - a space after the last character
;; # - If used after the last character of the service name, mark as a comment

    cmp al, 10 ;; If another delimiter is found, the name was loaded successfully
    je .serviceNameObtained

    cmp al, ' ' ;; If another delimiter is found, the name was loaded successfully
    je .serviceNameObtained

    cmp al, '#' ;; If another delimiter is found, the name was loaded successfully
    je .serviceNameObtained

;; If not ready, store the obtained character

    stosb

    jmp .getServiceName

.serviceNameObtained:

    pop es

    popa

    systemLog init.fileFound, 0, Log.Priorities.p4

    ret

.invalidServiceName:

    pop es

    popa

    jmp findDefaultShell


.rcFileNotFound:

    pop es

    popa

    systemLog init.fileNotFound, 0, Log.Priorities.p4

    jmp findDefaultShell

;;************************************************************************************

findDefaultShell:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, hexagonixService

    hx.syscall hx.stringSize

    push eax

    mov edi, hexagonixService
    mov esi, ' '

    pop ecx

    rep movsb

    pop es

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, defaultShell

    hx.syscall hx.stringSize

    push eax

    mov edi, hexagonixService
    mov esi, defaultShell

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

appFileBuffer: ;; Location where the configuration file will be opened
