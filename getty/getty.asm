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
;;                       Unix utility getty for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Architecture | Version | Subversion | Entry point | Image type | BSS size
headerHAPP HAPP.Architectures.i386, 1, 8, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "string.s"
include "log.s"

;;************************************************************************************

;; getty claims a VT for itself (hx.open on its own /dev/ttyN, then
;; hx.ioctl to make it that VT's own foreground owner), then blocks
;; running login on it. When login exits, getty exits too instead of
;; looping back to open/login again

applicationStart:

    mov [parameters], edi

    mov edi, getty.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, getty.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov esi, [parameters]

    cmp byte[esi], 0
    je applicationUsage

    call trimString

    call stringToInteger

    jc invalidVT

    cmp eax, 7
    ja invalidVT

    add al, '0' ;; EAX (0-7) = its own ASCII digit

    mov byte[getty.deviceName + 3], al ;; "ttyN", N filled in at runtime

    systemLog getty.verboseGetty, 0, Log.Priorities.p4

    mov esi, getty.deviceName

    xor ecx, ecx

    hx.syscall hx.open

    jc openFailed

;; Opening a tty is pure bookkeeping now. Claiming it as this process's own
;; VT is a separate, explicit step

    mov ebx, 3 ;; Claim the open tty as the caller's own VT
    
    xor ecx, ecx

    hx.syscall hx.ioctl

    mov eax, 0 ;; Do not pass arguments

    mov esi, getty.loginPath

    clc

    hx.syscall hx.exec ;; Blocks here until login exits

    jmp finish

;;************************************************************************************

openFailed:

    fputs getty.openError

    jmp finish

;;************************************************************************************

invalidVT:

    fputs getty.invalidVT

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs getty.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

VERSION equ "0.1.0"

getty:

.use:
db 10, "Usage: getty <vt>", 10, 10
db "Claims virtual terminal <vt> (0-7) as its own, then runs /sbin/login", 10
db "on it until login exits. Meant to be run once per VT from /etc/rc's", 10
db "own respawn= lines, not invoked directly.", 10, 10
db "getty version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.invalidVT:
db 10, "getty: invalid VT index.", 0
.openError:
db 10, "getty: could not claim this VT.", 0
.verboseGetty:
db "getty version ", VERSION, ".", 0
.deviceName:
db "tty0", 0
.loginPath:
db "/sbin/login", 0

parameters: dd ?
