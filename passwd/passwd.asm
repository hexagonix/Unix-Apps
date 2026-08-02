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
;;                          passwd utility for Hexagonix
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

    mov [parameters], edi

    mov edi, passwd.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, passwd.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [parameters]

    cmp byte[esi], 0
    je .ownPassword

;; A username argument was given, only root may do this without knowing
;; the target's current password

    hx.syscall hx.getUser

    cmp eax, 777
    je .targetGiven

    fputs passwd.permissionDenied

    jmp finish

.targetGiven:

    mov esi, [parameters]
    mov edi, targetUser

    call Hexagon.LibASM.PasswdHash.copyString

    mov esi, targetUser

    call Hexagon.LibASM.PasswdHash.findUser

    jc .userNotFound

    jmp .newPassword

.ownPassword:

    hx.syscall hx.getUser ;; ESI = own username

    mov edi, targetUser

    call Hexagon.LibASM.PasswdHash.copyString

    mov esi, targetUser

    call Hexagon.LibASM.PasswdHash.findUser

    jc .userNotFound

    fputs passwd.promptCurrent

    mov eax, 64

    mov ebx, 1234h ;; We don't want to echo the password!

    hx.syscall hx.getString

    hx.syscall hx.trimString

    call Hexagon.LibASM.PasswdHash.hash

    mov esi, Hexagon.LibASM.PasswdHash.hashBuffer
    mov edi, Hexagon.LibASM.PasswdHash.hashFound

    hx.syscall hx.compareWordsString

    jnc .wrongCurrent

.newPassword:

    fputs passwd.promptNew

    mov eax, 64

    mov ebx, 1234h

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov edi, newPasswordFirst

    call Hexagon.LibASM.PasswdHash.copyString

    fputs passwd.promptNewAgain

    mov eax, 64

    mov ebx, 1234h

    hx.syscall hx.getString

    hx.syscall hx.trimString

    mov edi, newPasswordFirst

    hx.syscall hx.compareWordsString

    jnc .mismatch

    mov esi, newPasswordFirst

    call Hexagon.LibASM.PasswdHash.hash

;; Build the replacement line: username:newhash:code:shell:theme, reusing
;; the code/shell/theme fields Hexagon.LibASM.PasswdHash.findUser already
;; resolved for targetUser, only the hash field actually changes

    mov edi, replacementLine

    mov esi, targetUser

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, Hexagon.LibASM.PasswdHash.hashBuffer

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov eax, [Hexagon.LibASM.PasswdHash.codeFound]

    hx.syscall hx.toString

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, Hexagon.LibASM.PasswdHash.shellFound

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], ':'

    inc edi

    mov esi, Hexagon.LibASM.PasswdHash.themeFound

    call Hexagon.LibASM.PasswdHash.appendString

    mov byte[edi], 0

    mov esi, targetUser
    mov edi, replacementLine

    call Hexagon.LibASM.PasswdHash.rewriteUser

    jc .writeError

    fputs passwd.success

    jmp finish

.userNotFound:

    fputs passwd.userNotFound

    jmp finish

.wrongCurrent:

    fputs passwd.wrongCurrent

    jmp finish

.mismatch:

    fputs passwd.mismatch

    jmp finish

.writeError:

    fputs passwd.writeError

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs passwd.use

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

VERSION equ "0.1.1"

passwd:

.use:
db 10, "Usage: passwd [user]", 10, 10
db "With no argument, changes your own password (your current password is", 10
db "required). Root can pass a username to change someone else's password", 10
db "without knowing their current one.", 10, 10
db "passwd version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.permissionDenied:
db 10, "Only an administrative (or root) user can change another user's password.", 0
.userNotFound:
db 10, "That user was not found.", 0
.promptCurrent:
db 10, "Current password: ", 0
.wrongCurrent:
db 10, "Wrong current password.", 0
.promptNew:
db 10, "New password: ", 0
.promptNewAgain:
db 10, "Repeat new password: ", 0
.mismatch:
db 10, "The passwords entered do not match.", 0
.writeError:
db 10, "Could not write /shadow. The password was not changed.", 0
.success:
db 10, "Password changed.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0

parameters: dd ?
targetUser:
times 17 db 0
newPasswordFirst:
times 65 db 0
replacementLine:
times 96 db 0
