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
;;                       Unix utility login for Hexagonix
;;
;;                 Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, loginHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "log.s"

searchSizeLimit = 32768

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

;;************************************************************************************

VERSION equ "4.11.1"

login:

.defaultShell: ;; Name of the file containing the default Hexagonix shell
db "sh", 0
.file: ;; Login management filename
db "passwd", 0
.fileNotFound:
db 10, 10, "The user database was not found on the volume.", 10, 0
.requestUser:
db 10, "Login: ", 0
.requestPassword:
db 10, "Password: ", 0
.use:
db 10, 10, "Usage: login [user]", 10, 10
db "Log in a registered user.", 10, 10
db "login version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.rootUser:
db "root", 0
.wrongData:
db 10, "Login incorrect", 0
.logind:
db "logind", 0

;; Verbose Messages

.verboseLogin:
db "login version ", VERSION, ".", 0
.verboseFindFile:
db "Searching user database in /...", 0
.verboseFileFound:
db "The user database was found.", 0
.verboseFileNotFound:
db "The user database was not found. The default shell will run (sh.app).", 0
.verboseError:
db "An unhandled error was encountered.", 0
.verboseLoginAccept:
db "Login accepted.", 0
.verboseLoginRefused:
db "Login attempt prevented by authentication failure.", 0
.verboseLogout:
db "Logout performed successfully.", 0

;; Buffers

tryDefaultShell: ;; Signals an attempt to load the default shell
db 0
previousCode:
dd 0
wrong:
db 0
startedByInit:
db 0
parameters: ;; If the application received any parameters
db 0
positionBX: ;; Marking the search position in the file content
dw 0

hexagonixShell: ;; Stores the name of the shell to be used
times 11 db 0
user: ;; Username obtained from the file
times 15 db 0
passwordObtained:;; Password obtained from the file
times 64 db 0
requestedUser:
times 17 db 0
previousUser:
times 17 db 0

;;************************************************************************************

loginHexagonix: ;; Entry point

    mov [requestedUser], edi

    mov edi, login.helpParameter
    mov esi, [requestedUser]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, login.helpParameter2
    mov esi, [requestedUser]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    call checkDatabase

    systemLog login.verboseLogin, 0, Log.Priorities.p4

startProcessing:

    hx.syscall hx.pid

    cmp eax, 02h
    je .viaInit

    mov byte [startedByInit], 00h

    jmp .continueAfterValidation

.viaInit:

    mov byte [startedByInit], 01h

.continueAfterValidation:

    call runLogind

    cmp byte[wrong], 1
    jne .initialRun

;; We don't need to run logind again

.continueAfterLoginRefused:

    clc

    systemLog login.verboseLoginRefused, 0, Log.Priorities.p4

    fputs login.wrongData

    mov byte[wrong], 0

.initialRun:

    systemLog login.verboseFindFile, 0, Log.Priorities.p4

    call clearUserVariables

    fputs login.requestUser

    mov eax, 15

    mov ebx, 01h

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov [requestedUser], esi

    call findUserName

    jc .withoutUser

    call findUserPassword

    fputs login.requestPassword

    mov eax, 64

    mov ebx, 1234h ;; We don't want to echo the password!

    hx.syscall hx.getString

    hx.syscall hx.trimString

    cmp byte[wrong], 1
    jne .continueProcessing

    jmp .loginRefused

.continueProcessing:

    mov edi, passwordObtained

    hx.syscall hx.compareWordsString

    jc .loginAccepted

.loginRefused:

    systemLog login.verboseLoginRefused, 00h, Log.Priorities.p4

    mov byte[wrong], 1

    jmp startProcessing.continueAfterLoginRefused

.withoutUser:

    cmp byte[parameters], 0
    je finish

.loginAccepted:

    systemLog login.verboseLoginAccept, 0, Log.Priorities.p4

    call registerUser

    call findUserShell

    hx.syscall hx.unlock

.startShell:

    clc

    mov esi, hexagonixShell

    hx.syscall hx.fileExists

    jc .notFound

    mov eax, 0 ;; Do not pass arguments
    mov esi, hexagonixShell ;; Filename

    clc

    hx.syscall hx.exec ;; Request to run the Hexagonix shell

    jc .tryDefaultShell

    hx.syscall hx.lock

    jmp .shellFinished

.tryDefaultShell: ;; Try loading the default Hexagonix shell

   call getDefaultShell ;; Configure Hexagonix default shell name

   mov byte[tryDefaultShell], 1 ;; Try loading the default Hexagonix shell

   jmp .startShell ;; Try loading the default Hexagonix shell

.shellFinished: ;; Try loading the shell again

    hx.syscall hx.lock

    systemLog login.verboseLogout, 0, Log.Priorities.p4

;; Here we will implement a change in the way login should interpret shell exit.
;; If login has PID 2, it means it was invoked via init. Therefore, he must remain
;;  a resident at this time. If PID 2, request user input again

    putNewLine

    cmp byte [startedByInit], 01h
    jne finish

    jmp .initialRun

.notFound: ;; The shell could not be located

;; Check if you have already tried to load the default Hexagonix shell

   cmp byte[tryDefaultShell], 0
   je .tryDefaultShell ;; If not, try loading the default Hexagonix shell

   jmp finish ;; If yes, the default shell cannot be run either

;;************************************************************************************

registerUser:

    clc

    mov esi, login.rootUser
    mov edi, user

    hx.syscall hx.compareWordsString

    jc .root

    mov eax, 555 ;; Common user code

    jmp .register

.root:

    mov eax, 777 ;; Root user code

.register:

    mov esi, user

    hx.syscall hx.setUser

    ret

;;************************************************************************************

