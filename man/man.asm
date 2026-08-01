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

VERSION equ "3.0.2"

CoreUtilsVersion equ "Dormin-1.1"
UnixUtilsVersion equ "Dormin-1.1"

manBarColor     = AZUL_CALMANTE
manBarFontColor = HEXAGONIX_CLASSICO_BRANCO

man:

.helpParameter:
db "?", 0
.helpParameter2:
db "--help",0
.use:
db 10, "Usage: man [utility]", 10, 10
db "Display detailed help for installed Unix utilities.", 10, 10
db "CoreUtils version: ", CoreUtilsVersion, 10
db "UnixUtils Version: ", UnixUtilsVersion, 10, 10
db "man version ", VERSION, 10, 10
db "Copyright (C) 2018-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 10
db "Hexagonix is distributed under the BSD-3-Clause license.", 0
.waitKeyPress:
db "Press <q> to exit.", 0
.manNotFound:
db ": manual not found for this utility.", 0
.manFileExtension:
db ".man", 0
.morePrompt:
db "-- More -- (press any key to continue, <q> to quit)", 0
.endPrompt:
db "(END) (press <q> to quit)", 0
.systemName:
db "Hexagonix", 0

utility:              dd ?
nameLength:           db 0 ;; Length of the utility name, before ".man" is appended to it
pageSize:             db 0 ;; Content lines per screen, computed from the console info
lineCount:            db 0 ;; Content lines printed on the current page so far
readPos:              dd ? ;; Where the next page starts reading from in appFileBuffer
numberColumns:        db 0
savedFontColor:       dd 0
savedBackgroundColor: dd 0

;;************************************************************************************

applicationStart:

    mov [utility], edi

    cmp byte[edi], 0
    je applicationUsage

    mov edi, man.helpParameter
    mov esi, [utility]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, man.helpParameter2
    mov esi, [utility]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [utility]

    hx.syscall hx.stringSize

    mov ebx, eax

    mov byte[nameLength], bl

    mov al, byte[man.manFileExtension+0]

    mov byte[esi+ebx+0], al

    mov al, byte[man.manFileExtension+1]

    mov byte[esi+ebx+1], al

    mov al, byte[man.manFileExtension+2]

    mov byte[esi+ebx+2], al

    mov al, byte[man.manFileExtension+3]

    mov byte[esi+ebx+3], al

    mov byte[esi+ebx+4], 0 ;; End of string

    hx.syscall hx.fileExists

    jc manNotFound

    mov edi, appFileBuffer

    mov esi, [utility]

    hx.syscall hx.open

    jc manNotFound

;; The file has been located and opened, "utility" is no longer needed with
;; the ".man" extension appended to it, so strip it back to just the plain
;; name for display

    mov esi, [utility]

    movzx ecx, byte[nameLength]

    mov byte[esi+ecx], 0

;; Environment preparation

    call buildInterface

    mov esi, appFileBuffer

    call showPaginated

    jmp finish

;;************************************************************************************

buildInterface:

    hx.syscall hx.clearConsole

    hx.syscall hx.getConsoleInfo

    mov byte[numberColumns], bl

;; BH is the row count. Row 0 is the bar and the last row (BH - 1) is the
;; "-- More --"/"(END)" prompt, so content gets the rest

    mov al, bh
    sub al, 2

    mov byte[pageSize], al

    ret

;;************************************************************************************

;; Redraws the bar at row 0 without disturbing the rest of the screen,
;; restoring the cursor to wherever it was so content printing can continue
;; right where it left off. Used to keep the bar visible after a page turn
;; that scrolls rather than clears

refreshBar:

    hx.syscall hx.getCursor

    push edx

    call drawBar

    pop edx

    hx.syscall hx.setCursor

    ret

;;************************************************************************************

;; Draws the header bar on row 0: the system name on the left, the manual
;; name centered on top of it

drawBar:

    hx.syscall hx.getColor

    mov dword[savedFontColor], eax
    mov dword[savedBackgroundColor], ebx

    mov eax, manBarFontColor
    mov ebx, manBarColor

    hx.syscall hx.setColor

    mov al, 0

    hx.syscall hx.clearLine ;; Fills row 0 with the current background color

    gotoxy 0, 0

    fputs man.systemName

    mov esi, [utility]

    hx.syscall hx.stringSize

    mov ecx, eax

    movzx eax, byte[numberColumns]

    sub eax, ecx

    shr eax, 1 ;; (columns - name length) / 2, to center the name on the bar

    gotoxy al, 0

    fputs [utility]

    mov eax, dword[savedFontColor]
    mov ebx, dword[savedBackgroundColor]

    hx.syscall hx.setColor

    ret

;;************************************************************************************

;; Prints a NUL terminated buffer one page at a time, like a classic pager.
;; The console is only cleared once, by buildInterface, before this is ever
;; called. From then on, a page turn scrolls the existing content up (via a
;; newline printed from the bottom row) instead of clearing the screen, and
;; the bar is simply redrawn on top afterward. Pressing <q> or <Q> at a
;; pause stops early
;;
;; Input:
;;
;; ESI - Buffer to print

showPaginated:

    mov dword[readPos], esi ;; drawBar uses ESI internally, save this first

    call drawBar

    gotoxy 0, 1

.pageLoop:

    mov esi, dword[readPos]

    mov byte[lineCount], 0

.charLoop:

    lodsb

    cmp al, 0
    je .documentEnd

    hx.syscall hx.printCharacter

    cmp al, 10
    jne .charLoop

    inc byte[lineCount]

    mov al, byte[lineCount]

    cmp al, byte[pageSize]

    jb .charLoop

;; A full page has been printed. Remember where the next one continues from
;; before pausing, so pauseForKeyPress doesn't need to preserve ESI

    mov dword[readPos], esi

    call pauseForKeyPress

    jc .end ;; The user pressed <q> or <Q>

    putNewLine ;; Scrolls the screen up, since we are on the bottom row

    call refreshBar

    jmp .pageLoop ;; Reloads ESI from readPos at the top

.documentEnd:

    call waitForQuit

.end:

    ret

;;************************************************************************************

;; Shown once the manual body has been fully printed. Unlike
;; pauseForKeyPress, only <q> or <Q> is accepted here, so the manual stays
;; on screen until the user explicitly asks to leave it, like a real pager

waitForQuit:

    putNewLine

    fputs man.endPrompt

.waitLoop:

    hx.syscall hx.waitKeyboard

    cmp al, 'q'
    je .done

    cmp al, 'Q'
    je .done

    jmp .waitLoop

.done:

    ret

;;************************************************************************************

;; Shows the pager prompt on the current row and waits for a key. The
;; caller is responsible for scrolling past this line afterward, so there
;; is nothing to clean up here
;;
;; Output:
;;
;; CF - Set if the user pressed <q> or <Q> to stop early

pauseForKeyPress:

    fputs man.morePrompt

    hx.syscall hx.waitKeyboard

    cmp al, 'q'
    je .stop

    cmp al, 'Q'
    je .stop

    clc

    ret

.stop:

    stc

    ret

;;************************************************************************************

manNotFound:

    putNewLine

    fputs [utility]

    fputs man.manNotFound

    jmp finish

;;************************************************************************************

applicationUsage:

    fputs man.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;*****************************************************************************

appFileBuffer:
