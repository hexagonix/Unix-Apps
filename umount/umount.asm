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
include "mount.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi
    mov esi, edi

    cmp byte[esi], 0
    je applicationUsage

    mov edi, umount.allParameter
    mov esi, [parameters]

    call compareWordsInString

    jc unmountAll

    mov esi, [parameters]
    mov edi, umount.helpParameter

    call compareWordsInString

    jc applicationUsage

    mov esi, [parameters]

    hx.syscall hx.unmount

    jc unmountingError

    jmp finish

;;************************************************************************************

;; Unmounts every currently mounted volume, walking hx.getMounts
;; backwards so they come down in reverse mount order. Root always
;; fails with 03h here, which is expected, not a real error

unmountAll:

    mov ebx, umount.mountsBufferSize

    call malloc

    cmp eax, 0
    je mountsMallocError

    mov [mountsBuffer], ebx

    mov esi, ebx

    hx.syscall hx.getMounts

    mov [mountsCount], eax

    cmp eax, 0
    je .noMounts

    dec eax

    imul eax, hx.mount.record.size

    add eax, [mountsBuffer]

    mov [mountsPointer], eax

.unmountLoop:

    cmp dword[mountsCount], 0
    je .noMounts

    mov esi, [mountsPointer]

    hx.syscall hx.unmount

    jnc .unmountNext

    cmp eax, 03h
    je .unmountNext

    fputs umount.unmountAllFailed

.unmountNext:

    mov eax, [mountsPointer]

    sub eax, hx.mount.record.size
    
    mov [mountsPointer], eax

    dec dword[mountsCount]

    jmp .unmountLoop

.noMounts:

    mov ebx, [mountsBuffer]
    mov ecx, umount.mountsBufferSize

    call free

    jmp finish

;;************************************************************************************

mountsMallocError:

    fputs umount.mallocError

    jmp finish

;;************************************************************************************

unmountingError:

    cmp eax, 01h
    je .permissionDenied

    cmp eax, 02h
    je .notMounted

    fputs umount.refusingRoot ;; Only remaining code is 03h, unmounting "/"

    jmp finish

.permissionDenied:

    fputs umount.operationDenied

    jmp finish

.notMounted:

    fputs umount.notMounted

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

applicationUsage:

    fputs umount.use

    jmp finish

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.1.0"

umount:

.use:
db 10, "Usage: umount [mount point]", 10
db "       umount -a", 10, 10
db "Unmounts a previously mounted volume.", 10, 10
db "With -a, every currently mounted volume is unmounted, in the reverse", 10
db "of the order mount -a mounted them in.", 10, 10
db "umount version ", VERSION, 10, 10
db "Copyright (C) 2026-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.allParameter:
db "-a", 0
.notMounted:
db 10, "Nothing is mounted at that path.", 0
.refusingRoot:
db 10, "Refusing to unmount the root volume (/).", 0
.operationDenied:
db "Only the root user can perform unmounts. Login in this user to perform the desired unmount.", 0
.mallocError:
db 10, "Failed to allocate a buffer for the mount listing.", 0
.unmountAllFailed:
db 10, "Failed to unmount one of the currently mounted volumes.", 0

umount.mountsBufferSize = 64 * 1024 ;; Sized well past hx.getMounts.record.limit records

parameters: dd 0

mountsBuffer:  dd ?
mountsCount:   dd ?
mountsPointer: dd ?
