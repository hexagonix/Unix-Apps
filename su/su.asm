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
;;                            su utility for Hexagonix
;;
;;                 Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

;; WARNING! This Unix tool uses the same syntax and modules as the Unix login tool.
;;
;; Pay attention to possible changes in the structure of the file used by login.
;;
;; The Unix su utility uses the same 'passwd' file as login.

use32

searchSizeLimit = 12288

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, suHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

suHexagonix: ;; Entry point

    mov [userRequested], edi

    mov edi, su.helpParameter
    mov esi, [userRequested]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, su.helpParameter2
    mov esi, [userRequested]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [userRequested]

    cmp byte[esi], 0
    je applicationUsage

startProcessing:

    putNewLine

    call saveCurrentUser ;; Saves the current user

    clc

    call findUserName

    jc .withoutUser

    call findUserPassword

    fputs su.solicitarSenha

    mov eax, 64

    mov ebx, 1234h ;; We don't want to echo the password!

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov edi, passwordObtained

    hx.syscall hx.compareWordsString

    jc .loginAccepted

    jmp finishExecution

.withoutUser:

    cmp byte[parameters], 0
    je finish

.loginAccepted:

    call registerUser

    call findShell

    call checkUser

    jc .greatPowers

    jmp .loadShell

.greatPowers:

    fputs su.greatPowers

.loadShell:

    mov eax, 0 ;; Do not pass arguments
    mov esi, shellHexagonix ;; Filename

    stc

    hx.syscall hx.exec ;; Request to load the Hexagonix shell

    jnc .shellFinished

.shellNotFound: ;; The shell could not be located

;; Check if you have already tried to load the default Hexagonix shell

   cmp byte[tryDefaultShell], 0
   je .tryDefaultShell ;; If not, try loading the default Hexagonix shell

   hx.syscall hx.exit ;; If yes, the default shell cannot be run either

.tryDefaultShell: ;; Try loading the default Hexagonix shell

;; Configure Hexagonix default shell name (filename)

   call getDefaultShell

;; Try to load default shell

   mov byte[tryDefaultShell], 1

   jmp .loadShell ;; Try loading the default Hexagonix shell

.shellFinished: ;; Try loading the shell again

    call restoreUser ;; Restores the user from the previous session

    jmp finish

;;************************************************************************************

checkUser:

    clc

    mov esi, su.rootUser
    mov edi, user

    hx.syscall hx.compareWordsString

    ret

;;************************************************************************************

registerUser:

    clc

    mov esi, su.rootUser
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

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, su.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .fileNotFound

    mov si, appFileBuffer ;; Points to the buffer with the file contents
    mov bx, 0FFFFh ;; Starts at position -1, so you can find the delimiters

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

    cmp bx, searchSizeLimit
    je .invalidUsername ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '@'
    jne .searchBetweenDelimiters ;; The starting delimiter was found

;; BX now points to the first character of the username retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, user ;; The username will be copied to ES:DI

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.getUsername:

    inc bx

    cmp bx, 17
    je .invalidUsername ;; If username is greater than 15, it is invalid

    mov al, [ds:si+bx]

    cmp al, '|' ;; If another delimiter is found, the username was loaded successfully
    je .usernameObtained

;; If not ready, store the obtained character

    stosb

    jmp .getUsername

.usernameObtained:

    mov edi, user
    mov esi, [userRequested]

    hx.syscall hx.compareWordsString

    jc .obtained

    call clearVariables

    mov word bx, [positionBX]

    mov si, appFileBuffer

    jmp .searchBetweenDelimiters

.obtained:

    pop es

    popa

    clc

    ret

.invalidUsername:

    pop es

    popa

    fputs su.withoutUser

    fputs [userRequested]

    stc

    ret

.fileNotFound:

    pop es

    popa

    fputs su.fileNotFound

    jmp finish

;;************************************************************************************

clearVariables:

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

findUserPassword:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, su.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .fileNotFound

    mov si, appFileBuffer    ;; Points to the buffer with the file contents
    mov bx, word [positionBX] ;; Continue where the previous option left off

    dec bx

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

    cmp bx, searchSizeLimit

    je .invalidPassword ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '|'
    jne .searchBetweenDelimiters ;; The starting delimiter was found

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
    je .invalidPassword ;; If password greater than 66, it is invalid

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

.invalidPassword:

    pop es

    popa

    stc

    ret

.fileNotFound:

    pop es

    popa

    fputs su.fileNotFound

    jmp finish

;;************************************************************************************

findShell:

    pusha

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, su.file
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .fileNotFound

    mov si, appFileBuffer ;; Points to the buffer with the file contents
    mov bx, word [positionBX] ;; Continue where the previous option left off

    dec bx

.searchBetweenDelimiters:

    inc bx

    mov word[positionBX], bx

    cmp bx, searchSizeLimit

    je .fileNotFound ;; If nothing is found within the size limit, cancel the search

    mov al, [ds:si+bx]

    cmp al, '&'
    jne .searchBetweenDelimiters ;; The starting delimiter was found

;; BX now points to the first character of the shell name retrieved from the file

    push ds ;; User mode data segment (38h selector)
    pop es

    mov di, shellHexagonix ;; The shell name will be copied to ES:DI - shellHexagonix

    mov si, appFileBuffer

    add si, bx ;; Move SI to where BX points

    mov bx, 0 ;; Start at 0

.shellNameObtained:

    inc bx

    cmp bx, 13
    je .invalidShellName ;; If file name greater than 11, the name is invalid

    mov al, [ds:si+bx]

    cmp al, '#' ;; If another delimiter is found, the name was loaded successfully
    je .obtained

;; If not ready, store the obtained character

    stosb

    jmp .shellNameObtained

.obtained:

    pop es

    popa

    ret

.invalidShellName:

    pop es

    popa

    jmp getDefaultShell


.fileNotFound:

    pop es

    popa

    jmp getDefaultShell

;;************************************************************************************

getDefaultShell:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, su.defaultShell

    hx.syscall hx.stringSize

    push eax

    mov edi, shellHexagonix
    mov esi, su.defaultShell

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

    fputs su.use

    jmp finish

;;************************************************************************************

finishExecution:

    fputs su.authenticationFailure

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

VERSION equ "1.9.0"

su:

.greatPowers:
db 10, 10, "You are now an administrative user. This means you can make deep changes to system, so be careful.", 10, 10
db 'Remember: "Great power comes with great responsibility"!', 0
.solicitarSenha:
db "Enter your UNIX password: ", 0
.use:
db 10, "Usage: su [user]", 10, 10
db "Change to a registered user.", 10, 10
db "su version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.fileNotFound:
db 10, "The user database was not found on the volume.", 0
.withoutUser:
db 10, "The requested user was not found: ", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.rootUser:
db "root", 0
.authenticationFailure:
db 10, "su: authentication failed.", 0
.defaultShell: ;; Name of the file containing the default Hexagonix shell
db "sh", 0
.file: ;; Login database filename
db "passwd", 0

;; Buffers

userRequested: ;; Requested User Buffer
times 17 db 0
previousUser: ;; Previous User Buffer
times 17 db 0
shellHexagonix: ;; Stores the filename of the shell to be used by the system
times 11 db 0
user: ;; Username obtained from file
times 15 db 0
passwordObtained: ;; Password obtained from file
times 64 db 0

previousCode:    dd 0 ;; Previous user code
tryDefaultShell: db 0 ;; Signals an attempt to load the default shell
parameters: db 0 ;; If the application received any parameters
positionBX: dw 0

;;************************************************************************************

appFileBuffer: ;; Location where the configuration file will be opened
