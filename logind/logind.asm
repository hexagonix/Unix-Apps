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
;;                          Login daemon for Hexagonix
;;
;;                 Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, daemonStart, 01h


;;************************************************************************************

include "hexagon.s"
include "Estelar/estelar.s"
include "macros.s"
include "log.s"
include "dev.s"
include "verUtils.s"

searchSizeLimit = 32768

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

;;************************************************************************************

VERSION equ "1.13.2"

logind:

match =Modern, LOGIN_STYLE
{

.aboutSystem:
db 10,10
db "  88                                                                                88", 10
db "  88                                                                                ''", 10
db "  88", 10
db "  88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8", 10
db "  88P'    '88 a8P     88  `P8, ,8P'  ''     `P8 a8'    `P88 a8'     '8a 88P'   `'88 88  `P8, ,8P'", 10
db "  88       88 8PP'''''''    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(", 10
db "  88       88 '8b,   ,aa  ,d8' '8b,  88,    ,88 '8a,   ,d88 '8a,   ,a8' 88       88 88  ,d8' '8b,", 10
db "  88       88  `'Pbbd8'' 8P'     `P8 `'8bbdP'P8  `'PbbdP'P8  `'PbbdP''  88       88 88 8P'     `P8", 10
db "                                                 aa,    ,88", 10
db "                                                  'P8bbdP'", 10, 10
db "                                  Hexagonix Operating System", 10, 10
db "                       Copyright (C) 2015-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "                                     All rights reserved.", 10, 0

}

match =Hexagonix, LOGIN_STYLE
{

.aboutSystem: db 0

}

.file:
db "passwd", 0 ;; Login configuration filename
.positionBX: ;; Marking the search position in the file content
dw 0
.systemVersion:
db 10, "Hexagonix ", 0
.console:
db " (tty0)", 0
.fileNotFound:
db 10, 10, "The user database was not found on the volume.", 10, 0
.leftBracket:
db " [", 0
.rightBracket:
db "]", 0
.lightTheme:
db "light", 0
.darkTheme:
db "dark", 0
.unknownVersion:
db "[unknown]", 0
.verboseLogind:
db "logind version ", VERSION, ".", 0
.OOBE:
db "oobe", 0

;; Buffers

themeChosen: ;; Buffer for user-defined theme
times 7 db 0

;;************************************************************************************

daemonStart: ;; Entry point

;; logind is a daemon that should only be used during startup.
;; To do this, it must check if the PID is 3 (init=1 and login=2).

    hx.syscall hx.pid

    cmp eax, 03h
    je startProcessing

    hx.syscall hx.exit

startProcessing:

    systemLog logind.verboseLogind, 0, Log.Priorities.p4

;; Now let's initialize the tty1 virtual console, clearing its contents and setting
;; its graphical properties. First, we must save the cursor position in the current console,
;; since it will have its position reset when the console is cleared.
;; This step takes this complexity out of Hexagon, reducing possible bugs and allowing expand to
;; other consoles in the future without having to change anything in the kernel.

    hx.syscall hx.getCursor

    push edx ;; Save current console position

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open the secondary console

    hx.syscall hx.open ;; Open the device

    hx.syscall hx.clearConsole

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopen the default console

    hx.syscall hx.open ;; Open the device

    pop edx ;; Restaurar posição do console

    hx.syscall hx.setCursor

.verifyOOBE:

    mov esi, logind.OOBE

    hx.syscall hx.fileExists

    mov esi, logind.OOBE
    mov eax, 0h

    hx.syscall hx.exec

    jc .continue

.continue:

    call checkDatabase

match =Modern, LOGIN_STYLE
{

    call verifyTheme

    hx.syscall hx.clearConsole

}

    call displaySystemInfo

    jmp finish

;;************************************************************************************

verifyTheme:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, logind.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .fileNotFound

    mov si, appFileBuffer ;; Points to the buffer with the file contents
    mov bx, 0FFFFh ;; Starts at position -1, so you can find the delimiters

.searchBetweenDelimiters:

    inc bx

    mov word[logind.positionBX], bx

    cmp bx, searchSizeLimit
    je .invalidThemeName ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '<'
    jne .searchBetweenDelimiters ;; The initial limiter has been found

;; BX now points to the first character of the username retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, themeChosen ;; The theme will be copied to ES:DI

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getTheme:

    inc bx

    cmp bx, 7
    je .invalidThemeName ;; If username is greater than 7, it is invalid

    mov al, [ds:si+bx]

    cmp al, '>' ;; If another delimiter is found, the username was loaded successfully
    je .themeObtained

;; If not ready, store the obtained character

    stosb

    jmp .getTheme

.themeObtained:

    mov edi, themeChosen
    mov esi, logind.lightTheme

    hx.syscall hx.compareWordsString

    jc .selectLightTheme

    mov edi, themeChosen
    mov esi, logind.darkTheme

    hx.syscall hx.compareWordsString

    jc .selectDarkTheme

    mov word bx, [logind.positionBX]

    mov si, appFileBuffer

    jmp .searchBetweenDelimiters

.selectLightTheme:

    pop es

    popa

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open first virtual console

    hx.syscall hx.open ;; Open the device

    mov eax, HEXAGONIX_CLASSICO_PRETO
    mov ebx, HEXAGONIX_CLASSICO_BRANCO

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole ;; Clean the console

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopens the standard console

    hx.syscall hx.open ;; Open the device

    mov eax, PRETO
    mov ebx, BRANCO_ANDROMEDA

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole ;; Clean the console

    ret

.selectDarkTheme:

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open first virtual console

    hx.syscall hx.open ;; Open the device

    mov eax, HEXAGONIX_BLOSSOM_AMARELO
    mov ebx, HEXAGONIX_BLOSSOM_CINZA

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole ;; Clean the console

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopens the standard console

    hx.syscall hx.open ;; Open the console

    mov eax, BRANCO_ANDROMEDA
    mov ebx, PRETO

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole ;; Clean the console

.invalidThemeName:

    pop es

    popa

    ret

.fileNotFound:

    pop es

    popa

    fputs logind.fileNotFound

    jmp finish

;;************************************************************************************

displaySystemInfo:

    fputs logind.aboutSystem

    fputs logind.systemVersion

    call getHexagonixVersion

    jc .error

    fputs versionObtained

    jmp .continue

.error:

    fputs logind.unknownVersion

    jmp .continue

.continue:

    fputs logind.console

    putNewLine

    ret

;;************************************************************************************

checkConsistency:

;; If any process is terminated after changing the default background

    call verifyTheme

    hx.syscall hx.clearConsole

    ret

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

checkDatabase:

    clc

    mov esi, logind.file

    hx.syscall hx.fileExists

    ret

;;************************************************************************************

appFileBuffer: ;; Location where the configuration file will be opened
