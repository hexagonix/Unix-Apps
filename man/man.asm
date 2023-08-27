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
;;                    Sistema Operacional Hexagonix® - Hexagonix® Operating System
;;
;;                          Copyright © 2015-2023 Felipe Miguel Nery Lunkes
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
include "macros.s"

;;************************************************************************************

versaoMAN equ "2.3.4.3"

versaoCoreUtils equ "Raava-CURRENT-6.1" 
versaoUnixUtils equ "Raava-CURRENT-6.1"

align 32

man:

.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help",0
.man:
db "Hexagonix manual", 0
.uso:
db 10, "Usage: man [utility]", 10, 10
db "Display detailed help for installed Unix utilities.", 10, 10
db "CoreUtils version: ", versaoCoreUtils, 10
db "UnixUtils Version: ", versaoUnixUtils, 10, 10
db "man version ", versaoMAN, 10, 10
db "Copyright (C) 2018-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 10
db "Hexagonix is distributed under the BSD-3-Clause license.", 0
.aguardar:
db "Press <q> to exit.", 0
.naoEncontrado:
db ": manual not found for this utility.", 0
.separador:
db 10, "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++", 10, 0
.extensaoManual:
db ".man", 0

;;************************************************************************************

inicioAPP:

    mov [utilitario], edi

    cmp byte[edi], 0
    je usoAplicativo

    mov edi, man.parametroAjuda
    mov esi, [utilitario]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, man.parametroAjuda2
    mov esi, [utilitario]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov esi, [utilitario]

    hx.syscall tamanhoString

    mov ebx, eax

    mov al, byte[man.extensaoManual+0]
    
    mov byte[esi+ebx+0], al
    
    mov al, byte[man.extensaoManual+1]
    
    mov byte[esi+ebx+1], al
    
    mov al, byte[man.extensaoManual+2]
    
    mov byte[esi+ebx+2], al
    
    mov al, byte[man.extensaoManual+3]
    
    mov byte[esi+ebx+3], al
    
    mov byte[esi+ebx+4], 0      ;; Fim da string

    push esi

    hx.syscall arquivoExiste

    jc manualNaoEncontrado

    mov edi, bufferArquivo

    pop esi
    
    hx.syscall hx.open
    
    jc manualNaoEncontrado

;; Preparação do ambiente

    hx.syscall limparTela

    call montarInterface
    
    fputs bufferArquivo

    jmp terminar

;;************************************************************************************

montarInterface:
    
    fputs man.man

    mov ecx, 24

.loopEspaco:

    mov al, ' '
    
    hx.syscall imprimirCaractere
    
    dec ecx
    
    cmp ecx, 0
    je .terminado
    
    jmp .loopEspaco

.terminado:

    fputs [utilitario]

    novaLinha
    novaLinha

    ret

;;************************************************************************************

manualNaoEncontrado:

    novaLinha

    fputs [utilitario]

    fputs man.naoEncontrado

   jmp terminar

;;************************************************************************************

usoAplicativo:

    fputs man.uso
    
    jmp terminar

;;************************************************************************************

terminar:   

    hx.syscall encerrarProcesso
    
;;*****************************************************************************

utilitario: dd ?

bufferArquivo:
