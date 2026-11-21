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
;;                     Unix utility raava for Hexagonix
;;
;;                 Copyright (c) 2015-2026 Felipe Miguel Nery Lunkes
;;                              All rights reserved.
;;
;;************************************************************************************

use32

include "HAPP.s" ;; Here is a structure for the HAPP header

;; Architecture | Version | Subversion | Entry point | Image type | BSS size
headerHAPP HAPP.Architectures.i386, 1, 8, applicationStart, 01h, HAPP.bss.none

;;************************************************************************************

include "hexagon.s"
include "errors.s"
include "tty.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"
include "process.s"
include "term.s"

;;************************************************************************************

;; Raava shows terminals in windows on a VT of its own. Each window is a shell on
;; a pty, with Raava on the manager, and its terminal kept by term.s. The screen
;; is composed as a grid of cells from the bottom window up, and only the cells
;; that changed since the last time are written to the VT

Raava.maxWindows = 8
Raava.savedFD    = 15 ;; The terminal's copy while 0, 1 and 2 are lent to a shell
Raava.readSize   = 1024
Raava.outputSize = 65536
Raava.commandKey = 01h ;; Ctrl+A, as in screen

;; One window. Its size is the size of its terminal, inside the border

Raava.Window.used    = 0  ;; Byte
Raava.Window.number  = 1  ;; Byte, shown in the title, from 1
Raava.Window.manager = 4
Raava.Window.pid     = 8
Raava.Window.x       = 12 ;; Of the border, in cells
Raava.Window.y       = 16
Raava.Window.width   = 20
Raava.Window.height  = 24
Raava.Window.term    = 28
Raava.Window.size    = Raava.Window.term + Lib.Term.size

;;************************************************************************************

applicationStart:

    push ds
    pop es

    mov [parameters], edi

    mov edi, raava.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, raava.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

;; The colors of the theme, read while still on the VT Raava came from

    hx.syscall hx.getColor

    mov [themeFont], eax
    mov [themeBackground], ebx

    hx.syscall hx.getTTY

    mov [originalVT], eax

    call claimFreeVT

    jc noFreeVT

    ttyGetSize

    mov [columns], eax
    mov [rows], ebx

    mul ebx

    imul ebx, eax, Lib.Term.Cell.size

    mov [screenBytes], ebx

    call malloc

    cmp eax, 0

    je noMemory

    mov [screen], ebx

    mov ebx, [screenBytes]

    call malloc

    cmp eax, 0

    je noMemory

    mov [previous], ebx

    mov ebx, Raava.outputSize

    call malloc

    cmp eax, 0

    je noMemory

    mov [output], ebx

;; Nothing drawn yet, so every cell differs from what is on the VT

    mov edi, [previous]
    mov ecx, [screenBytes]
    xor eax, eax

    cld

    rep stosb

    ttyGetMode

    mov [savedMode], eax

;; Every key as it comes, Ctrl+C included, for the window in focus to get it

    ttySetMode 0

    hx.setNonBlocking 0, 1

    call Lib.Console.clear

    call newWindow

    cmp dword[windowCount], 0

    je finishSession

    mov byte[redraw], 1

;;************************************************************************************

mainLoop:

    mov byte[activity], 0

    call readWindows

    call readKeys

    cmp byte[quit], 0

    jne finishSession

    cmp dword[windowCount], 0

    je finishSession

    cmp byte[redraw], 0

    je .drawn

    call compose
    call render

    mov byte[redraw], 0

.drawn:

    cmp byte[activity], 0

    jne mainLoop

    mov ecx, 1

    hx.syscall hx.sleep ;; Nothing happened, the processor goes to someone else

    jmp mainLoop

;;************************************************************************************

;; Takes what each shell wrote. A manager read as the end of the file is a
;; shell that is gone, and its window closes

readWindows:

    pushad

    xor ebx, ebx

.nextWindow:

    cmp ebx, Raava.maxWindows

    jae .done

    imul ebp, ebx, Raava.Window.size
    add ebp, windows

    cmp byte[ebp + Raava.Window.used], 0

    je .skip

    mov eax, dword[ebp + Raava.Window.manager]
    mov edi, readBuffer
    mov ecx, Raava.readSize

    push ebx
    push ebp

    hx.syscall hx.read

    pop ebp
    pop ebx

    jc .skip ;; Nothing yet

    cmp eax, 0

    je .ended

    mov ecx, eax
    mov esi, readBuffer
    lea edi, [ebp + Raava.Window.term]

    call termWrite

    mov byte[activity], 1
    mov byte[redraw], 1

    jmp .skip

