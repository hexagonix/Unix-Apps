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

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo.

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioAPP, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************
;;
;; Dados do aplicativo
;;
;;************************************************************************************

versaoFNT equ "0.6.7"

fnt:

.uso:
db 10, "Usage: fnt [graphic font file]", 10, 10
db "Changes the system font.", 10, 10
db "fnt version ", versaoFNT, 10, 10
db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.nomeArquivo:
db 10, "Font filename: ", 0
.nomeFonte:
db "Filename: ", 0
.falhaFormato:
db 10, "The file does not contain a font in Hexagon format.", 0
.sucesso:
db 10, 10, "Font changed successfully.", 0
.falha:
db 10, "File not found.", 0
.introducaoTeste:
db 10, "Font preview: ", 0
.testeFonte:
db 10, 10
db "Hexagonix Operating System", 10, 10
db "1234567890-=", 10
db "!@#$%^&*()_+", 10
db "QWERTYUIOP{}", 10
db "qwertyuiop[]", 10
db 'ASDFGHJKL:"|', 10
db "asdfghjkl;'\", 10
db "ZXCVBNM<>?", 10
db "zxcvbnm,./", 10, 10
db "Hexagonix Operating System", 10, 0
.tamanhoSuperior:
db 10, "This font file exceeds the maximum size of 2 Kb.", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0

parametro: dd 0
regES:     dw 0

;;************************************************************************************

inicioAPP:

    mov [regES], es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov [parametro], edi

    mov esi, [parametro]

    cmp byte[esi], 0
    je usoAplicativo

    mov edi, fnt.parametroAjuda
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, fnt.parametroAjuda2
    mov esi, [parametro]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    fputs fnt.nomeArquivo

    fputs [parametro]

    mov esi, [parametro]

    hx.syscall cortarString ;; Remover espaços em branco extras

    call validarFonte

    jc .erroFormato

    hx.syscall alterarFonte

    jc .erroTexto

    fputs fnt.sucesso

    fputs fnt.introducaoTeste

    fputs fnt.testeFonte

    mov ebx, 00h

    hx.syscall encerrarProcesso

.erroTexto:

    fputs fnt.falha

    jmp .erroFim

.erroFormato:

    fputs fnt.falhaFormato

    jmp .erroFim

.erroFim:

    mov ebx, 00h

    jmp terminar

;;************************************************************************************

terminar:

    mov ebx, 00h

    hx.syscall encerrarProcesso

;;************************************************************************************

usoAplicativo:

    fputs fnt.uso

    jmp terminar

;;************************************************************************************

validarFonte:

    mov esi, [parametro]
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc .erroSemFonte

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHFNT

    cmp byte[edi+1], "F"
    jne .naoHFNT

    cmp byte[edi+2], "N"
    jne .naoHFNT

    cmp byte[edi+3], "T"
    jne .naoHFNT

.verificarTamanho:

    hx.syscall arquivoExiste

;; Em EAX, o tamanho do arquivo. Ele não deve ser maior que 2000 bytes, o que poderia
;; sobrescrever dados na memória do Hexagon

    mov ebx, 2000

    cmp eax, ebx
    jng .continuar

    jmp .tamanhoSuperior

.continuar:

    clc

    ret

.erroSemFonte:

    fputs fnt.falha

    jmp terminar

.naoHFNT:

    stc

    ret

.tamanhoSuperior:

    fputs fnt.tamanhoSuperior

    jmp terminar

;;************************************************************************************

bufferArquivo:
