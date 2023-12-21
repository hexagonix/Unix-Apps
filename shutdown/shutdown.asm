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
;;                         Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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
include "log.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi ;; Save command line parameters

    logSistema shutdown.Verbose.start, 00h, Log.Prioridades.p4
    logSistema shutdown.Verbose.status, 00h, Log.Prioridades.p4

    mov esi, [parameters]

    cmp byte[esi], 0
    je argumentRequired

    mov edi, shutdown.helpParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    mov edi, shutdown.helpParameter2
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc applicationUsage

    mov edi, shutdown.shutdownParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc startShutdown

    mov edi, shutdown.shuydownNow
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc startShutdown

    mov edi, shutdown.rebootParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc startReboot

    mov edi, shutdown.shutdownWithoutEchoParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc startShutdownWithoutEcho

    mov edi, shutdown.rebootWithoutEchoParameter
    mov esi, [parameters]

    hx.syscall compararPalavrasString

    jc startRebootWithoutEcho

    jmp applicationUsage

;;************************************************************************************

startShutdown:

    jmp shutdownHexagon

;;************************************************************************************

startReboot:

    jmp rebootHexagon

;;************************************************************************************

startShutdownWithoutEcho:

    logSistema shutdown.Verbose.shutdownParameter, 00h, Log.Prioridades.p4

    call prepareSystemWithoutEcho

    logSistema shutdown.Verbose.parameterRequest, 00h, Log.Prioridades.p4

    hx.syscall desligarPC

    jmp finish

;;************************************************************************************

startRebootWithoutEcho:

    logSistema shutdown.Verbose.rebootParameter, 00h, Log.Prioridades.p4

    call prepareSystemWithoutEcho

    logSistema shutdown.Verbose.parameterRequest, 00h, Log.Prioridades.p4

    hx.syscall reiniciarPC

    jmp finish

;;************************************************************************************

shutdownHexagon:

    logSistema shutdown.Verbose.shutdownParameter, 00h, Log.Prioridades.p4

    call prepareSystem

    logSistema shutdown.Verbose.parameterRequest, 00h, Log.Prioridades.p4

    hx.syscall desligarPC

    jmp finish

;;************************************************************************************

rebootHexagon:

    logSistema shutdown.Verbose.rebootParameter, 00h, Log.Prioridades.p4

    call prepareSystem

    logSistema shutdown.Verbose.parameterRequest, 00h, Log.Prioridades.p4

    hx.syscall reiniciarPC

    jmp finish

;;************************************************************************************

prepareSystemWithoutEcho:

    mov ecx, 20000

    hx.syscall causarAtraso

    ret

;;************************************************************************************

prepareSystem:

    fputs shutdown.systemMessage

    mov ecx, 10000

    hx.syscall causarAtraso

    fputs shutdown.disksMessage

    mov ecx, 10000

    hx.syscall causarAtraso

    ret

;;************************************************************************************

applicationUsage:

    fputs shutdown.use

    jmp finish

;;************************************************************************************

argumentRequired:

    fputs shutdown.arguments

    jmp finish

;;************************************************************************************

finish:

    logSistema shutdown.Verbose.failedRequest, 00h, Log.Prioridades.p4

    hx.syscall encerrarProcesso

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

messageLabel equ "[shutdown]: "

VERSION  equ "1.6.0"

shutdown:

.shutdownParameter:
db "-d", 0
.shutdownWithoutEchoParameter:
db "-de", 0
.rebootParameter:
db "-r", 0
.rebootWithoutEchoParameter:
db "-re", 0
.shuydownNow:
db "now", 0
.systemMessage:
db 10, "The system is coming down. Please wait...", 0
.disksMessage:
db 10, "Stoping disks and shutting down the computer...", 0
.doneMessage:
db "[Ok]", 0
.failMessage:
db "[Fail]", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.arguments:
db 10, "An argument is required.", 0
.use:
db 10, "Usage: shutdown [argument]", 10, 10
db "Power off or reboot the computer.", 10, 10
db "Possible arguments:", 10, 10
db "-d  - Power the computer off.", 10
db "-r  - Reboot the computer.", 10
db "now - Same as -d.", 10, 10
db "shutdown version ", VERSION, 10, 10
db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0

shutdown.Verbose:

.start:
db messageLabel, "starting power management (version ", VERSION, ")...", 0
.status:
db messageLabel, "getting device state...", 0
.shutdownParameter:
db messageLabel, "received shutdown request.", 0
.rebootParameter:
db messageLabel, "reboot request received.", 0
.parameterRequest:
db messageLabel, "sending signal to processes and request to Hexagon...", 0
.failedRequest:
db messageLabel, "failed to process the request or request rejected by Hexagon.", 0

parameters: dd ?