.ended:

    mov eax, ebx
    xor ecx, ecx ;; The shell is gone already

    call closeWindow

    mov byte[activity], 1

.skip:

    inc ebx

    jmp .nextWindow

.done:

    popad

    ret

;;************************************************************************************

;; Takes the keys typed. Ctrl+A starts a command of Raava, anything else goes
;; to the window in focus

readKeys:

    pushad

    mov eax, 0
    mov edi, keyBuffer
    mov ecx, 64

    hx.syscall hx.read

    jc .done

    cmp eax, 0

    je .done

    mov byte[activity], 1

    mov ecx, eax
    mov esi, keyBuffer

.nextKey:

    mov al, byte[esi]

    cmp byte[commandPending], 0

    jne .command

    cmp al, Raava.commandKey

    jne .toWindow

    mov byte[commandPending], 1

    jmp .next

.toWindow:

    call sendToFocused

    jmp .next

.command:

    mov byte[commandPending], 0

    call runCommand

.next:

    inc esi

    loop .nextKey

.done:

    popad

    ret

;; Input: AL - Letter after Ctrl+A

runCommand:

    pushad

    cmp al, 'c'

    je .new

    cmp al, 'n'

    je .next

    cmp al, 'x'

    je .close

    cmp al, 'q'

    je .quit

    cmp al, Raava.commandKey

    jne .done

    call sendToFocused ;; Ctrl+A twice is one Ctrl+A for the window

    jmp .done

.new:

    call newWindow

    jmp .done

.next:

    call focusNext

    jmp .done

.close:

    cmp dword[orderCount], 0

    je .done

    mov ebx, [orderCount]
    movzx eax, byte[order + ebx - 1]
    mov ecx, 1 ;; Its shell still runs

    call closeWindow

    jmp .done

.quit:

    mov byte[quit], 1

.done:

    popad

    ret

;; Input: AL - Byte for the shell in focus

sendToFocused:

    pushad

    cmp dword[orderCount], 0

    je .done

    mov byte[sendByte], al

    mov ebx, [orderCount]
    movzx ebx, byte[order + ebx - 1]

    imul ebp, ebx, Raava.Window.size
    add ebp, windows

    mov eax, dword[ebp + Raava.Window.manager]
    mov esi, sendByte
    mov ecx, 1

    hx.syscall hx.write ;; A full ring drops the key, as nobody reads it anyway

.done:

    popad

    ret

;; The window at the bottom comes to the top, so repeating it goes through them all

focusNext:

    pushad

    mov ecx, [orderCount]

    cmp ecx, 2

    jb .done

    mov al, byte[order]

    mov edi, order
    lea esi, [order + 1]

    dec ecx

    cld

    rep movsb

    mov byte[edi], al

    mov byte[redraw], 1

.done:

    popad

    ret

;;************************************************************************************

;; Opens a window with a shell in it, over the others and in focus

newWindow:

    pushad

    xor ebx, ebx

.findSlot:

    cmp ebx, Raava.maxWindows

    jae .done ;; Every window in use

    imul ebp, ebx, Raava.Window.size
    add ebp, windows

    cmp byte[ebp + Raava.Window.used], 0

    je .slotFound

    inc ebx

    jmp .findSlot

.slotFound:

    mov [slot], ebx

    call openPair

    jc .done

    mov eax, [pairManager]
    mov dword[ebp + Raava.Window.manager], eax

;; Three quarters of the VT wide, for ps and top to fit, and two thirds high,
;; each new one a little lower and to the right

    mov eax, [columns]
    imul eax, eax, 3
    shr eax, 2

    mov dword[ebp + Raava.Window.width], eax

    mov eax, [rows]
    shl eax, 1
    xor edx, edx
    mov ecx, 3
    div ecx

    mov dword[ebp + Raava.Window.height], eax

    mov eax, [windowCount]
    shl eax, 1
    add eax, 2

    mov dword[ebp + Raava.Window.x], eax

    mov eax, [windowCount]
    add eax, 2 ;; Under the status bar

    mov dword[ebp + Raava.Window.y], eax

    call fitWindow

    lea edi, [ebp + Raava.Window.term]
    mov eax, dword[ebp + Raava.Window.width]
    mov ebx, dword[ebp + Raava.Window.height]
    mov ecx, [themeFont]
    mov edx, [themeBackground]

    call termInit

    jc .noTerminal

