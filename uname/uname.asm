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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, applicationStart, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

VERSION equ "2.7.0"

uname:

;; Parameters POSIX.2 and compatible with BSD uname:
;;
;; -a: all parameters included
;; -s: kernel name
;; -n: hostname
;; -r: kernel release
;; -v: kernel version
;; -m: machine type
;; -p: processor type
;; -i: hardware platform
;; -o: operating system

.operatingSystem:
db "Hexagonix", 0
.space:
db " ", 0
.machine:
db "Hexagonix-PC", 0
.buildHexagon:
db "(build ", 0
.closeParentheses:
db ")", 0
.version:
db " version ", 0
.archi386:
db "i386", 0
.archamd64:
db "amd64", 0
.hexagonix:
db "Hexagonix", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.showAllParameter:
db "-a", 0
.showKernelNameParameter:
db "-s", 0
.showHostnameParameter:
db "-n", 0
.showReleaseParameter:
db "-r", 0
.showMachineTypeParameter:
db "-m", 0
.shorArchparameter:
db "-p", 0
.showPlatformParameter:
db "-i", 0
.showVersionParameter:
db "-v", 0
.showOperatingSystemParameter:
db "-o", 0
.hostFilename:
db "host", 0
.notSupported:
db "Unknown architecture.", 0
.platformPC:
db "PC", 0
.use:
db 10, "Usage: uname [parameter]", 10, 10
db "Displays system information.", 10, 10
db "Possible parameters (in case of missing parameters, the '-s' option will be selected):", 10, 10
db " -a: Displays all possible system, kernel and machine information.", 10
db " -s: Running kernel name.", 10
db " -n: Display the hostname of the machine running the system.", 10
db " -r: Release of the running kernel.", 10
db " -v: Running kernel version.", 10
db " -m: Machine type.", 10
db " -p: System processor architecture.", 10
db " -i: System hardware platform.", 10
db " -o: Name of running operating system.", 10, 10
db "uname version ", VERSION, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.dot:
db ".", 0

parameters: dd ?

;;************************************************************************************

applicationStart: ;; Entry point

    mov [parameters], edi

    mov edi, uname.helpParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    mov edi, uname.helpParameter2
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

;; -a

    mov edi, uname.showAllParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showAll

;; -s

    mov edi, uname.showKernelNameParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showKernelName

;; -n

    mov edi, uname.showHostnameParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showHostname

;; -r

    mov edi, uname.showReleaseParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showRelease

;; -m

    mov edi, uname.showMachineTypeParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showArch

;; -p

    mov edi, uname.shorArchparameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showArch

;; -i

    mov edi, uname.showPlatformParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showPlatform

;; -v

    mov edi, uname.showVersionParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showVersionOnly

;; -o

    mov edi, uname.showOperatingSystemParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc showOperatingSystemInfo

    jmp showKernelName

;;************************************************************************************

showKernelName:

    call putSpace

    hx.syscall hx.uname

    imprimirString

    jmp finish

;;************************************************************************************

showHostname:

    call putSpace

    call getHostname

    jmp finish

;;************************************************************************************

showRelease:

    call putSpace

    call kernelVersion

    jmp finish

;;************************************************************************************

showArch:

    call putSpace

    hx.syscall hx.uname

;; In EDX we have the architecture

    cmp edx, 01
    je .i386

    cmp edx, 02
    je .x86_64

    fputs uname.notSupported

    jmp .finish

.i386:

    fputs uname.archi386

    jmp .finish

.x86_64:

    fputs uname.archamd64

    jmp .finish

.finish:

    jmp finish

;;************************************************************************************

showPlatform:

    call putSpace

    fputs uname.platformPC

    jmp finish

;;************************************************************************************

showAll:

    call putSpace

    fputs uname.operatingSystem

    fputs uname.space

    call getHostname

.continuarHost:

    fputs uname.space

    hx.syscall hx.uname

    imprimirString

;; Para ficar de acordo com o padrão do FreeBSD, a mensagem "version" não é exibida

    ;; fputs uname.version

    fputs uname.space

    call kernelVersion

    fputs uname.space

    cmp edx, 01h
    je .i386

    cmp edx, 02h
    je .amd64

.i386:

    fputs uname.archi386

    jmp .continue

.amd64:

    fputs uname.archamd64

    jmp .continue

.continue:

    fputs uname.space

    fputs uname.hexagonix

    jmp finish

;;************************************************************************************

showOperatingSystemInfo:

    call putSpace

    fputs uname.operatingSystem

    jmp finish

;;************************************************************************************

showVersionOnly:

    call putSpace

    hx.syscall hx.uname

    imprimirString

    fputs uname.space

    call kernelVersion

    jmp finish

;;************************************************************************************

;; Requests the kernel version, decodes it and displays it to the user

kernelVersion:

    hx.syscall hx.uname

    push ecx
    push ebx

    imprimirInteiro

    fputs uname.dot

    pop eax

    imprimirInteiro

    pop ecx

    cmp ecx, 0
    je .continue

    push ecx

    fputs uname.dot

    pop eax

    imprimirInteiro

.continue:

    fputs uname.space

    fputs uname.buildHexagon

    hx.syscall hx.uname

    fputs edi

    fputs uname.closeParentheses

    ret

;;************************************************************************************

applicationUsage:

    fputs uname.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall encerrarProcesso

;;*****************************************************************************

putSpace:

    putNewLine

    ret

;;*****************************************************************************

getHostname:

;; Let's now display the hostname

    mov edi, appFileBuffer
    mov esi, uname.hostFilename

    hx.syscall hx.open

    jc .fileNotFound ;; If not found, display the default

;; If found, display the defined hostname

    clc

    mov esi, appFileBuffer

    hx.syscall tamanhoString

    mov edx, eax
    dec edx

    mov al, 0

    hx.syscall inserirCaractere

    fputs appFileBuffer

    jmp .continue

.fileNotFound:

    stc

    fputs uname.machine

.continue:

    ret

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

appFileBuffer: