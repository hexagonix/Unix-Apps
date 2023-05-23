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

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov edi, fileUnix.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, fileUnix.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    mov esi, [parametro]
    
    hx.syscall cortarString
    
    hx.syscall tamanhoString
    
    cmp eax, 13
    jl .obterInformacoes
    
    fputs fileUnix.arquivoInvalido
    
    jmp .fim
    
.obterInformacoes:

    hx.syscall arquivoExiste

    jc .semArquivo
    
    push eax

    call manterArquivo

    fputs fileUnix.tamanhoArquivo
    
    pop eax 
    
    imprimirInteiro
    
    fputs fileUnix.bytes

;; Primeiro vamos ver se se trata de uma imagem executável. Se sim, podemos pular todo o
;; restante do processamento. Isso garante que imagens executáveis sejam relatadas como
;; tal mesmo se tiverem diferentes extensões, visto que cada shell pode procurar por um
;; tipo de extensão específico/preferido além de .APP. Imagens acessórias que necessitam
;; de ser chamadas por outro processo no âmbito de sua execução podem apresentar outra extensão.
;; O próprio Hexagon® é uma imagem HAPP mas apresenta extensão .SIS

    call verificarArquivoHAPP 
    
    call verificarArquivoHBoot

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

.continuar:

    mov esi, nomeArquivo

    hx.syscall stringParaMaiusculo    ;; Iremos checar com base na extensão em maiúsculo
    
    hx.syscall tamanhoString

    add esi, eax                     ;; Adicionar o tamanho do nome

    sub esi, 4                       ;; Subtrair 4 para manter apenas a extensão

    mov edi, fileUnix.extensaoUNX
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .UNX
    
    jc .arquivoUNX

    mov edi, fileUnix.extensaoSIS
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .SIS
    
    jc .arquivoSIS

    mov edi, fileUnix.extensaoTXT
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .TXT
    
    jc .arquivoTXT

    mov edi, fileUnix.extensaoASM
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .ASM
    
    jc .arquivoASM

    mov edi, fileUnix.extensaoCOW
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .COW
    
    jc .arquivoCOW

    mov edi, fileUnix.extensaoMAN
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .MAN
    
    jc .arquivoMAN

    mov edi, fileUnix.extensaoFNT
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .FNT
    
    jc .arquivoFNT

    mov edi, fileUnix.extensaoCAN
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .CAN
    
    jc .arquivoCAN

;; Checar agora com duas letras de extensão

;; Checar agora com uma única letra de extensão

    add esi, 2 ;; Adicionar 2 (seria uma remoção de 2) para manter apenas a extensão

    mov edi, fileUnix.extensaoS
    
    hx.syscall compararPalavrasString  ;; Checar por extensão .S
    
    jc .arquivoS

.semExtensaoValida:

    fputs fileUnix.arquivoPadrao

    jmp .fim

.aplicativo:

    fputs fileUnix.appValido

    jmp .fim

.arquivoHBoot:

    fputs fileUnix.arquivoHBoot

    jmp .fim

.arquivoUNX:

    fputs fileUnix.arquivoUnix

    jmp .fim

.arquivoTXT:

    fputs fileUnix.arquivoTXT

    jmp .fim

.arquivoFNT:

    fputs fileUnix.arquivoFNT

    jmp .fim

.arquivoCAN:

    fputs fileUnix.arquivoCAN

    jmp .fim

.arquivoCOW:

    fputs fileUnix.arquivoCOW

    jmp .fim

.arquivoMAN:

    fputs fileUnix.arquivoMAN

    jmp .fim

.arquivoSIS:

    fputs fileUnix.arquivoSIS

    jmp .fim

.arquivoASM:

    fputs fileUnix.arquivoASM

    jmp .fim

.arquivoS:

    fputs fileUnix.arquivoLibASM

    jmp .fim

.semArquivo:

    fputs fileUnix.semArquivo

    jmp .fim    
    
.fim:
    
    jmp terminar

;;************************************************************************************

verificarArquivoHAPP:

    mov esi, nomeArquivo
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc inicioAPP.semArquivo

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHAPP

    cmp byte[edi+1], "A"
    jne .naoHAPP

    cmp byte[edi+2], "P"
    jne .naoHAPP

    cmp byte[edi+3], "P"
    jne .naoHAPP

    jmp inicioAPP.aplicativo

.naoHAPP:

    ret

;;************************************************************************************

verificarArquivoHBoot:

    mov esi, nomeArquivo
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc inicioAPP.semArquivo

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHBoot

    cmp byte[edi+1], "B"
    jne .naoHBoot

    cmp byte[edi+2], "O"
    jne .naoHBoot

    cmp byte[edi+3], "O"
    jne .naoHBoot

    cmp byte[edi+4], "T"
    jne .naoHBoot

    jmp inicioAPP.arquivoHBoot

.naoHBoot:

    ret

;;************************************************************************************

usoAplicativo:

    fputs fileUnix.uso
    
    jmp terminar

;;************************************************************************************

manterArquivo:

    push esi
    push eax

    hx.syscall cortarString

    hx.syscall tamanhoString

    mov ecx, eax

    mov edi, nomeArquivo

    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI
    
    pop eax

    pop esi

    ret

;;************************************************************************************

terminar:   

    hx.syscall encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
    
versaoFILE equ "1.9.1.1"

fileUnix:

.uso:
db 10, "Usage: file [file]", 10, 10
db "Retrieve information from the file and send it to the main console.", 10, 10
db "file version ", versaoFILE, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.arquivoInvalido:
db 10, "The file name is invalid. Please enter a valid filename.", 0
.tamanhoArquivo:
db 10, "File size: ", 0
.bytes:
db " bytes.", 0
.semArquivo:
db 10, "The requested file is not available on this volume.", 10
db "Check the filename and try again.", 0  
.appValido:
db 10, "This appears to be a Unix executable for Hexagon(R).", 0
.arquivoHBoot:
db 10, "This appears to be an executable in HBoot format (HBoot or HBoot module).", 0
.arquivoASM:
db 10, "This appears to be an Assembly source file.", 0
.arquivoLibASM:
db 10, "This appears to be a source file that contains an Assembly development library.", 0
.arquivoSIS:
db 10, "This appears to be a system file.", 0
.arquivoUnix:
db 10, "This appears to be a Unix environment data or configuration file.", 0               
.arquivoMAN:
db 10, "This appears to be a manual file.", 0
.arquivoCOW:
db 10, "This appears to be a database file from the cowsay utility.", 0
.arquivoTXT:
db 10, "This appears to be a UTF-8 text file.", 0
.arquivoFNT:
db 10, "This appears to be a Hexagon(R) display font file.", 0
.arquivoCAN:
db 10, "This appears to be a Hexagonix(R) config plugin file.", 0
.arquivoPadrao:
db 10, "This appears to be a plain text file.", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.extensaoSIS:
db ".SIS", 0
.extensaoASM:
db ".ASM", 0
.extensaoBIN:
db ".BIN", 0
.extensaoUNX:
db ".UNX", 0
.extensaoFNT:
db ".FNT", 0
.extensaoOCL:
db ".OCL", 0
.extensaoMAN:
db ".MAN", 0
.extensaoCOW:
db ".COW", 0
.extensaoTXT:
db ".TXT", 0
.extensaoCAN:
db ".CAN", 0
.extensaoS:
db ".S", 0

parametro:            dd ?
regES:                dw 0
nomeArquivo: times 13 db 0

bufferArquivo: