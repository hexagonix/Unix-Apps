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
;;                         Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
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
appHeader headerHAPP HAPP.Architectures.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "errors.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, edi

    cmp byte[esi], 0
    je displayMounts

    call getParameters

    jc  applicationUsage

    mov edi, mount.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, mount.defaultPath
    mov esi, [mountPoint]

    hx.syscall hx.compareWordsString

    jc .mountFilesysten

    jmp mountPointError

.mountFilesysten:

    fputs mount.volume

    fputs [volume]

    fputs mount.mountPoint

    fputs [mountPoint]

    fputs mount.closeBracket

    mov esi, [volume]

    hx.syscall hx.open

    jc openingError

    jmp finish

;;************************************************************************************

displayMounts:

    putNewLine

    hx.syscall hx.getVolume

    push edi
    push eax

    printString

    fputs mount.volumeInformation

    fputs mount.defaultPath

    fputs mount.filesystemType

    pop eax

    cmp ah, 01h
    je .fat12

    cmp ah, 04h
    je .fat16_32

    cmp ah, 06h
    je .fat16

    fputs mount.unknownFilesystem

    jmp .continue

.fat12:

    fputs mount.FAT12

    jmp .continue

.fat16_32:

    fputs mount.FAT16_32

    jmp .continue

.fat16:

    fputs mount.FAT16

    jmp .continue

.continue:

    fputs mount.filesystemLabel

    pop edi

    mov esi, edi

    hx.syscall hx.trimString

    printString

    jmp finish

;;************************************************************************************

mountPointError:

    fputs mount.mountPointError

    jmp finish

;;************************************************************************************

openingError:

    cmp eax, IO.operationDenied
    je .operationDenied

    cmp eax, IO.notFound
    je .notFound

    fputs mount.openingError

    jmp finish

.operationDenied:

    fputs mount.operationDenied

    jmp finish

.notFound:

    fputs mount.notFound

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;; Get parameters directly from the command line

getParameters:

    mov esi, [parameters]
    mov [volume], esi

    cmp byte[esi], 0
    je applicationUsage

    mov al, ' '

    hx.syscall hx.findCharacter

    jc applicationUsage

    mov al, ' '

    call findCharacterMount

    mov [mountPoint], esi

    jmp .done

.done:

    clc

    ret

;;************************************************************************************

;; Searches for a specific character in the given String
;;
;; Input:
;;
;; ESI - String to be checked
;; AL  - Character to search for
;;
;; Output:
;;
;; ESI - Character position in the given String

findCharacterMount:

    lodsb

    cmp al, ' '
    je .done

    jmp findCharacterMount

.done:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

applicationUsage:

    fputs mount.use

    jmp finish

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "2.7.1"

mount:

.volume:
db 10, "Mounting [", 0
.mountPoint:
db "] on [", 0
.closeBracket:
db "]...", 0
.use:
db 10, "Usage: mount [volume] [mount point]", 10, 10
db "Performs mounting a volume to a file system mount point.", 10, 10
db "If no parameter is provided, the mounting points will be displayed.", 10, 10
db "mount version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.openingError:
db 10, "Error mounting volume at specified mount point.", 10
db "Try to enter a valid name or reference of an attached volume.", 0
.helpParameter:
db "?", 0
.defaultPath:
db "/", 0
.mountPointError:
db 10, "Please enter a valid mount point for this volume and file system.", 0
.volumeInformation:
db " on ", 0
.filesystemLabel:
db " with the label ", 0
.filesystemType:
db " type ", 0
.notFound:
db 10, "Device not found or filesystem not supported.", 0
.operationDenied:
db "The mount was refused by the system. This may be explained due to the fact that the current user", 10
db "does not have administrative privileges, not being a root user (root).", 10, 10
db "Only the root user (root) can perform mounts. Login in this user to perform the desired mount.", 0
.FAT16:
db "FAT16B", 0
.FAT12:
db "FAT12", 0
.FAT16_32:
db "FAT16 <32 MB", 0
.unknownFilesystem:
db "unknown", 0

parameters: dd 0
volume:     dd ?
mountPoint: dd ?