;; The shell sees the size of its window

    mov eax, dword[ebp + Raava.Window.manager]
    mov ebx, 7
    mov ecx, dword[ebp + Raava.Window.width]
    mov edx, dword[ebp + Raava.Window.height]

    hx.syscall hx.ioctl

    hx.setNonBlocking dword[ebp + Raava.Window.manager], 1
    hx.setCloseOnSpawn dword[ebp + Raava.Window.manager], 1

    call startShell

    jc .noShell

    mov eax, [shellPID]
    mov dword[ebp + Raava.Window.pid], eax

    mov eax, [slot]
    inc eax

    mov byte[ebp + Raava.Window.number], al
    mov byte[ebp + Raava.Window.used], 1

    mov eax, [orderCount]
    mov ebx, [slot]
    mov byte[order + eax], bl

    inc dword[orderCount]
    inc dword[windowCount]

    mov byte[redraw], 1

    jmp .done

.noShell:

    lea edi, [ebp + Raava.Window.term]

    call termFree

    jmp .closeManager

.noTerminal:

    mov eax, [pairSubsidiary]

    hx.syscall hx.close

.closeManager:

    mov eax, dword[ebp + Raava.Window.manager]

    hx.syscall hx.close

.done:

    popad

    ret

;; Keeps a window with its border inside the VT, under the status bar
;;
;; Input: EBP - Window

fitWindow:

    pushad

    mov eax, [columns]
    sub eax, 2 ;; The border

    cmp dword[ebp + Raava.Window.width], eax

    jbe .widthFits

    mov dword[ebp + Raava.Window.width], eax

.widthFits:

    mov eax, [rows]
    sub eax, 3 ;; The border and the status bar

    cmp dword[ebp + Raava.Window.height], eax

    jbe .heightFits

    mov dword[ebp + Raava.Window.height], eax

.heightFits:

    mov eax, [columns]
    sub eax, dword[ebp + Raava.Window.width]
    sub eax, 2 ;; Last column the border can start at

    cmp dword[ebp + Raava.Window.x], eax

    jbe .xFits

    mov dword[ebp + Raava.Window.x], eax

.xFits:

    mov eax, [rows]
    sub eax, dword[ebp + Raava.Window.height]
    sub eax, 2

    cmp dword[ebp + Raava.Window.y], eax

    jbe .yFits

    mov dword[ebp + Raava.Window.y], eax

.yFits:

    popad

    ret

;; Opens the first free pair, its manager and then its subsidiary
;;
;; Output:
;;
;; CF set if every pair is in use

openPair:

    pushad

    mov byte[pairDigit], '0'

.tryPair:

    mov al, byte[pairDigit]

    mov byte[raava.manager + 4], al
    mov byte[raava.subsidiary + 4], al

    mov esi, raava.manager

    xor ecx, ecx

    hx.syscall hx.open

    jnc .managerOpened

    inc byte[pairDigit]

    cmp byte[pairDigit], '7'

    jbe .tryPair

    popad

    stc

    ret

.managerOpened:

    mov [pairManager], eax

    mov esi, raava.subsidiary

    xor ecx, ecx

    hx.syscall hx.open

    jc .noSubsidiary

    mov [pairSubsidiary], eax

    popad

    clc

    ret

.noSubsidiary:

    mov eax, [pairManager]

    hx.syscall hx.close

    popad

    stc

    ret

;; Starts a shell with 0, 1 and 2 on the subsidiary just opened. They are
;; pointed there only for the spawn, which copies them into the shell, and then
;; put back. The managers and the terminal's copy are kept from the shell
;;
;; Output:
;;
;; CF set if the shell could not be started

startShell:

    pushad

    mov eax, 0
    mov ebx, Raava.savedFD

    hx.syscall hx.dup2

    hx.setCloseOnSpawn Raava.savedFD, 1

    xor ebx, ebx

.toSubsidiary:

    push ebx

    mov eax, [pairSubsidiary]

    hx.syscall hx.dup2

    pop ebx

    inc ebx

    cmp ebx, 3

    jb .toSubsidiary

    mov eax, [pairSubsidiary]

    hx.syscall hx.close

    mov esi, raava.shell
    xor eax, eax

    hx.syscall hx.spawn

    mov [shellPID], eax

    setc byte[spawnFailed]

    xor ebx, ebx

