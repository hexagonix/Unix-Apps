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
;;                          deluser utility for Hexagonix
;;
;;                 Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
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

    mov esi, [parameters]

    cmp byte[esi], 0
    je withoutParameter

    mov edi, deluser.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, deluser.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    hx.syscall hx.getUser

    cmp eax, 777
    je .isRoot

    fputs deluser.permissionDenied

    jmp finish

.isRoot:

    mov edi, deluser.rootUser
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc .cannotRemoveRoot

    mov esi, [parameters]

    call Hexagon.LibASM.PasswdHash.findUser

    jc .userNotFound

    putNewLine

    fputs deluser.confirmation

.getConfirmationKeys:

    hx.syscall hx.waitKeyboard

    cmp al, 'y'
    je .confirmed

    cmp al, 'Y'
    je .confirmed

    cmp al, 'n'
    je .cancelled

    cmp al, 'N'
    je .cancelled

    jmp .getConfirmationKeys

.confirmed:

    hx.syscall hx.printCharacter

    mov esi, [parameters]
    mov edi, 0

    call Hexagon.LibASM.PasswdHash.rewriteUser

    jc .writeError

    fputs deluser.success

    jmp finish

.cancelled:

    hx.syscall hx.printCharacter

    fputs deluser.cancel

    jmp finish

.cannotRemoveRoot:

    fputs deluser.cannotRemoveRoot

    jmp finish

.userNotFound:

    fputs deluser.userNotFound

    jmp finish

.writeError:

    fputs deluser.writeError

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs deluser.use

    jmp finish

;;************************************************************************************

withoutParameter:

    fputs deluser.withoutParameter

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

deluser:

.use:
db 10, "Usage: deluser [user]", 10, 10
db "Removes a user account.", 10, 10
db "deluser version ", VERSION, 10, 10
db "Copyright (C) 2015-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.permissionDenied:
db 10, "Only an administrative (or root) user can complete this action.", 10
db "Login in this user to perform the desired operation.", 0
.cannotRemoveRoot:
db 10, "The root user cannot be removed.", 0
.userNotFound:
db 10, "That user was not found.", 0
.confirmation:
db "Are you sure you want to delete this user (y/N)? ", 0
.cancel:
db 10, "The operation was aborted by the user.", 0
.success:
db 10, "User removed.", 0
.writeError:
db 10, "Could not write /shadow. No user was removed.", 0
.withoutParameter:
db 10, "A username is required.", 10
db "Use 'deluser ?' for help with this utility.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.rootUser:
db "root", 0

parameters: dd ?
