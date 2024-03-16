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

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "1.14.1"

lshapp:

.use:
db 10, "Usage: lshapp [file]", 10, 10
db "Retrieve and display information from a HAPP image.", 10, 10
db "lshapp version ", VERSION, 10, 10
db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.invalidFile:
db 10, 10, "The filename is invalid. Please enter a valid filename.", 10, 0
.fileInfo:
db 10, "> Filename: ", 0
.fileSize:
db 10, "> File size: ", 0
.bytes:
db " bytes.", 0
.invalidImage:
db 10, "<!> This is not a valid HAPP image. Try another file.", 0
.fileNotFound:
db 10, "<!> The requested file is not available on this volume. Check the filename and try again.", 0
.archType:
db 10, "> Target architecture: ", 0
.verHexagon:
db 10, "> Minimum version of Hexagon required to run: ", 0
.fieldVersionHexagon:
db " -> [HAPP:version and HAPP:subversion].", 0
.header:
db 10, "<+> This file contains a valid HAPP image.", 0
.i386:
db "i386", 0
.amd64:
db "amd64", 0
.fieldArch:
db " -> [HAPP:arch].", 0
.invalidArch:
db "unknown", 0
.imageEntryPoint:
db 10, "> Image entry point: ?:", 0
.fieldEntryPoint:
db " -> [HAPP:entryPoint].", 0
.imageType:
db 10, "> HAPP image format (type): ", 0
.HAPPExec:
db "Exec", 0
.HAPPLibS:
db "LibS", 0
.HAPPLibD:
db "LibD", 0
.unknownImagetype:
db "?", 0
.fieldImageType:
db " -> [HAPP:imageFormat].", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.dot:
db ".", 0

.entryPoint:        dd 0
.architecture:      db 0
.minimumVersion:    db 0
.minimumSubversion: db 0
.imageFormat:       db 0

parameters: dd ?

filename:
times 13 db 0

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, [parameters]

    cmp byte[esi], 0
    je applicationUsage

    mov edi, lshapp.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, lshapp.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [parameters]

    hx.syscall hx.trimString

    hx.syscall hx.stringSize

    cmp eax, 13
    jl .getInformation

    fputs lshapp.invalidFile

    jmp .end

.getInformation:

    hx.syscall hx.fileExists

    jc .fileNotFound

    call saveFilename

;; First let's see if it is an executable image.
;; If not, we can skip all the rest of the processing.
;; This ensures that executable images are reported as such even if they have different
;; extensions. The Hexagon itself is a HAPP image.

    call checkFileByHeader

    jmp .end

.fileNotFound:

    fputs lshapp.fileNotFound

    jmp .end

.end:

    jmp finish

;;************************************************************************************

checkFileByHeader:

    mov esi, filename
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc applicationStart.fileNotFound

    mov edi, appFileBuffer

    cmp byte[edi+0], "H"
    jne .invalidHeader

    cmp byte[edi+1], "A"
    jne .invalidHeader

    cmp byte[edi+2], "P"
    jne .invalidHeader

    cmp byte[edi+3], "P"
    jne .invalidHeader

    mov dh, byte[edi+4]
    mov byte[lshapp.architecture], dh

    mov dh, byte[edi+5]
    mov byte[lshapp.minimumVersion], dh

    mov dh, byte[edi+6]
    mov byte[lshapp.minimumSubversion], dh

    mov eax, dword[edi+7]
    mov dword[lshapp.entryPoint], eax

    mov ah, byte[edi+11]
    mov byte[lshapp.imageFormat], ah

    fputs lshapp.header

;; Image size

    mov esi, filename

    hx.syscall hx.fileExists

    jc applicationStart.fileNotFound

    push eax
    push esi

    fputs lshapp.fileInfo

    pop esi

    fputs esi

    fputs lshapp.fileSize

    pop eax

    printInteger

    fputs lshapp.bytes

;; Type of architecture

    fputs lshapp.archType

    cmp byte[lshapp.architecture], 01h
    je .i386

    cmp byte[lshapp.architecture], 02h
    je .amd64

    cmp byte[lshapp.architecture], 02h
    jg .invalidArch

.i386:

    fputs lshapp.i386

    jmp .continue

.amd64:

    fputs lshapp.amd64

    jmp .continue

.invalidArch:

    fputs lshapp.invalidArch

    jmp .continue

.continue:

;; Version of Hexagon required for execution

    fputs lshapp.fieldArch

    fputs lshapp.verHexagon

    mov dh, byte[lshapp.minimumVersion]
    movzx eax, dh

    printInteger

    fputs lshapp.dot

    mov dh, byte[lshapp.minimumSubversion]
    movzx eax, dh

    printInteger

    fputs lshapp.fieldVersionHexagon

;; Image entry point

    fputs lshapp.imageEntryPoint

    mov eax, dword[lshapp.entryPoint]

    printHexadecimal

    fputs lshapp.fieldEntryPoint

;; HAPP type

    fputs lshapp.imageType

    cmp byte[lshapp.imageFormat], 01h
    je .HAPPExec

    cmp byte[lshapp.imageFormat], 02h
    je .HAPPLibS

    cmp byte[lshapp.imageFormat], 03h
    je .HAPPLibD

    fputs lshapp.unknownImagetype

    jmp .imageTypeField

.HAPPExec:

    fputs lshapp.HAPPExec

    jmp .imageTypeField

.HAPPLibS:

    fputs lshapp.HAPPLibS

    jmp .imageTypeField

.HAPPLibD:

    fputs lshapp.HAPPLibD

    jmp .imageTypeField

.imageTypeField:

    fputs lshapp.fieldImageType

    ret

.invalidHeader:

    fputs lshapp.invalidImage

    ret

;;************************************************************************************

applicationUsage:

    fputs lshapp.use

    jmp finish

;;************************************************************************************

saveFilename:

    push esi
    push eax

    hx.syscall hx.trimString

    hx.syscall hx.stringSize

    mov ecx, eax

    mov edi, filename

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    pop eax

    pop esi

    ret

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

appFileBuffer:
