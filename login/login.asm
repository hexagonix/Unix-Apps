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
;;                       Unix utility login for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 6, loginHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "log.s"
include "dev.s"
include "passwdHash.s"

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

;;************************************************************************************

VERSION equ "6.0.0"

login:

.defaultShell: ;; Name of the file containing the default Hexagonix shell
db "sh", 0
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
.wrongData:
db 10, "Login incorrect", 0
.logind:
db "logind", 0
.lightTheme:
db "light", 0
.darkTheme:
db "dark", 0

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
.rootUser:
db "root", 0

;; Buffers

tryDefaultShell: ;; Signals an attempt to load the default shell
db 0
previousCode:
dd 0
wrong:
db 0
parameters: ;; If the application received any parameters
db 0

hexagonixShell: ;; Stores the name of the shell to be used
times 12 db 0
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

    fputs login.requestUser

    mov eax, 15

    mov ebx, 01h

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov [requestedUser], esi

    mov esi, [requestedUser]

    call Hexagon.LibASM.PasswdHash.findUser

    jc .withoutUser

    fputs login.requestPassword

    mov eax, 64

    mov ebx, 1234h ;; We don't want to echo the password!

    hx.syscall hx.getString

    hx.syscall hx.trimString

    cmp byte[wrong], 1
    jne .continueProcessing

    jmp .loginRefused

.continueProcessing:

    call Hexagon.LibASM.PasswdHash.hash ;; ESI still points at the trimmed, typed password

    mov esi, Hexagon.LibASM.PasswdHash.hashBuffer
    mov edi, Hexagon.LibASM.PasswdHash.hashFound

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

match =Modern, LOGIN_STYLE
{

    call applyTheme

}

    call copyFoundShell

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

.shellFinished:

    hx.syscall hx.lock

    systemLog login.verboseLogout, 0, Log.Priorities.p4

;; login is one-shot: one session, then it exits. Whatever launched it (a
;; respawn= entry in /rc, or a user running it directly) is responsible for
;; deciding whether to run it again

    putNewLine

    jmp finish

.notFound: ;; The shell could not be located

;; Check if you have already tried to load the default Hexagonix shell

   cmp byte[tryDefaultShell], 0
   je .tryDefaultShell ;; If not, try loading the default Hexagonix shell

   jmp finish ;; If yes, the default shell cannot be run either

;;************************************************************************************

;; Copies Hexagon.LibASM.PasswdHash.shellFound (the authenticated user's shell
;; field) into hexagonixShell, the buffer .startShell/.tryDefaultShell already
;; share. hexagonixShell starts zero-filled and login only ever does this copy
;; once per run, so no explicit NUL padding is needed, same assumption
;; getDefaultShell below already relies on

copyFoundShell:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov esi, Hexagon.LibASM.PasswdHash.shellFound

    hx.syscall hx.stringSize

    push eax

    mov edi, hexagonixShell
    mov esi, Hexagon.LibASM.PasswdHash.shellFound

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

;; Colors the console to match the authenticated user's theme field. Checks
;; tty0's actual current colors against the target theme's pair first, since
;; the console may already be showing it (Apps/Unix/logind/logind.asm's
;; verifyTheme paints its own fixed default before any user is known), and
;; skips the repaint if so; whatever painted the console before is not
;; assumed to be any particular theme

applyTheme:

    push es

    push ds ;; User mode data segment (38h selector)
    pop es

    mov edi, Hexagon.LibASM.PasswdHash.themeFound
    mov esi, login.lightTheme

    hx.syscall hx.compareWordsString

    jc .light

    mov edi, Hexagon.LibASM.PasswdHash.themeFound
    mov esi, login.darkTheme

    hx.syscall hx.compareWordsString

    jc .dark

    jmp .done ;; Unrecognized theme value, leave the colors as they are

.light:

    mov esi, Hexagon.LibASM.Dev.video.tty0

    hx.syscall hx.open

    hx.syscall hx.getColor ;; EAX = current font color, EBX = current background

    cmp eax, PRETO
    jne .lightApply

    cmp ebx, BRANCO_ANDROMEDA
    jne .lightApply

    jmp .done ;; Console already matches light, nothing to repaint

.lightApply:

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open first virtual console

    hx.syscall hx.open

    mov eax, HEXAGONIX_CLASSICO_PRETO
    mov ebx, HEXAGONIX_CLASSICO_BRANCO

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopens the standard console

    hx.syscall hx.open

    mov eax, PRETO
    mov ebx, BRANCO_ANDROMEDA

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole

    jmp .done

.dark:

    mov esi, Hexagon.LibASM.Dev.video.tty0

    hx.syscall hx.open

    hx.syscall hx.getColor ;; EAX = current font color, EBX = current background

    cmp eax, BRANCO_ANDROMEDA
    jne .darkApply

    cmp ebx, PRETO
    jne .darkApply

    jmp .done ;; Console already matches dark, nothing to repaint

.darkApply:

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Open first virtual console

    hx.syscall hx.open

    mov eax, HEXAGONIX_BLOSSOM_AMARELO
    mov ebx, HEXAGONIX_BLOSSOM_CINZA

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reopens the standard console

    hx.syscall hx.open

    mov eax, BRANCO_ANDROMEDA
    mov ebx, PRETO

    hx.syscall hx.setColor

    hx.syscall hx.clearConsole

.done:

    pop es

    ret

;;************************************************************************************

registerUser:

    mov eax, [Hexagon.LibASM.PasswdHash.codeFound]

    mov esi, [requestedUser]

    hx.syscall hx.setUser

    ret

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

    mov esi, Hexagon.LibASM.PasswdHash.file

    hx.syscall hx.fileExists

    jc defaultLogin

    ret
