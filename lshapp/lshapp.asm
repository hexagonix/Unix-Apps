;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2023 Felipe Miguel Nery Lunkes
;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
;;              ┌─┘│                 Licenciado sob licença BSD-3-Clause
;;              └──┘          
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
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

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo. Anteriormente,
;; o cabeçalho era criado em cada imagem e poderia diferir de uma para outra. Caso algum
;; campo da especificação HAPP mudasse, os cabeçalhos de todos os aplicativos deveriam ser
;; alterados manualmente. Com uma estrutura padronizada, basta alterar um arquivo que deve
;; ser incluído e montar novamente o aplicativo, sem a necessidade de alterar manualmente
;; arquivo por arquivo. O arquivo contém uma estrutura instanciável com definição de 
;; parâmetros no momento da instância, tornando o cabeçalho tão personalizável quanto antes.

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
    
    mov edi, lshapp.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, lshapp.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov esi, [parametro]
    
    hx.syscall cortarString
    
    hx.syscall tamanhoString
    
    cmp eax, 13
    jl .obterInformacoes
    
    fputs lshapp.arquivoInvalido
    
    jmp .fim
    
.obterInformacoes:

    hx.syscall arquivoExiste

    jc .semArquivo
    
    push eax
    push esi

    fputs lshapp.infoArquivo
        
    pop esi

    call manterArquivo

    imprimirString

    fputs lshapp.tamanhoArquivo
    
    pop eax 
    
    imprimirInteiro
    
    fputs lshapp.bytes

;; Primeiro vamos ver se se trata de uma imagem executável. Se sim, podemos pular todo o
;; restante do processamento. Isso garante que imagens executáveis sejam relatadas como
;; tal mesmo se tiverem diferentes extensões, visto que cada shell pode procurar por um
;; tipo de extensão específico/preferido além de .APP. Imagens acessórias que necessitam
;; de ser chamadas por outro processo no âmbito de sua execução podem apresentar outra extensão.
;; O próprio Hexagon® é uma imagem HAPP mas apresenta extensão .SIS

    call verificarArquivoHAPP 

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

    jmp .fim

.semArquivo:

    fputs lshapp.semArquivo

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

    mov dh, byte[edi+4]
    mov byte[lshapp.arquitetura], dh

    mov dh, byte[edi+5]
    mov byte[lshapp.versaoMinima], dh

    mov dh, byte[edi+6]
    mov byte[lshapp.subverMinima], dh

    mov eax, dword[edi+7]
    mov dword[lshapp.pontoEntrada], eax

    mov ah, byte[edi+11]
    mov byte[lshapp.especieImagem], ah

    fputs lshapp.cabecalho

    fputs lshapp.tipoArquitetura

    cmp byte[lshapp.arquitetura], 01h
    je .i386

    cmp byte[lshapp.arquitetura], 02h
    je .amd64

    cmp byte[lshapp.arquitetura], 02h
    jg .arquiteturaInvalida

.i386:

    fputs lshapp.i386

    jmp .continuar

.amd64:

    fputs lshapp.amd64

    jmp .continuar

.arquiteturaInvalida:

    fputs lshapp.arquiteturaInvalida

    jmp .continuar

.continuar:

    fputs lshapp.campoArquitetura

    fputs lshapp.verHexagon

    mov dh, byte[lshapp.versaoMinima]
    movzx eax, dh

    imprimirInteiro

    fputs lshapp.ponto

    mov dh, byte[lshapp.subverMinima]
    movzx eax, dh

    imprimirInteiro

    fputs lshapp.camposVersaoHexagon

    fputs lshapp.entradaCodigo

    mov eax, dword[lshapp.pontoEntrada]
    
    imprimirHexadecimal

    fputs lshapp.campoEntrada

    fputs lshapp.tipoImagem

    ;; mov dh, byte[lshapp.especieImagem]
    ;; movzx eax, dh

    ;; imprimirInteiro

    cmp byte[lshapp.especieImagem], 01h
    je .HAPPExec

    cmp byte[lshapp.especieImagem], 02h
    je .HAPPLibS

    cmp byte[lshapp.especieImagem], 03h
    je .HAPPLibD

    fputs lshapp.HAPPDesconhecido

    jmp .tipoHAPPListado

.HAPPExec:

    fputs lshapp.HAPPExec

    jmp .tipoHAPPListado

.HAPPLibS:

    fputs lshapp.HAPPLibS

    jmp .tipoHAPPListado

.HAPPLibD:

    fputs lshapp.HAPPLibD

    jmp .tipoHAPPListado

.tipoHAPPListado:

    fputs lshapp.campoImagem

    ret

.naoHAPP:

    fputs lshapp.imagemInvalida

    ret

;;************************************************************************************

usoAplicativo:

    fputs lshapp.uso
    
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

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

align 16

versaoLSHAPP equ "1.10.3"

lshapp:

.uso:                 db 10, "Usage: lshapp [file]", 10, 10
                      db "Retrieve and display information from a HAPP image.", 10, 10
                      db "lshapp version ", versaoLSHAPP, 10, 10
                      db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
                      db "All rights reserved.", 0
.arquivoInvalido:     db 10, 10, "The filename is invalid. Please enter a valid filename.", 10, 0
.infoArquivo:         db 10, "Filename: ", 0
.tamanhoArquivo:      db 10, "Size of this file: ", 0
.bytes:               db " bytes.", 10, 0
.imagemInvalida:      db 10, "<!> This is not a valid HAPP image. Try another file.", 10, 0
.semArquivo:          db 10, 10, "<!> The requested file is not available on this volume.", 10, 10
                      db "<!> Check the file name and try again.", 10, 0  
.tipoArquitetura:     db 10, 10, "> Image target architecture: ", 0
.verHexagon:          db 10, "> Minimum version of Hexagon(R) required to run: ", 0
.camposVersaoHexagon: db " -> [HAPP:version and HAPP:subversion].", 0
.cabecalho:           db 10, "<+> This file contains a valid HAPP image.", 0
.i386:                db "i386", 0
.amd64:               db "amd64", 0
.campoArquitetura:    db " -> [HAPP:arch].", 0
.arquiteturaInvalida: db "unknown", 0
.entradaCodigo:       db 10, "> Image entry point: ?:", 0
.campoEntrada:        db " -> [HAPP:entryPoint].", 0
.tipoImagem:          db 10, "> HAPP image format (type): ", 0
.HAPPExec:            db "(Exec)", 0
.HAPPLibS:            db "(LibS)", 0
.HAPPLibD:            db "(LibD)", 0
.HAPPDesconhecido:    db "(?)", 0
.campoImagem:         db " -> [HAPP:imageFormat].", 0
.parametroAjuda:      db "?", 0
.parametroAjuda2:     db "--help", 0
.ponto:               db ".", 0
.pontoEntrada:        dd 0
.arquitetura:         db 0
.versaoMinima:        db 0
.subverMinima:        db 0
.especieImagem:       db 0

parametro:            dd ?
nomeArquivo: times 13 db 0
regES:                dw 0

;;************************************************************************************

bufferArquivo:
