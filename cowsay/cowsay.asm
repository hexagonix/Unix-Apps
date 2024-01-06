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

applicationStart:

    push ds ;; User mode data segment (38h selector)
    pop es

    mov [parameters], edi

    call getParameters

    mov edi, cowsay.helpParameter
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    mov edi, cowsay.helpParameter2
    mov esi, [parameters]

    hx.syscall hx.compareWordsString

    jc applicationUsage

    putNewLine

    mov esi, [userMessage]

    hx.syscall hx.stringSize

    mov dword[userMessageSize], eax

    mov ecx, eax
    add ecx, 4

.loopTopBubble:

    fputs cowsay.topLine

    loop .loopTopBubble

.leftSide:

    putNewLine

    fputs cowsay.bar

    mov ecx, dword[userMessageSize]
    add ecx, 2

.loopTopSpace:

    fputs cowsay.espace

    loop .loopTopSpace

    fputs cowsay.bar

    putNewLine

.message:

    fputs cowsay.bar

    fputs cowsay.espace

    fputs [userMessage]

    fputs cowsay.espace

    fputs cowsay.bar

    putNewLine

    fputs cowsay.bar

    mov ecx, dword[userMessageSize]
    add ecx, 2

.loopBottomSpace:

    fputs cowsay.espace

    loop .loopBottomSpace

    fputs cowsay.bar

    putNewLine

    mov ecx, dword[userMessageSize]

    add ecx, 4

.loopBottomBubble:

    fputs cowsay.bottomLine

    loop .loopBottomBubble

    putNewLine

    cmp byte[externalFile], 0
    je .innerCow

    mov esi, [cowProfile]

    hx.syscall hx.stringSize

    mov ebx, eax

    mov al, byte[cowsay.extensionCOW+0]

    mov byte[esi+ebx+0], al

    mov al, byte[cowsay.extensionCOW+1]

    mov byte[esi+ebx+1], al

    mov al, byte[cowsay.extensionCOW+2]

    mov byte[esi+ebx+2], al

    mov al, byte[cowsay.extensionCOW+3]

    mov byte[esi+ebx+3], al

    mov byte[esi+ebx+4], 0 ;; End of string, will be cut here and nothing after will be relevant

    push esi

    hx.syscall hx.fileExists

    jc .innerCow

    pop esi

    mov edi, appFileBuffer

    hx.syscall hx.open

    jc .innerCow

    fputs appFileBuffer

    jmp .finish

.innerCow:

    fputs cowsay.cow

.finish:

    jmp finish

;;************************************************************************************

;; Obtains the necessary parameters, directly from the command line

getParameters:

    mov esi, [parameters]
    mov [cowProfile], esi

    cmp byte[esi], 0
    je applicationUsage

;; So let's go. Some things will be done here to check parameters, like changing
;; of the character to be displayed and the parameters to be sended to output


;; First, let's look for '"'. This indicates that it is a sentence and that you should skip the
;; searches for a character change parameter, which is the first parameter.
;; You must use this character to skip loading another character in the case of a sentence.
;; Otherwise, it will be interpreted that the first word is the character to be loaded from disk
;; and the message will be chopped up, even if the character does not exist in a .COW file on
;; disk. So, this will all be validated now.

;; First, let's validate that we have a sentence here

    mov al, '"' ;; Let's search for the sentence marker

    clc ;; Clean the Carry

    hx.syscall hx.findCharacter ;; Request character search service

    jnc .withoutExternalFile ;; A sentence marker was identified. Skip character load

;; Okay, we don't have a sentence. We have more than one parameter, what could identify a single
;; word after the character parameter? If the user did not enter the '"', it will be interpreted
;; as such.

    mov al, ' ' ;; Let's search if there is a space, which would indicate two or more words

    hx.syscall hx.findCharacter ;; Request character search service

;; We don't have more than one word, which indicates that there is no character chang

    jc .addMessage

;; So far we have validated individual phrases and words, without the need to load a character
;; directly from disk. If we got this far, it means that there is more than one word and the user
;; did not specify that it was a phrase, with the character '"'. Therefore, the first parameter,
;; which corresponds to the character, must be separated from the rest of the string, which is
;; what will be displayed to the user

    mov al, ' ' ;; Let's look for the position where the separation of the parameters occurs

    call findCharacterCowsay ;; This function belongs to the application, not the system API

;; The string properly cut and separated. File name trimming will be done later.

    mov [userMessage], esi
    jmp .done

;; An external character must be loaded and after it there is a word or sentence

.done:

    mov byte[externalFile], 01h ;; Mark that an external character should be loaded

    clc

    ret

;; Well, we have a sentence. We have to remove the '"' characters from the string to be printed.

.withoutExternalFile:

    clc ;; Clear the Carry

    mov esi, [cowProfile] ;; Let's take the parameter string provided by the system

    hx.syscall hx.trimString ;; Cut it (trimming) to be sure of the character positions

;; Now let's remove the '"' characters, remembering that only the first and last '"' characters
;; will be removed. Anyone inside the chain will remain, for now.

    mov eax, 00h ;; Position zero of the cut string, first '"'

    hx.syscall hx.removeCharacterString ;; Remove the character

    hx.syscall hx.stringSize ;; Now, how long is the residual chain?

    dec eax ;; The last character is always the terminator, so indent one. This is the last '"'

    hx.syscall hx.removeCharacterString ;; Remove the character

    mov [userMessage], esi ;; The message is ready to be displayed

    mov byte[externalFile], 00h ;; Mark as use of internal character

    ret

;; Now, the case of a word being passed as a parameter.
;; This means that, even if it references an external character, ignore it.
;; In this case, at least two terms must be passed. What's the point of carrying a character if
;; there is no message?
;; So, ignore the character and interpret it as a single word to be displayed. Basically, the
;; initial parameter will be transported to the memory space allocated to the message properly
;; ready for display

.addMessage:

    clc

    mov esi, [cowProfile]

    mov [userMessage], esi ;; The message is ready to be displayed

    mov byte[externalFile], 00h ;; Mark as use of internal character

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

findCharacterCowsay:

    lodsb

    cmp al, ' '
    je .done

    jmp findCharacterCowsay

.done:

    mov byte[esi-1], 0

    ret

;;************************************************************************************

applicationUsage:

    fputs cowsay.use

    jmp finish

;;************************************************************************************

finish:

    hx.syscall hx.exit

;;************************************************************************************

VERSION equ "2.4.0"

cowsay:

.use:
db 10, "Usage: cowsay [profile] [message]", 10, 10
db "Display a message to the user.", 10, 10
db "You can change the entity that displays the message.", 10
db "This change must be requested BEFORE the message.", 10
db 'In the case of a sentence, the character " must appear before and after the sentence.', 10, 10
db "cowsay version ", VERSION, 10, 10
db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.helpParameter:
db "?", 0
.helpParameter2:
db "--help", 0
.espace:
db " ", 0
.bar:
db "|", 0
.topLine:
db "_", 0
.bottomLine:
db "-", 0
.cow:
db "   \", 10
db "    \   ^__^", 10
db "     \  (oo)\_______", 10
db "        (__)\       )\/\", 10
db "             ||----w |", 10
db "             ||     ||", 0
.extensionCOW:
db ".cow", 0

parameters:      dd ?
cowProfile:      dd ?
userMessage:     dd ?
externalFile:    db 0
userMessageSize: dd 0

;;************************************************************************************

appFileBuffer: