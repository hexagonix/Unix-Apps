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
;;                         Copyright (c) 2015-2025 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2025, Felipe Miguel Nery Lunkes
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

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    mov esi, [parameters]

    cmp byte[esi], 0
    je applicationUsage

    mov edi, fileUnix.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, fileUnix.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov esi, [parameters]

    hx.syscall hx.trimString

    hx.syscall hx.stringSize

    cmp eax, 13
    jl .getInfo

    fputs fileUnix.arquivoInvalido

    jmp .end

.getInfo:

    hx.syscall hx.fileExists

    jc .fileNotFound

    push eax

    call saveFileName

    fputs fileUnix.fileSize

    pop eax

    printInteger

    fputs fileUnix.bytes

;; First let's see if it is an executable image. If yes, we can skip all the rest of the
;; processing. This ensures that executable images are reported as such even if they have
;; different extensions, as each shell can look for a specific/preferred extension type other
;; than .APP. Accessory images that need to be called by another process during its execution
;; may have another extension. The Hexagon itself is a HAPP image

    call verifyHAPPFile

    call verifyHBootFile

;; If it is not an executable image, try to identify it by extension, without checking the
;; file contents

.continue:

    mov esi, fileName

    hx.syscall hx.stringToUppercase ;; We will check based on the capitalized extension

    hx.syscall hx.stringSize

    add esi, eax ;; Add name length

    sub esi, 4 ;; Subtract 4 to keep only the extension

    mov edi, fileUnix.extensionUNX

    hx.syscall hx.compareWordsString ;; Check for .UNX extension

    jc .fileUNX

    mov edi, fileUnix.extensionSIS

    hx.syscall hx.compareWordsString ;; Check for .SIS extension

    jc .fileSIS

    mov edi, fileUnix.extensionTXT

    hx.syscall hx.compareWordsString ;; Check for .TXT extension

    jc .fileTXT

    mov edi, fileUnix.extensionASM

    hx.syscall hx.compareWordsString ;; Check for .ASM extension

    jc .fileASM

    mov edi, fileUnix.extensionCOW

    hx.syscall hx.compareWordsString ;; Check for .COW extension

    jc .fileCOW

    mov edi, fileUnix.extensionMAN

    hx.syscall hx.compareWordsString ;; Check for .MAN extension

    jc .fileMAN

    mov edi, fileUnix.extensionFNT

    hx.syscall hx.compareWordsString ;; Check for .FNT extension

    jc .fileFNT

    mov edi, fileUnix.extensionCAN

    hx.syscall hx.compareWordsString ;; Check for .CAN extension

    jc .fileCAN

;; Check now with two letters in length

;; Check now with a single letter extension

    add esi, 2 ;; Add 2 (would be a removal of 2) to keep just the extension

    mov edi, fileUnix.extensionS

    hx.syscall hx.compareWordsString ;; Check for .S extension

    jc .fileS

.noValidExtension:

    fputs fileUnix.defaultFile

    jmp .end

.application:

    fputs fileUnix.validApplication

    jmp .end

.fileHBoot:

    fputs fileUnix.fileHBoot

    jmp .end

.fileUNX:

    fputs fileUnix.fileUnix

    jmp .end

.fileTXT:

    fputs fileUnix.fileTXT

    jmp .end

.fileFNT:

    fputs fileUnix.fileFNT

    jmp .end

.fileCAN:

    fputs fileUnix.fileCAN

    jmp .end

.fileCOW:

    fputs fileUnix.fileCOW

    jmp .end

.fileMAN:

    fputs fileUnix.fileMAN

    jmp .end

.fileSIS:

    fputs fileUnix.fileSIS

    jmp .end

.fileASM:

    fputs fileUnix.fileASM

    jmp .end

.fileS:

    fputs fileUnix.fileLibASM

    jmp .end

.fileNotFound:

    fputs fileUnix.fileNotFound

    jmp .end

.end:

    jmp finish

;;************************************************************************************

verifyHAPPFile:

    mov esi, fileName
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc applicationStart.fileNotFound

    mov edi, appFileBuffer

    cmp byte[edi+0], "H"
    jne .notHAPP

    cmp byte[edi+1], "A"
    jne .notHAPP

    cmp byte[edi+2], "P"
    jne .notHAPP

    cmp byte[edi+3], "P"
    jne .notHAPP

    jmp applicationStart.application

.notHAPP:

    ret

;;************************************************************************************

verifyHBootFile:

    mov esi, fileName
    mov edi, appFileBuffer

    hx.syscall hx.open

    jc applicationStart.fileNotFound

    mov edi, appFileBuffer

    cmp byte[edi+0], "H"
    jne .notHBoot

    cmp byte[edi+1], "B"
    jne .notHBoot

    cmp byte[edi+2], "O"
    jne .notHBoot

    cmp byte[edi+3], "O"
    jne .notHBoot

    cmp byte[edi+4], "T"
    jne .notHBoot

    jmp applicationStart.fileHBoot

.notHBoot:

    ret

;;************************************************************************************

applicationUsage:

    fputs fileUnix.use

    jmp finish

;;************************************************************************************

saveFileName:

    push esi
    push eax

    hx.syscall hx.trimString

    hx.syscall hx.stringSize

    mov ecx, eax

    mov edi, fileName

    rep movsb ;; Copy (ECX) characters from ESI to EDI

    pop eax

    pop esi

    ret

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;*********************************************************************

VERSION equ "1.11.0"

fileUnix:

.use:
db 10, "Usage: file [file]", 10, 10
db "Retrieve information from the file and send it to the console.", 10, 10
db "file version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringYear, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.arquivoInvalido:
db 10, "The file name is invalid. Please enter a valid filename.", 0
.fileSize:
db 10, "File size: ", 0
.bytes:
db " bytes.", 0
.fileNotFound:
db 10, "The requested file is not available on this volume. Check the filename and try again.", 0
.validApplication:
db 10, "This appears to be a Unix executable for Hexagon.", 0
.fileHBoot:
db 10, "This appears to be an executable in HBoot format (HBoot or HBoot module).", 0
.fileASM:
db 10, "This appears to be an Assembly source file.", 0
.fileLibASM:
db 10, "This appears to be a source file that contains an Assembly development library.", 0
.fileSIS:
db 10, "This appears to be a system file.", 0
.fileUnix:
db 10, "This appears to be a Unix environment data or configuration file.", 0
.fileMAN:
db 10, "This appears to be a manual file.", 0
.fileCOW:
db 10, "This appears to be a database file from the cowsay utility.", 0
.fileTXT:
db 10, "This appears to be a UTF-8 text file.", 0
.fileFNT:
db 10, "This appears to be a Hexagon display font file.", 0
.fileCAN:
db 10, "This appears to be a Hexagonix config plugin file.", 0
.defaultFile:
db 10, "This appears to be a data file.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.extensionSIS:
db ".SIS", 0
.extensionASM:
db ".ASM", 0
.extensionBIN:
db ".BIN", 0
.extensionUNX:
db ".UNX", 0
.extensionFNT:
db ".FNT", 0
.extensionOCL:
db ".OCL", 0
.extensionMAN:
db ".MAN", 0
.extensionCOW:
db ".COW", 0
.extensionTXT:
db ".TXT", 0
.extensionCAN:
db ".CAN", 0
.extensionS:
db ".S", 0

parameters: dd ?

fileName:
times 13 db 0

;;************************************************************************************

appFileBuffer: