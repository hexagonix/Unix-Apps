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
;;                          adduser utility for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 5, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "passwdHash.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    hx.syscall hx.getUser

    cmp eax, 777
    je .isRoot

    fputs adduser.permissionDenied

    jmp finish

.isRoot:

    fputs adduser.promptUser

    mov eax, 15

    mov ebx, 1

    hx.syscall hx.getString

    hx.syscall hx.trimString

    cmp byte[esi], 0
    je .noUsername

    mov edi, newUser

    call Hexagon.LibASM.PasswdHash.copyString

    mov esi, newUser

    call Hexagon.LibASM.PasswdHash.findUser

    jnc .alreadyExists

    fputs adduser.promptPassword

    mov eax, 64

    mov ebx, 1234h ;; We don't want to echo the password!

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov edi, passwordFirst

    call Hexagon.LibASM.PasswdHash.copyString

    fputs adduser.promptPasswordAgain

    mov eax, 64

    mov ebx, 1234h

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov edi, passwordFirst

    hx.syscall hx.compareWordsString

    jnc .passwordMismatch

    mov esi, passwordFirst

    call Hexagon.LibASM.PasswdHash.hash

    fputs adduser.promptShell

    mov eax, 11

    mov ebx, 1

    hx.syscall hx.getString

    hx.syscall hx.trimString

    cmp byte[esi], 0
    jne .shellGiven

    mov esi, adduser.defaultShell

.shellGiven:

    mov edi, newShell

    call Hexagon.LibASM.PasswdHash.copyString

    fputs adduser.promptTheme

    mov eax, 7

    mov ebx, 1

    hx.syscall hx.getString

    hx.syscall hx.trimString

    cmp byte[esi], 0
    jne .themeGiven

    mov esi, adduser.defaultTheme

.themeGiven:

    mov edi, newTheme

    call Hexagon.LibASM.PasswdHash.copyString

    call appendUser

    jc .writeError

    fputs adduser.success

    jmp finish

.noUsername:

    fputs adduser.withoutUsername

    jmp finish

.alreadyExists:

    fputs adduser.userExists

    jmp finish

.passwordMismatch:

    fputs adduser.passwordMismatch

    jmp finish

.writeError:

    fputs adduser.writeError

    jmp finish

;;************************************************************************************

;; Appends a new username:hash:555:shell:theme line to /shadow and writes the
;; whole file back (hx.unlink then hx.create, see the plan's Decisions:
;; hx.create's own overwrite behavior is never relied on)
;;
;; Input: newUser, Hexagon.LibASM.PasswdHash.hashBuffer, newShell, newTheme
;; already filled in by the caller
;;
;; Output: CF set on write failure

appendUser:

    mov esi, Hexagon.LibASM.PasswdHash.file
    mov edi, Hexagon.LibASM.PasswdHash.fileBuffer

    xor ecx, ecx

    hx.syscall hx.open

    jc .empty

    mov esi, Hexagon.LibASM.PasswdHash.fileBuffer

    hx.syscall hx.stringSize

    mov edi, Hexagon.LibASM.PasswdHash.fileBuffer

    add edi, eax

    cmp eax, 0
    je .buildLine

    mov esi, edi

    dec esi ;; ESI -> last real byte of the existing content

    cmp byte[esi], 10
    je .buildLine ;; Already ends in a newline

    mov byte[edi], 10 ;; Separator newline before the new record

    inc edi

    jmp .buildLine

.empty:

    mov edi, Hexagon.LibASM.PasswdHash.fileBuffer

.buildLine:

    mov esi, newUser

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, Hexagon.LibASM.PasswdHash.hashBuffer

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, adduser.defaultCode

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, newShell

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, newTheme

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], 10

    inc edi

    mov byte[edi], 0

    mov esi, Hexagon.LibASM.PasswdHash.file

    hx.syscall hx.unlink

    mov esi, Hexagon.LibASM.PasswdHash.fileBuffer

    hx.syscall hx.stringSize

    mov esi, Hexagon.LibASM.PasswdHash.file
    mov edi, Hexagon.LibASM.PasswdHash.fileBuffer

    hx.syscall hx.create

    ret

;;************************************************************************************

applicationUsage:

    fputs adduser.use

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

adduser:

.use:
db 10, "Usage: adduser", 10, 10
db "Interactively creates a new Hexagonix user account.", 10, 10
db "adduser version ", VERSION, 10, 10
db "Copyright (C) 2015-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.permissionDenied:
db 10, "Only an administrative (or root) user can complete this action.", 10
db "Login in this user to perform the desired operation.", 0
.promptUser:
db 10, "Username: ", 0
.promptPassword:
db 10, "Password: ", 0
.promptPasswordAgain:
db 10, "Repeat password: ", 0
.promptShell:
db 10, "Shell [sh]: ", 0
.promptTheme:
db 10, "Theme (dark/light) [dark]: ", 0
.withoutUsername:
db 10, "A username is required.", 0
.userExists:
db 10, "That username already exists.", 0
.passwordMismatch:
db 10, "The passwords entered do not match.", 0
.writeError:
db 10, "Could not write /shadow. No user was created.", 0
.success:
db 10, "User created.", 0
.defaultShell:
db "/bin/sh", 0
.defaultTheme:
db "dark", 0
.defaultCode:
db "555", 0

newUser:
times 17 db 0
passwordFirst:
times 65 db 0
newShell:
times 12 db 0
newTheme:
times 8 db 0