findUserName:

    clc

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, login.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .userFileNotFound

    mov si, appFileBuffer ;; Points to the buffer with the file contents
    mov bx, 0FFFFh ;; Starts at position -1, so you can find the delimiters

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

    cmp bx, searchSizeLimit
    je .invalidUserName ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '@'
    jne .searchBetweenDelimiters ;; The initial delimiter has been found

;; BX now points to the first character of the username retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, user ;; The username will be copied to ES:DI

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getUserName:

    inc bx

    cmp bx, 17
    je .invalidUserName ;; If username is greater than 15, it is invalid

    mov al, [ds:si+bx]

    cmp al, '|' ;; If another delimiter is found, the username was loaded successfully
    je .userNameObtained

;; If not ready, store the obtained character

    stosb

    jmp .getUserName

.userNameObtained:

    mov edi, user
    mov esi, [requestedUser]

    hx.syscall hx.compareWordsString

    jc .obtained

    call clearVariable

    mov word bx, [positionBX]

    mov si, appFileBuffer

    jmp .searchBetweenDelimiters

.obtained:

    pop es

    popa

    clc

    ret

.invalidUserName:

    pop es

    popa

    mov byte[wrong], 1

    clc

    ret

.userFileNotFound:

    pop es

    popa

    fputs login.fileNotFound

    jmp finish

;;************************************************************************************

clearVariable:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, user

    hx.syscall hx.stringSize

    push eax

    mov esi, 0

    mov edi, user

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

clearUserVariables:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, user

    hx.syscall hx.stringSize

    push eax

    mov esi, ' '

    mov edi, user

    pop ecx

    rep movsb

    mov esi, requestedUser

    hx.syscall hx.stringSize

    push eax

    mov esi, ' '

    mov edi, passwordObtained

    pop ecx

    rep movsb

    mov esi, hexagonixShell

    hx.syscall hx.stringSize

    push eax

    mov esi, " "

    mov edi, hexagonixShell

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

findUserPassword:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, login.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .userFileNotFound

    mov si, appFileBuffer    ;; Points to the buffer with the file contents
    mov bx, word [positionBX] ;; Continua de onde a opção anterior parou

    dec bx

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

    cmp bx, searchSizeLimit

    je .invalidUserPassword ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '|'
    jne .searchBetweenDelimiters ;; The initial delimiter has been found

;; BX now points to the first character of the password retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, passwordObtained ;; The password will be copied to ES:DI

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getUserPassword:

    inc bx

    cmp bx, 66
    je .invalidUserPassword ;; If password greater than 66, it is invalid

    mov al, [ds:si+bx]

    cmp al, '&' ;; If another delimiter is found, the password has been loaded successfully
    je .userPasswordObtained

;; If not ready, store the obtained character

    stosb

    jmp .getUserPassword

.userPasswordObtained:

    pop es

    popa

    ret

.invalidUserPassword:

    pop es

    popa

    mov byte[wrong], 1

    clc

    ret

.userFileNotFound:

    pop es

    popa

    fputs login.fileNotFound

    jmp finish

;;************************************************************************************

findUserShell:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, login.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .configurationFileNotFound

    mov si, appFileBuffer   ;; Points to the buffer with the file contents
    mov bx, word[positionBX] ;; Continue where the previous option left off

    dec bx

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

    cmp bx, searchSizeLimit

    je .configurationFileNotFound  ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '&'
    jne .searchBetweenDelimiters ;; The initial limiter has been found

;; BX now points to the first character of the shell name retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, hexagonixShell ;; The shell name will be copied to ES:DI - hexagonixShell

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getShellName:

    inc bx

    cmp bx, 13
    je .invalidShellName ;; If file name greater than 11, the name is invalid

    mov al, [ds:si+bx]

    cmp al, '#' ;; If another delimiter is found, the name was loaded successfully
    je .shellNameObtained

;; If not ready, store the obtained character

    stosb

    jmp .getShellName

.shellNameObtained:

    pop es

    popa

    ret

.invalidShellName:

    pop es

    popa

    jmp getDefaultShell


.configurationFileNotFound:

    pop es

    popa

    jmp getDefaultShell

;;************************************************************************************

getDefaultShell:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, login.defaultShell

    hx.syscall hx.stringSize

    push eax

    mov edi, hexagonixShell
    mov esi, login.defaultShell

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

saveCurrentUser:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    hx.syscall hx.getUser

    push esi

    hx.syscall hx.stringSize

    pop esi

    push eax

    mov edi, previousUser

    pop ecx

    rep movsb

    pop es

    hx.syscall hx.getUser

    mov [previousCode], eax

    ret

;;************************************************************************************

restoreUser:

    mov esi, previousUser
    mov eax, [previousCode]

    hx.syscall hx.setUser

    ret

;;************************************************************************************

applicationUsage:

    fputs login.use

    jmp finish

;;************************************************************************************

runLogind:

    mov eax, 0 ;; Do not pass arguments
    mov esi, login.logind ;; File name

    clc

    hx.syscall hx.exec ;; Request login daemon loading

    ret

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

defaultLogin:

;; If the user database file is not found, we must start a standard system shell,
;; logged in as root.

;; First, log in as root

    mov eax, 777 ;; Root user code

    mov esi, login.rootUser

    hx.syscall hx.setUser

    mov eax, 0
    mov esi, login.defaultShell

    clc

    hx.syscall hx.exec

    je finish

;;************************************************************************************

;; First, we must check the user database.
;; If the database is not available, the system must be logged in with the root user
;; and the default shell must be started.

checkDatabase:

    clc

    mov esi, login.file

    hx.syscall hx.fileExists

    jc defaultLogin

    ret

;;************************************************************************************

appFileBuffer: ;; Location where the configuration file will be opened