.toTerminal:

    push ebx

    mov eax, Raava.savedFD

    hx.syscall hx.dup2

    pop ebx

    inc ebx

    cmp ebx, 3

    jb .toTerminal

    mov eax, Raava.savedFD

    hx.syscall hx.close

    hx.setNonBlocking 0, 1 ;; A copy carries no flags

    cmp byte[spawnFailed], 0

    jne .failed

    popad

    clc

    ret

.failed:

    popad

    stc

    ret

;; Closes a window and the pty under it
;;
;; Input:
;;
;; EAX - Window index
;; ECX - 1 to end its shell, which still runs, 0 if it is gone already

closeWindow:

    pushad

    imul ebp, eax, Raava.Window.size
    add ebp, windows

    mov edx, eax ;; The index

    push ecx

    mov eax, dword[ebp + Raava.Window.manager]

    hx.syscall hx.close

    pop ecx

    cmp ecx, 0

    je .shellGone

    mov ebx, dword[ebp + Raava.Window.pid]

    push edx

    hx.syscall hx.kill

    pop edx

.shellGone:

    lea edi, [ebp + Raava.Window.term]

    call termFree

    mov byte[ebp + Raava.Window.used], 0

    dec dword[windowCount]

;; Out of the order, the ones above it moving down one

    xor ecx, ecx

.find:

    cmp ecx, [orderCount]

    jae .removed

    cmp byte[order + ecx], dl

    je .remove

    inc ecx

    jmp .find

.remove:

    mov al, byte[order + ecx + 1]
    mov byte[order + ecx], al

    inc ecx

    cmp ecx, [orderCount]

    jb .remove

    dec dword[orderCount]

.removed:

    mov byte[redraw], 1

    popad

    ret

;;************************************************************************************

;; Finds a VT with no process on it, from tty2 on, claims it and shows it. The
;; clock and the logins stay on theirs
;;
;; Output:
;;
;; CF set if there is none

claimFreeVT:

    pushad

    mov ebx, 4096

    call malloc

    cmp eax, 0

    je .none

    mov [processes], ebx

    mov esi, ebx
    mov ecx, 4096

    hx.syscall hx.getProcesses ;; EAX = records

    jc .none

    mov [processCount], eax

    mov edx, 2 ;; VT being tried

.tryVT:

    cmp edx, 7

    ja .none

    cmp edx, [originalVT]

    je .busy

    mov esi, [processes]
    mov ebx, dword[esi] ;; Record size
    add esi, 4

    mov ecx, [processCount]

.checkRecord:

    jecxz .free

    movzx eax, byte[esi + hx.process.record.tty]

    cmp eax, edx

    je .busy

    add esi, ebx

    dec ecx

    jmp .checkRecord

.busy:

    inc edx

    jmp .tryVT

.free:

    mov [ownVT], edx

    mov eax, edx

    call openVT ;; EAX = descriptor

    jc .none

    push eax

    mov ebx, 3 ;; Claimed as Raava's own, 0, 1 and 2 following it

    hx.syscall hx.ioctl

    mov eax, dword[esp]
    mov ebx, 2 ;; Shown

    hx.syscall hx.ioctl

    pop eax

    hx.syscall hx.close

    popad

    clc

    ret

.none:

    popad

    stc

    ret

;; Input: EAX - VT index. Output: EAX - Descriptor of it, CF set on error

openVT:

    add al, '0'

    mov byte[raava.vt + 3], al

    mov esi, raava.vt
    xor ecx, ecx

    hx.syscall hx.open

    ret

;;************************************************************************************

;; Builds the screen as cells: the background, the status bar, then each window
;; from the bottom up, the one in focus last

compose:

    pushad

    mov edi, [screen]
    mov ecx, [columns]
    imul ecx, [rows]

.background:

    mov byte[edi + Lib.Term.Cell.character], ' '

    mov eax, [themeFont]
    mov dword[edi + Lib.Term.Cell.font], eax

    mov eax, [themeBackground]
    mov dword[edi + Lib.Term.Cell.background], eax

    add edi, Lib.Term.Cell.size

    loop .background

;; The status bar, in the colors of the theme swapped

    mov eax, [themeBackground]
    mov [putFont], eax

    mov eax, [themeFont]
    mov [putBackground], eax

    xor eax, eax ;; Column
    xor edx, edx ;; Row
    mov esi, raava.statusBar

.statusText:

    mov bl, byte[esi]

    cmp bl, 0

    je .statusPad

    call putCell

    inc esi
    inc eax

    jmp .statusText

.statusPad:

    cmp eax, [columns]

    jae .windows

    mov bl, ' '

    call putCell

    inc eax

    jmp .statusPad

.windows:

    xor ecx, ecx

.nextWindow:

    cmp ecx, [orderCount]

    jae .done

    movzx ebx, byte[order + ecx]

    imul ebp, ebx, Raava.Window.size
    add ebp, windows

    mov eax, [orderCount]
    dec eax

    cmp ecx, eax

    sete al ;; The last one is in focus

    call drawWindow

    inc ecx

    jmp .nextWindow

.done:

    popad

    ret

;; Input: EBP - Window, AL - 1 if it is in focus

drawWindow:

    pushad

;; The border of the window in focus is in the colors of the theme swapped

    mov ebx, [themeFont]
    mov ecx, [themeBackground]

    cmp al, 0

    je .colorsChosen

    xchg ebx, ecx

.colorsChosen:

    mov [putFont], ebx
    mov [putBackground], ecx

    mov eax, dword[ebp + Raava.Window.x]
    mov edx, dword[ebp + Raava.Window.y]

    call borderRow

    add edx, dword[ebp + Raava.Window.height]
    inc edx

    call borderRow

;; The sides

    mov edx, dword[ebp + Raava.Window.y]
    mov ecx, dword[ebp + Raava.Window.height]

.side:

    inc edx

    mov eax, dword[ebp + Raava.Window.x]
    mov bl, '|'

    call putCell

    add eax, dword[ebp + Raava.Window.width]
    inc eax

    call putCell

    loop .side

;; The title, over the top border

    movzx eax, byte[ebp + Raava.Window.number]
    add al, '0'

    mov byte[raava.title + 2], al

    mov eax, dword[ebp + Raava.Window.x]
    add eax, 2
    mov edx, dword[ebp + Raava.Window.y]
    mov esi, raava.title

.title:

    mov bl, byte[esi]

    cmp bl, 0

    je .inside

    call putCell

    inc esi
    inc eax

    jmp .title

;; The cells of its terminal

.inside:

    mov esi, dword[ebp + Raava.Window.term + Lib.Term.cells]

    xor edx, edx ;; Row of the terminal

.insideRow:

    cmp edx, dword[ebp + Raava.Window.height]

    jae .done

    xor eax, eax ;; Column of the terminal

.insideCell:

    cmp eax, dword[ebp + Raava.Window.width]

    jae .insideNextRow

    mov ebx, dword[esi + Lib.Term.Cell.font]
    mov [putFont], ebx

    mov ebx, dword[esi + Lib.Term.Cell.background]
    mov [putBackground], ebx

    mov bl, byte[esi + Lib.Term.Cell.character]

    push eax
    push edx

    add eax, dword[ebp + Raava.Window.x]
    inc eax

    add edx, dword[ebp + Raava.Window.y]
    inc edx

    call putCell

    pop edx
    pop eax

    add esi, Lib.Term.Cell.size

    inc eax

    jmp .insideCell

.insideNextRow:

    inc edx

    jmp .insideRow

.done:

    popad

    ret

;; A top or bottom border: corners and a line between them
;;
;; Input: EAX - Column of the window, EDX - Row, EBP - Window

borderRow:

    pushad

    mov bl, '+'

    call putCell

    mov ecx, dword[ebp + Raava.Window.width]
    mov bl, '-'

.line:

    inc eax

    call putCell

    loop .line

    inc eax
    mov bl, '+'

    call putCell

    popad

    ret

;; Puts a cell on the screen in putFont and putBackground, leaving out what
;; falls outside it. Every register is preserved
;;
;; Input: EAX - Column, EDX - Row, BL - Character

putCell:

    pushad

    cmp eax, [columns]

    jae .outside

    cmp edx, [rows]

    jae .outside

    push eax

    mov eax, edx

    mul dword[columns]

    pop edx

    add eax, edx

    imul edi, eax, Lib.Term.Cell.size

    add edi, [screen]

    mov byte[edi + Lib.Term.Cell.character], bl

    mov eax, [putFont]
    mov dword[edi + Lib.Term.Cell.font], eax

    mov eax, [putBackground]
    mov dword[edi + Lib.Term.Cell.background], eax

