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

use32

;; Now let's create a HAPP header for the application

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Instance | Structure | Architecture | Version | Subversion | Entry Point | Image type
appHeader headerHAPP HAPP.Architectures.i386, 1, 5, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

;; Prints the current time in the top-right corner of the console once a
;; second, saving and restoring the caller's cursor position around it so it
;; can safely run alongside an interactive shell. Meant to be launched with
;; "clock &" and stopped with "kill <pid>", it never exits on its own

applicationStart:

    mov [parameters], edi

    mov edi, clock.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, clock.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    hx.syscall hx.getConsoleInfo

    mov al, bl
    sub al, 9 ;; "HH:MM:SS" is 8 characters, plus 1 column of padding

    mov byte[clock.cornerColumn], al

.loop:

    hx.syscall hx.getCursor

    mov byte[clock.savedX], dl
    mov byte[clock.savedY], dh

    gotoxy [clock.cornerColumn], 0

    hx.syscall hx.time ;; EAX = hour, EBX = minute, ECX = second, all BCD

    call BCDToASCII

    mov word[clock.hour], ax

    mov eax, ebx

    call BCDToASCII

    mov word[clock.minute], ax

    mov eax, ecx

    call BCDToASCII

    mov word[clock.second], ax

    fputs clock.hour
    fputs clock.sepHour
    fputs clock.minute
    fputs clock.sepHour
    fputs clock.second

    gotoxy [clock.savedX], [clock.savedY]

    mov ecx, 100 ;; ~1 second, at the kernel's 100 Hz timer rate

    hx.syscall hx.sleep

    jmp .loop

;;************************************************************************************

applicationUsage:

    fputs clock.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;; Performs conversion from a BCD number to an ASCII character pair that can be displayed
;;
;; Input:
;;
;; AL - BCD value
;;
;; Output:
;;
;; AX - ASCII character pair

BCDToASCII:

    mov ah, al

    and ax, 0xF00F ;; Mask bits

    shr ah, 4      ;; Shift right AH to get unwrapped BCD

    or ax, 0x3030  ;; Match 30 to get ASCII

    xchg ah, al    ;; Swap for ASCII convention

    ret

;;************************************************************************************

VERSION equ "0.2.1"

clock:

.use:
db 10, "Usage: clock", 10, 10
db "Show the current time in the top-right corner of the console, refreshed", 10
db "every second, until terminated. Meant to be run in the background, using", 10
db "'clock &', and stopped with kill.", 10, 10
db "clock version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.sepHour:
db ":", 0

.cornerColumn: db 0
.savedX:       db 0
.savedY:       db 0
.hour:         db 0, 0, 0
.minute:       db 0, 0, 0
.second:       db 0, 0, 0

parameters: dd ?
