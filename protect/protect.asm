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

;; Architecture | Version | Subversion | Entry point | Image type | BSS size

headerHAPP HAPP.Architectures.i386, 1, 8, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "string.s"
include "malloc.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, edi

    cmp byte[esi], 0
    je argumentRequired

    mov edi, protect.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, protect.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    call requireRoot

    mov edi, protect.allParameter
    mov esi, [parameters]

    call compareWordsInString

    jc protectAll

    mov edi, protect.unprotectParameter
    mov esi, [parameters]

    call compareWordsInString

    jc unprotectSingle

    mov edi, protect.setuidParameter
    mov esi, [parameters]

    call compareWordsInString

    jc setuidSingle

    mov esi, [parameters]
    mov ebx, protect.modeProtected

    call chownPath

    jc chownError

    jmp finish

;;************************************************************************************

unprotectSingle:

    mov esi, [parameters]

    call skipFirstWord ;; ESI now sits past "-u ", at the path itself

    cmp byte[esi], 0
    je applicationUsage

    mov ebx, protect.modeOpen

    call chownPath

    jc chownError

    jmp finish

;;************************************************************************************

setuidSingle:

    mov esi, [parameters]

    call skipFirstWord ;; ESI now sits past "-s ", at the path itself

    cmp byte[esi], 0
    je applicationUsage

    mov ebx, protect.modeSetuid

    call chownPath

    jc chownError

    jmp finish

;;************************************************************************************

;; Reads /etc/protect and calls hx.chown for each path listed in it,
;; protecting every one of them. A missing /etc/protect simply protects
;; nothing, not an error

protectAll:

    mov ebx, protect.protectBufferSize

    call malloc

    cmp eax, 0

    je mallocError

    mov [protectBuffer], ebx

    mov esi, protect.protectPath
    mov edi, ebx

    xor ecx, ecx

    hx.syscall hx.open

    jc .noProtectFile

    mov esi, ebx

.lineLoop:

    mov edi, protect.lineBuffer

.copyChar:

    lodsb

    cmp al, 0
    je .lastLine

    cmp al, 10
    je .lineComplete

;; /etc/protect may carry CRLF line endings, so the CR is skipped outright instead of copied

    cmp al, 13 
    je .copyChar

    mov byte[edi], al

    inc edi

    cmp edi, protect.lineBuffer + protect.lineBufferSize - 1
    jae .lineComplete ;; Line too long for the buffer, process what fits

    jmp .copyChar

.lineComplete:

    mov byte[edi], 0

    push esi

    call .protectLine

    pop esi

    jmp .lineLoop

.lastLine:

    mov byte[edi], 0

    call .protectLine

.noProtectFile:

    mov ebx, [protectBuffer]
    mov ecx, protect.protectBufferSize

    call free

    jmp finish

;; Parses one NUL terminated /etc/protect line and protects it. Blank
;; lines and lines starting with '#' are silently ignored. A path may be
;; followed by a space and the word "setuid" to also grant root on exec

.protectLine:

    mov esi, protect.lineBuffer

    call trimString

    cmp byte[esi], 0
    je .protectLineDone

    cmp byte[esi], '#'
    je .protectLineDone

    mov ebx, protect.modeProtected

    push esi ;; ESI still at the start of the path

.scanSpace:

    lodsb

    cmp al, ' '
    je .foundSpace

    cmp al, 0
    je .noSecondWord

    jmp .scanSpace

.foundSpace:

    mov byte[esi - 1], 0 ;; NUL-terminate the path in place, ESI now at the second word
    mov edi, protect.setuidWord

    call compareWordsInString

    jnc .noSecondWord

    mov ebx, protect.modeSetuid

.noSecondWord:

    pop esi

    call chownPath

.protectLineDone:

    ret

;;************************************************************************************

mallocError:

    fputs protect.mallocError

    jmp finish

;;************************************************************************************

;; Calls hx.chown on a single path
;;
;; Input:
;;
;; ESI - Path
;; EBX - Requested mode (protect.modeProtected or protect.modeOpen)
;;
;; Output:
;;
;; CF set on error, EAX holding the error code

chownPath:

    hx.syscall hx.chown

    ret

;;************************************************************************************

;; Scans ESI forward past its first word and the single space after it
;;
;; Input:
;;
;; ESI - String starting with a word followed by a space
;;
;; Output:
;;
;; ESI - Start of whatever follows that first space

skipFirstWord:

    lodsb

    cmp al, ' '
    je .done

    cmp al, 0
    je .done

    jmp skipFirstWord

.done:

    ret

;;************************************************************************************

chownError:

    cmp eax, 01h
    je .permissionDenied

    fputs protect.notFound ;; Only remaining code is 02h, path not found

    jmp finish

.permissionDenied:

    fputs protect.operationDenied

    jmp finish

;;************************************************************************************

;; Only root, directly or through a setuid elevation such as sudo, may
;; protect, unprotect or mark a path setuid. Checked once up front, since
;; -a would otherwise fail silently once per line instead of all at once

requireRoot:

    hx.syscall hx.getUser

    cmp eax, 0
    je .authorized

    fputs protect.operationDenied

    jmp finish

.authorized:

    ret

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

applicationUsage:

    fputs protect.use

    jmp finish

;;************************************************************************************

argumentRequired:

    fputs protect.argumentRequired

    jmp finish


;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.1.0"

protect:

.use:
db 10, "Usage: protect <path>", 10
db "       protect -u <path>", 10
db "       protect -s <path>", 10
db "       protect -a", 10, 10
db "Marks a path/file as protected: only root can unlink, rename or change it.", 10, 10
db "With -u, removes the protection from a path instead.", 10
db "With -s, also grants root to whoever runs the path, through the setuid attribute.", 10
db "With -a, every path listed in /etc/protect is protected. A path may be", 10
db "followed there by the word setuid to also get -s.", 10, 10
db "Only the root user can run this.", 10, 10
db "protect version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.argumentRequired:
db 10, "An argument is required. Use --help for more information.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.allParameter:
db "-a", 0
.unprotectParameter:
db "-u", 0
.setuidParameter:
db "-s", 0
.setuidWord:
db "setuid", 0
.mallocError:
db 10, "Failed to allocate a buffer for /etc/protect.", 0
.notFound:
db 10, "That path does not exist.", 0
.operationDenied:
db 10,  "Only the root user (root), directly or through sudo, can protect, unprotect or mark a path setuid.", 0
.protectPath:
db "/etc/protect", 0

protect.protectBufferSize = 4 * 1024
protect.lineBufferSize    = 128
protect.modeProtected     = 0 ;; No write-for-others bit (S_IWOTH): FAT16B sets its SYSTEM attribute
protect.modeOpen          = 2 ;; Write-for-others bit (S_IWOTH) present: FAT16B clears it
protect.modeSetuid        = protect.modeProtected or 0800h ;; Protected, plus S_ISUID: FAT16B also sets its setuid attribute

parameters: dd 0

protectBuffer: dd ?

protect.lineBuffer:
times protect.lineBufferSize db 0