.outside:

    popad

    ret

;;************************************************************************************

;; Writes to the VT only the cells that differ from what is on it, moving there
;; when they do not follow each other, then leaves the cursor where the window
;; in focus has it

render:

    pushad

    mov edi, [output]

    mov dword[lastFont], -1
    mov dword[lastBackground], -1
    mov dword[expected], -1

    mov esi, [screen]
    mov ebp, [previous]

    xor edx, edx ;; Row

.row:

    cmp edx, [rows]

    jae .cursor

    xor ecx, ecx ;; Column

.cell:

    cmp ecx, [columns]

    jae .nextRow

    mov al, byte[esi + Lib.Term.Cell.character]

    cmp al, byte[ebp + Lib.Term.Cell.character]

    jne .changed

    mov eax, dword[esi + Lib.Term.Cell.font]

    cmp eax, dword[ebp + Lib.Term.Cell.font]

    jne .changed

    mov eax, dword[esi + Lib.Term.Cell.background]

    cmp eax, dword[ebp + Lib.Term.Cell.background]

    je .nextCell

.changed:

    call flushIfFull

;; Where the VT's cursor already is when it follows the last cell written

    mov eax, edx

    imul eax, [columns] ;; Not mul, which would take EDX, the row

    add eax, ecx

    cmp eax, [expected]

    je .positioned

    push eax

    mov eax, edx
    mov ebx, ecx

    call appendPosition

    pop eax

.positioned:

    inc eax

    mov [expected], eax

;; Past the last column the VT waits to go to the next line, so the next cell
;; is always positioned

    lea ebx, [ecx + 1]

    cmp ebx, [columns]

    jb .colors

    mov dword[expected], -1

.colors:

    mov eax, dword[esi + Lib.Term.Cell.font]

    cmp eax, [lastFont]

    je .fontSame

    mov [lastFont], eax
    mov bl, '3'

    call appendColor

.fontSame:

    mov eax, dword[esi + Lib.Term.Cell.background]

    cmp eax, [lastBackground]

    je .backgroundSame

    mov [lastBackground], eax
    mov bl, '4'

    call appendColor

.backgroundSame:

    mov al, byte[esi + Lib.Term.Cell.character]
    mov byte[edi], al

    inc edi

;; What is on the VT now

    mov byte[ebp + Lib.Term.Cell.character], al

    mov eax, dword[esi + Lib.Term.Cell.font]
    mov dword[ebp + Lib.Term.Cell.font], eax

    mov eax, dword[esi + Lib.Term.Cell.background]
    mov dword[ebp + Lib.Term.Cell.background], eax

.nextCell:

    add esi, Lib.Term.Cell.size
    add ebp, Lib.Term.Cell.size

    inc ecx

    jmp .cell

.nextRow:

    inc edx

    jmp .row

;; The cursor of the window in focus, on its last column when it waits past it

.cursor:

    cmp dword[orderCount], 0

    je .write

    mov ebx, [orderCount]
    movzx ebx, byte[order + ebx - 1]

    imul ebp, ebx, Raava.Window.size
    add ebp, windows

    mov ebx, dword[ebp + Raava.Window.term + Lib.Term.x]
    mov eax, dword[ebp + Raava.Window.width]

    dec eax

    cmp ebx, eax

    jbe .xInside

    mov ebx, eax

.xInside:

    add ebx, dword[ebp + Raava.Window.x]
    inc ebx

    mov eax, dword[ebp + Raava.Window.term + Lib.Term.y]
    add eax, dword[ebp + Raava.Window.y]
    inc eax

    call appendPosition

.write:

    call flush

    popad

    ret

;; Input: EAX - Row, EBX - Column, both from 0, EDI - Where it goes. Output: EDI past it

appendPosition:

    push eax

    mov byte[edi], 27
    mov byte[edi + 1], '['

    add edi, 2

    inc eax

    call Lib.Console.appendDecimal

    mov byte[edi], ';'

    inc edi

    lea eax, [ebx + 1]

    call Lib.Console.appendDecimal

    mov byte[edi], 'H'

    inc edi

    pop eax

    ret

