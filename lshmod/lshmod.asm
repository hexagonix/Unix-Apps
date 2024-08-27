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
;;
;;                        Application variables and data
;;
;;************************************************************************************

VERSION equ "0.10.1"

lshmod:

.use:
db 10, "Usage: lshmod [file]", 10, 10
db "Retrieve information from an HBoot image or module.", 10, 10
db "lshmod version ", VERSION, 10, 10
db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.invalidFile:
db 10, "The file name is invalid. Please enter a valid filename.", 0
.fileInfo:
db 10, "> Filename: ", 0
.fileSize:
db 10, "> File size: ", 0
.bytes:
db " bytes", 0
.invalidImage:
db 10, "<!> This is not an HBoot module image. Try another file.", 0
.fileNotFound:
db 10, "<!> The requested file is not available on this volume. Check the filename and try again.", 0
.archType:
db 10, "> Target architecture: ", 0
.modVersion:
db 10, "> Module version: ", 0
.dot:
db ".", 0
.header:
db 10, "<+> This file contains a valid HBoot image or HBoot module.", 0
.i386:
db "i386", 0
.amd64:
db "amd64", 0
.invalidArch:
db "unknown", 0
.imageInternalName:
db 10, "> Internal name of the HBoot image or module: ", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.modName:      dd 0
.architecture: db 0
.verMod:       db 0
.subverMod:    db 0

parameters: dd ?

filename:
times 13 db 0
moduleInternalName:
times 8   db 0

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, [parameters]

    cmp byte[esi], 0
    je applicationUsage

    mov edi, lshmod.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, lshmod.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [parameters]

    hx.syscall hx.trimString

    hx.syscall hx.stringSize

    cmp eax, 13
    jl .getInformation

    fputs lshmod.invalidFile

    jmp .end

.getInformation:

    hx.syscall hx.fileExists

    jc .fileNotFound

    call saveFilename

;; Let's check if the image is in fact an HBoot image

    call checkFileByHeader

;; If it is not an executable image, try to identify it by the extension, without
;; checking the content of the file

    jmp .end

.fileNotFound:

    fputs lshmod.fileNotFound

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

    cmp byte[edi+1], "B"
    jne .invalidHeader

    cmp byte[edi+2], "O"
    jne .invalidHeader

    cmp byte[edi+3], "O"
    jne .invalidHeader

    cmp byte[edi+4], "T"
    jne .invalidHeader

    mov dh, byte[edi+5]
    mov byte[lshmod.architecture], dh

    mov dh, byte[edi+6]
    mov byte[lshmod.verMod], dh

    mov dh, byte[edi+7]
    mov byte[lshmod.subverMod], dh

    mov esi, dword[edi+8]
    mov dword[moduleInternalName+0], esi

    mov esi, dword[edi+12]
    mov dword[moduleInternalName+4], esi

    mov dword[moduleInternalName+8], 0

    fputs lshmod.header

;; Let's get the image size

    mov esi, filename

    hx.syscall hx.fileExists

    jc applicationStart.fileNotFound

    push eax
    push esi

    fputs lshmod.fileInfo

    pop esi

    fputs esi

    fputs lshmod.fileSize

    pop eax

    printInteger

    fputs lshmod.bytes

;; Architecture

    fputs lshmod.archType

    cmp byte[lshmod.architecture], 01h
    je .i386

    cmp byte[lshmod.architecture], 02h
    je .amd64

    cmp byte[lshmod.architecture], 02h
    jg .invalidArch

.i386:

    fputs lshmod.i386

    jmp .continue

.amd64:

    fputs lshmod.amd64

    jmp .continue

.invalidArch:

    fputs lshmod.invalidArch

    jmp .continue

.continue:

    fputs lshmod.modVersion

    mov dh, byte[lshmod.verMod]
    movzx eax, dh

    printInteger

    fputs lshmod.dot

    mov dh, byte[lshmod.subverMod]
    movzx eax, dh

    printInteger

    fputs lshmod.imageInternalName

    mov esi, moduleInternalName

    hx.syscall hx.trimString

    fputs moduleInternalName

    ret

.invalidHeader:

    fputs lshmod.invalidImage

    ret

;;************************************************************************************

applicationUsage:

    fputs lshmod.use

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
