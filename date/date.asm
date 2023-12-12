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
;;                         Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, [parameters]

    mov edi, date.helpParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    mov edi, date.helpParameter2
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    putNewLine

    call processBCD ;; Convert BCD to printable character

    fputs date.day

    fputs date.espace

    fputs date.month

    fputs date.espace

    fputs date.hour

    fputs date.sepHour

    fputs date.minute

    fputs date.sepHour

    fputs date.second

    fputs date.espace

    fputs date.timezone

    fputs date.espace

    fputs date.century

    fputs date.year

match =SIM, DIASEMANA
{

;; Now let's check the day of the week

    mov eax, date.weekDay

    cmp byte[eax], '1'
    je .sunday

    cmp byte[eax], '2'
    je .monday

    cmp byte[eax], '3'
    je .tuesday

    cmp byte[eax], '4'
    je .wednesday

    cmp byte[eax], '5'
    je .thursday

    cmp byte[eax], '6'
    je .friday

    cmp byte[eax], '7'
    je .saturday

    jmp .unknown

.sunday:

    fputs date.sunday

    jmp .continue

.monday:

    fputs date.monday

    jmp .continue

.tuesday:

    fputs date.tuesday

    jmp .continue

.wednesday:

    fputs date.wednesday

    jmp .continue

.thursday:

    fputs date.thursday

    jmp .continue

.friday:

    fputs date.friday

    jmp .continue

.saturday:

    fputs date.saturday

    jmp .continue

.unknown:

}

.continue:

    jmp finish

;;************************************************************************************

processBCD:

;; First, let's request real-time clock information

;; Let's process the day

    hx.syscall hx.date

    call BCDToASCII

    mov word[date.day], ax
    mov byte[date.day+15], 0

;; Let's process the month

    hx.syscall hx.date

    mov eax, ebx

    call BCDToASCII

    mov word[date.month], ax
    mov byte[date.month+15], 0

;; Let's process the century (first two digits of the year)

    hx.syscall hx.date

    mov eax, ecx

    call BCDToASCII

    mov word[date.century], ax
    mov byte[date.century+15], 0

;; Let's process the year

    hx.syscall hx.date

    mov eax, edx

    call BCDToASCII

    mov word[date.year], ax
    mov byte[date.year+15], 0

;; Let's process the day of the week

    hx.syscall hx.date

    mov eax, esi

    call BCDToASCII

    mov word[date.weekDay], ax
    mov byte[date.weekDay+15], 0

;; Let's process the hour

    hx.syscall hx.time

    mov eax, eax

    call BCDToASCII

    mov word[date.hour], ax
    mov byte[date.hour+15], 0

;; Let's process the minutes

    hx.syscall hx.time

    mov eax, ebx

    call BCDToASCII

    mov word[date.minute], ax
    mov byte[date.minute+15], 0

;; Let's process the seconds

    hx.syscall hx.time

    mov eax, ecx

    call BCDToASCII

    mov word[date.second], ax
    mov byte[date.second+15], 0

    ret

;;************************************************************************************

;; Performs conversion from a BCD number to an ASCII character that can be displayed

BCDToASCII:

    mov ah, al
    and ax, 0xF00F ;; Mask bits
    shr ah, 4      ;; Shift right AH to get unwrapped BCD
    or ax, 0x3030  ;; Match 30 to get ASCII
    xchg ah, al    ;; Swap for ASCII convention

    ret

;;************************************************************************************

applicationUsage:

    fputs date.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall encerrarProcesso

;;************************************************************************************

VERSION equ "1.3.0"

date:

.use:
db 10, "Usage: date", 10, 10
db "Display system date and time.", 10, 10
db "date version ", VERSION, 10, 10
db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.sunday:
db " (Sunday)", 0
.monday:
db " (Monday)", 0
.tuesday:
db " (Tuesday)", 0
.wednesday:
db " (Wednesday)", 0
.thursday:
db " (Thursday)", 0
.friday:
db " (Friday)", 0
.saturday:
db " (Saturday)", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.setDate:
db "/", 0
.sepHour:
db ":", 0
.spacing:
db " of ", 0
.espace:
db " ", 0
.timezone:
db "GMT", 0
.day:     dd 0
.month:   dd 0
.century: dd 0
.year:    dd 0
.hour:    dd 0
.minute:  dd 0
.second:  dd 0
.weekDay: dd 0

parameters: dd ?
