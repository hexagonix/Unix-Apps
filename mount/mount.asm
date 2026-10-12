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
    je displayMounts

    mov edi, mount.allParameter
    mov esi, [parameters]

    call compareWordsInString

    jc mountAll

    call getParameters

    jc  applicationUsage

    mov edi, mount.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov esi, [volume]
    mov edi, [mountPoint]

    hx.syscall hx.mount

    jc mountingError

    jmp finish

;;************************************************************************************

;; Lists every mount point currently in use, one per line ("device on point
;; type fstype"). hx.getMounts needs its own caller-supplied buffer,
;; so this mallocs one and frees it after printing

displayMounts:

    putNewLine

    mov byte[mountsFirstLine], 1
    mov ebx, mount.mountsBufferSize

    call malloc

    cmp eax, 0

    je mountsMallocError

    mov [mountsBuffer], ebx

    mov esi, ebx

    hx.syscall hx.getMounts

    mov [mountsCount], eax
    mov eax, [mountsBuffer]
    mov [mountsPointer], eax

.mountsLoop:

    cmp dword[mountsCount], 0
    je .mountsDone

    cmp byte[mountsFirstLine], 0
    je .separator

    mov byte[mountsFirstLine], 0

    jmp .printRecord

.separator:

    putNewLine

.printRecord:

    mov esi, [mountsPointer]

    add esi, hx.mount.record.deviceName

    printString

    fputs mount.on

    mov esi, [mountsPointer] ;; Mount point path sits at record offset 0

    printString

    fputs mount.type

    mov esi, [mountsPointer]
    movzx eax, byte[esi + hx.mount.record.filesystemType]

    call printMountFilesystemType

    mov eax, [mountsPointer]

    add eax, hx.mount.record.size
    
    mov [mountsPointer], eax

    dec dword[mountsCount]

    jmp .mountsLoop

.mountsDone:

    mov ebx, [mountsBuffer]
    mov ecx, mount.mountsBufferSize

    call free

    jmp finish

;;************************************************************************************

mountsMallocError:

    fputs mount.mallocError

    jmp finish

;;************************************************************************************

;; Reads /etc/fstab and calls hx.mount for each entry in it (type and
;; options are accepted but unused). A missing /etc/fstab simply leaves
;; nothing mounted, not an error

mountAll:

    mov ebx, mount.fstabBufferSize

    call malloc

    cmp eax, 0
    je mountsMallocError

    mov [fstabBuffer], ebx

    mov esi, mount.fstabPath
    mov edi, ebx

    xor ecx, ecx

    hx.syscall hx.open

    jc .noFstab

    mov esi, ebx

.lineLoop:

    mov edi, mount.lineBuffer

.copyChar:

    lodsb

    cmp al, 0
    je .lastLine

    cmp al, 10
    je .lineComplete

;; /etc/fstab may carry CRLF line endings, so the CR is skipped outright instead of copied

    cmp al, 13 
    je .copyChar 

    mov byte[edi], al

    inc edi

    cmp edi, mount.lineBuffer + mount.lineBufferSize - 1
    jae .lineComplete ;; Line too long for the buffer, process what fits

    jmp .copyChar

.lineComplete:

    mov byte[edi], 0

    push esi

    call .mountLine

    pop esi

    jmp .lineLoop

.lastLine:

    mov byte[edi], 0

    call .mountLine

.noFstab:

    mov ebx, [fstabBuffer]
    mov ecx, mount.fstabBufferSize

    call free

    jmp finish

;; Parses one NUL terminated fstab line and mounts it. Blank lines and
;; lines starting with '#' are silently ignored

.mountLine:

    mov esi, mount.lineBuffer

    call trimString

    cmp byte[esi], 0
    je .mountLineDone

    cmp byte[esi], '#'
    je .mountLineDone

    push esi ;; Device field start, saved across the mount point split below

    call findFieldEnd ;; Terminates the device field, ESI now at the next field

    jc .mountLineNoTarget ;; No mount point on this line, nothing to mount

    mov edi, esi

    call findFieldEnd ;; Terminates the mount point field, dropping type/options

    pop esi ;; Device field start

    hx.syscall hx.mount

    jnc .mountLineDone

    fputs mount.fstabMountFailed

    jmp .mountLineDone

.mountLineNoTarget:

    pop esi ;; Balances the push above, value unused

.mountLineDone:

    ret

;;************************************************************************************

;; Prints the filesystem name for a mount record's type code at the current
;; cursor position
;;
;; Input:
;;
;; AL - Filesystem type code

printMountFilesystemType:

    cmp al, 01h
    je .fat12

    cmp al, 04h
    je .fat16_32

    cmp al, 06h
    je .fat16

    cmp al, 0FFh ;; Hexagon.VFS.FS.DEVFS
    je .devfs

    fputs mount.unknownFilesystem

    ret

.fat12:

    fputs mount.FAT12

    ret

.fat16_32:

    fputs mount.FAT16_32

    ret

.fat16:

    fputs mount.FAT16

    ret

.devfs:

    fputs mount.devfs

    ret

;;************************************************************************************

mountingError:

    cmp eax, 01h
    je .permissionDenied

    cmp eax, 02h
    je .deviceNotFound

    cmp eax, 03h
    je .badMountPoint

    cmp eax, 04h
    je .noFreeSlots

    cmp eax, 06h
    je .mountPointBusy

    fputs mount.badBPB ;; Only remaining code is 05h, a bad partition BPB

    jmp finish

.permissionDenied:

    fputs mount.operationDenied

    jmp finish

.deviceNotFound:

    fputs mount.notFound

    jmp finish

.badMountPoint:

    fputs mount.mountPointError

    jmp finish

.noFreeSlots:

    fputs mount.noFreeSlots

    jmp finish

.mountPointBusy:

    fputs mount.mountPointBusy

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

    call findCharacterInString

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

;; Scans forward from ESI until a space or the end of the string, cutting
;; the field off in place at whichever it finds
;;
;; Input:
;;
;; ESI - Start of the field
;;
;; Output:
;;
;; ESI - Start of whatever follows the field
;; CF  - Set if the field already reached the end of the string, with no
;;       space separating it from anything after

findFieldEnd:

    lodsb

    cmp al, 0
    je .terminated

    cmp al, ' '
    jne findFieldEnd

    mov byte[esi-1], 0

    clc

    ret

.terminated:

    mov byte[esi-1], 0

    stc

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

VERSION equ "2.8.0"

mount:

.use:
db 10, "Usage: mount [volume] [mount point]", 10
db "       mount -a", 10, 10
db "Performs mounting a volume to a file system mount point.", 10, 10
db "If no parameter is provided, the mounting points will be displayed.", 10
db "With -a, every volume listed in /etc/fstab is mounted.", 10, 10
db "mount version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.allParameter:
db "-a", 0
.mountPointError:
db 10, "Please enter a valid mount point for this volume and file system.", 0
.on:
db " on ", 0
.type:
db " type ", 0
.mallocError:
db 10, "Failed to allocate a buffer for the mount listing.", 0
.FAT16:
db "fat16b", 0
.FAT12:
db "fat12", 0
.FAT16_32:
db "fat16 <32 mb", 0
.devfs:
db "devfs", 0
.unknownFilesystem:
db "unknown", 0
.notFound:
db 10, "Device not found or filesystem not supported.", 0
.noFreeSlots:
db 10, "No free mount slots are available. Unmount an existing volume first.", 0
.mountPointBusy:
db 10, "That mount point already has a different device mounted on it.", 0
.badBPB:
db 10, "Failed to read the partition's own boot parameter block.", 0
.operationDenied:
db "Only the root user can perform mounts. Login in this user to perform the desired mount.", 0
.fstabPath:
db "/etc/fstab", 0
.fstabMountFailed:
db 10, "Failed to mount an entry listed in /etc/fstab.", 0

mount.mountsBufferSize = 64 * 1024 ;; Sized well past hx.getMounts.record.limit records
mount.fstabBufferSize  = 4 * 1024
mount.lineBufferSize   = 128

parameters: dd 0
volume:     dd ?
mountPoint: dd ?

mountsBuffer:    dd ?
mountsCount:     dd ?
mountsPointer:   dd ?
mountsFirstLine: db ?

fstabBuffer: dd ?

mount.lineBuffer:
times mount.lineBufferSize db 0