;; ESC [ c 8 ; 2 ; r ; g ; b m
;;
;; Input: EAX - Color, BL - '3' for the font, '4' for the background, EDI - Where it goes

appendColor:

    push eax
    push edx

    mov edx, eax

    mov byte[edi], 27
    mov byte[edi + 1], '['
    mov byte[edi + 2], bl
    mov byte[edi + 3], '8'
    mov byte[edi + 4], ';'
    mov byte[edi + 5], '2'

    add edi, 6

    mov eax, edx
    shr eax, 16

    call .channel

    mov eax, edx
    shr eax, 8

    call .channel

    mov eax, edx

    call .channel

    mov byte[edi], 'm'

    inc edi

    pop edx
    pop eax

    ret

.channel:

    mov byte[edi], ';'

    inc edi

    and eax, 0FFh

    call Lib.Console.appendDecimal

    ret

;; Writes what was gathered when little room is left for the next cell

flushIfFull:

    push eax

    mov eax, edi
    sub eax, [output]

    cmp eax, Raava.outputSize - 128

    jb .room

    call flush

.room:

    pop eax

    ret

;; Writes what was gathered, from [output] to EDI. Output: EDI - [output]

flush:

    pushad

    mov esi, [output]
    mov ecx, edi
    sub ecx, esi

    jecxz .done

    mov eax, 1

    hx.syscall hx.write

.done:

    popad

    mov edi, [output]

    ret

;;************************************************************************************

finishSession:

    xor eax, eax

.closeNext:

    cmp eax, Raava.maxWindows

    jae .closed

    imul ebp, eax, Raava.Window.size
    add ebp, windows

    cmp byte[ebp + Raava.Window.used], 0

    je .skip

    mov ecx, 1

    call closeWindow

.skip:

    inc eax

    jmp .closeNext

.closed:

    hx.setNonBlocking 0, 0

    ttySetMode [savedMode]

    fputs raava.resetColor

    call Lib.Console.clear

;; Back to the VT Raava came from. Its own is left with no foreground when it ends

    mov eax, [originalVT]

    call openVT

    jc finish

    push eax

    mov ebx, 2

    hx.syscall hx.ioctl

    pop eax

    hx.syscall hx.close

    jmp finish

noFreeVT:

    fputs raava.noFreeVT

    jmp finish

noMemory:

    fputs raava.noMemory

    jmp finish

applicationUsage:

    fputs raava.use

    jmp finish

finish:

    hx.syscall hx.exit

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.1.0"

raava:

.use:
db 10, "Usage: raava", 10, 10
db "Shows shells in windows on a virtual terminal of its own. Ctrl+A then", 10
db "c opens a window, n goes to the next one, x closes it and q leaves.", 10
db "Ctrl+A twice sends Ctrl+A to the window.", 10, 10
db "raava version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.noFreeVT:
db 10, "raava: no virtual terminal is free.", 0
.noMemory:
db 10, "raava: not enough memory.", 0
.statusBar:
db " Raava   Ctrl+A then: c new window, n next, x close, q quit", 0
.title:
db " [1] sh ", 0
.shell:
db "/bin/sh", 0
.manager:
db "ptyp0", 0
.subsidiary:
db "ttyp0", 0
.vt:
db "tty0", 0
.resetColor:
db 27, "[0m", 0

parameters:      dd ?
themeFont:       dd 0
themeBackground: dd 0
originalVT:      dd 0
ownVT:           dd 0
savedMode:       dd 0
columns:         dd 0
rows:            dd 0
screenBytes:     dd 0
screen:          dd 0
previous:        dd 0
output:          dd 0
expected:        dd 0
lastFont:        dd 0
lastBackground:  dd 0
putFont:         dd 0
putBackground:   dd 0
processes:       dd 0
processCount:    dd 0
windowCount:     dd 0
orderCount:      dd 0
slot:            dd 0
pairManager:     dd 0
pairSubsidiary:  dd 0
shellPID:        dd 0
pairDigit:       db 0
spawnFailed:     db 0
commandPending:  db 0
activity:        db 0
redraw:          db 0
quit:            db 0
sendByte:        db 0

order:      times Raava.maxWindows db 0 ;; Window indexes, bottom first
keyBuffer:  times 64 db 0
readBuffer: times Raava.readSize db 0
windows:    times Raava.maxWindows * Raava.Window.size db 0
