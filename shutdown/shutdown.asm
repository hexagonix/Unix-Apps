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
include "process.s"
include "log.s"

;;************************************************************************************

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi ;; Save command line parameters

    systemLog shutdown.Verbose.start, 00h, Log.Priorities.p4
    systemLog shutdown.Verbose.status, 00h, Log.Priorities.p4

    mov esi, [parameters]

    cmp byte[esi], 0
    je argumentRequired

    mov edi, shutdown.helpParameter
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    mov edi, shutdown.helpParameter2
    mov esi, [parameters]

    call compareWordsInString

    jc applicationUsage

    call requireRoot

    mov edi, shutdown.shutdownParameter
    mov esi, [parameters]

    call compareWordsInString

    jc startShutdown

    mov edi, shutdown.shuydownNow
    mov esi, [parameters]

    call compareWordsInString

    jc startShutdown

    mov edi, shutdown.rebootParameter
    mov esi, [parameters]

    call compareWordsInString

    jc startReboot

    mov edi, shutdown.shutdownWithoutEchoParameter
    mov esi, [parameters]

    call compareWordsInString

    jc startShutdownWithoutEcho

    mov edi, shutdown.rebootWithoutEchoParameter
    mov esi, [parameters]

    call compareWordsInString

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

    systemLog shutdown.Verbose.shutdownParameter, 00h, Log.Priorities.p4

    call prepareSystemWithoutEcho

    systemLog shutdown.Verbose.parameterRequest, 00h, Log.Priorities.p4

    hx.syscall hx.shutdown

    jmp finish

;;************************************************************************************

startRebootWithoutEcho:

    systemLog shutdown.Verbose.rebootParameter, 00h, Log.Priorities.p4

    call prepareSystemWithoutEcho

    systemLog shutdown.Verbose.parameterRequest, 00h, Log.Priorities.p4

    hx.syscall hx.restart

    jmp finish

;;************************************************************************************

shutdownHexagon:

    systemLog shutdown.Verbose.shutdownParameter, 00h, Log.Priorities.p4

    call prepareSystem

    systemLog shutdown.Verbose.parameterRequest, 00h, Log.Priorities.p4

    hx.syscall hx.shutdown

    jmp finish

;;************************************************************************************

rebootHexagon:

    systemLog shutdown.Verbose.rebootParameter, 00h, Log.Priorities.p4

    call prepareSystem

    systemLog shutdown.Verbose.parameterRequest, 00h, Log.Priorities.p4

    hx.syscall hx.restart

    jmp finish

;;************************************************************************************

prepareSystemWithoutEcho:

    mov ecx, 100

    hx.syscall hx.sleep

    call terminateProcesses

    call execUmountAll

    ret

;;************************************************************************************

prepareSystem:

    fputs shutdown.systemMessage

    mov ecx, 100

    hx.syscall hx.sleep

    call terminateProcesses

    fputs shutdown.disksMessage

    mov ecx, 100

    hx.syscall hx.sleep

    call execUmountAll

    ret

;;************************************************************************************

;; Kills every process except PID 0, init (PID 1) and shutdown's own PID

terminateProcesses:

    hx.syscall hx.pid

    mov [ownPID], eax
    mov dword[processesBufferSize], 2048 ;; Arbitrary starting guess

.allocateBuffer:

    mov ebx, dword[processesBufferSize]

    call malloc

    cmp eax, 0
    je .done ;; No buffer available, nothing left to try

    mov [processesBuffer], ebx
    mov esi, ebx
    mov ecx, dword[processesBufferSize]

    hx.syscall hx.getProcesses ;; EAX = record count, or exact size needed if CF is set

    jnc .haveProcesses

    push eax

    mov ebx, [processesBuffer]
    mov ecx, dword[processesBufferSize]

    call free

    pop eax

    mov dword[processesBufferSize], eax

    jmp .allocateBuffer

.haveProcesses:

    mov [processesCount], eax
    mov esi, [processesBuffer]
    mov eax, dword[esi] ;; Record size, read from the message itself
    mov [processRecordSize], eax

    add esi, 4 ;; Skip past the record size

    mov [recordsPointer], esi

.killLoop:

    cmp dword[processesCount], 0
    je .freeBuffer

    mov esi, [recordsPointer]
    mov ebx, dword[esi + hx.process.record.pid]

    cmp ebx, 0
    je .killNext ;; The kernel itself, never a real process

    cmp ebx, 1
    je .killNext ;; init

    cmp ebx, [ownPID]
    je .killNext

    hx.syscall hx.kill

.killNext:

    mov eax, [recordsPointer]

    add eax, [processRecordSize]
    
    mov [recordsPointer], eax

    dec dword[processesCount]

    jmp .killLoop

.freeBuffer:

    mov ebx, [processesBuffer]
    mov ecx, [processesBufferSize]

    call free

.done:

    ret

;;************************************************************************************

;; Requests every mounted volume come down before the power off or
;; reboot completes. Reading the mount list and walking the mount table
;; both stay the invoked binary's own responsibility, not shutdown's

execUmountAll:

    mov esi, shutdown.umountPath
    mov edi, shutdown.umountAllArgument
    mov eax, edi

    hx.syscall hx.exec

    ret

;;************************************************************************************

;; Only root, directly or through a setuid elevation such as sudo, may
;; power off or reboot the system

requireRoot:

    hx.syscall hx.getUser

    cmp eax, 0
    je .authorized

    fputs shutdown.operationDenied

    jmp finish

.authorized:

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

    systemLog shutdown.Verbose.failedRequest, 00h, Log.Priorities.p4

    hx.syscall hx.exit

;;************************************************************************************
;;
;;                        Application variables and data
;;
;;************************************************************************************

messageLabel equ "[shutdown]: "

VERSION equ "1.9.0"

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
.umountPath:
db "/sbin/umount", 0
.umountAllArgument:
db "-a", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.arguments:
db 10, "An argument is required.", 0
.operationDenied:
db 10, "Only the root user (root), directly or through sudo, can shut down or reboot the system.", 0
.use:
db 10, "Usage: shutdown [argument]", 10, 10
db "Power off or reboot the computer.", 10, 10
db "Every other running process is terminated and every mounted volume is", 10
db "unmounted first.", 10, 10
db "Possible arguments:", 10, 10
db "-d  - Power the computer off.", 10
db "-r  - Reboot the computer.", 10
db "now - Same as -d.", 10, 10
db "Only the root user can run this.", 10, 10
db "shutdown version ", VERSION, 10, 10
db "Copyright (C) 2022-", __stringYear, " Felipe Miguel Nery Lunkes", 10
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

ownPID:              dd ?
processesBufferSize: dd ?
processesBuffer:     dd ?
processesCount:      dd ?
processRecordSize:   dd ?
recordsPointer:      dd ?
