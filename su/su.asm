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
;;                            su utility for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

;; WARNING! This Unix tool uses the same syntax and modules as the Unix login tool.
;;
;; Pay attention to possible changes in the structure of the file used by login.
;;
;; The Unix su utility uses the same '/shadow' database as login.

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 6, suHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "passwdHash.s"

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

    mov esi, [userRequested]

    call Hexagon.LibASM.PasswdHash.findUser

    jc .withoutUser

    fputs su.solicitarSenha

    mov eax, 64

    mov ebx, 1234h ;; We don't want to echo the password!

    hx.syscall hx.getString

    hx.syscall hx.trimString

    call Hexagon.LibASM.PasswdHash.hash ;; ESI still points at the trimmed, typed password

    mov esi, Hexagon.LibASM.PasswdHash.hashBuffer
    mov edi, Hexagon.LibASM.PasswdHash.hashFound

    hx.syscall hx.compareWordsString

    jc .loginAccepted

    jmp finishExecution

.withoutUser:

    fputs su.withoutUser

    fputs [userRequested]

    cmp byte[parameters], 0
    je finish

.loginAccepted:

    call registerUser

    call copyFoundShell

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

;; CF set if the authenticated user's code is root (777), used to show the
;; "great powers" warning before starting the shell

checkUser:

    cmp dword[Hexagon.LibASM.PasswdHash.codeFound], 777
    je .isRoot

    clc

    ret

.isRoot:

    stc

    ret

;;************************************************************************************

registerUser:

    mov eax, [Hexagon.LibASM.PasswdHash.codeFound]

    mov esi, [userRequested]

    hx.syscall hx.setUser

    ret

;;************************************************************************************

;; Copies Hexagon.LibASM.PasswdHash.shellFound (the authenticated user's shell
;; field) into shellHexagonix, the buffer .loadShell/.tryDefaultShell already
;; share. shellHexagonix starts zero-filled and su only ever does this copy
;; once per run, so no explicit NUL padding is needed, same assumption
;; getDefaultShell below already relies on

copyFoundShell:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, Hexagon.LibASM.PasswdHash.shellFound

    hx.syscall hx.stringSize

    push eax

    mov edi, shellHexagonix
    mov esi, Hexagon.LibASM.PasswdHash.shellFound

    pop ecx

    rep movsb

    pop es

    ret

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

VERSION equ "2.1.0"

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
.authenticationFailure:
db 10, "su: authentication failed.", 0
.defaultShell: ;; Name of the file containing the default Hexagonix shell
db "sh", 0

;; Buffers

userRequested: ;; Requested User Buffer
times 17 db 0
previousUser: ;; Previous User Buffer
times 17 db 0
shellHexagonix: ;; Stores the filename of the shell to be used by the system
times 12 db 0

previousCode:    dd 0 ;; Previous user code
tryDefaultShell: db 0 ;; Signals an attempt to load the default shell
parameters: db 0 ;; If the application received any parameters
