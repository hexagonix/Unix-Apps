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
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoLSHMOD equ "0.5"

lshmod:

.uso:                 db 10, 10, "Usage: lshmod [file]", 10, 10
                      db "Retrieve information from an HBoot image or module.", 10, 10
                      db "lshmod version ", versaoLSHMOD, 10, 10
                      db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
                      db "All rights reserved.", 10, 0
.arquivoInvalido:     db 10, 10, "The file name is invalid. Please enter a valid filename.", 10, 0
.infoArquivo:         db 10, 10, "Filename: ", 0
.tamanhoArquivo:      db 10, "Size of this file: ", 0
.bytes:               db " bytes.", 10, 0
.imagemInvalida:      db 10, "<!> This is not an HBoot module image. Try another file.", 10, 0
.semArquivo:          db 10, 10, "<!> The requested file is not available on this volume.", 10, 10
                      db "<!> Check the file name and try again.", 10, 0  
.tipoArquitetura:     db 10, 10, "> Target architecture: ", 0
.verModulo:           db 10, "> Module version: ", 0
.ponto:               db ".", 0
.cabecalho:           db 10, "<+> This file contains a valid HBoot image or HBoot module.", 0
.i386:                db "i386", 0
.amd64:               db "amd64", 0
.arquiteturaInvalida: db "unknown", 0
.entradaCodigo:       db 10, "> Internal name of the HBoot image or module: ", 0
.parametroAjuda:      db "?", 0
.parametroAjuda2:     db "--help", 0
.nomeMod:             dd 0
.arquitetura:         db 0
.verMod:              db 0
.subverMod:           db 0

parametro:            dd ?
nomeArquivo: times 13 db 0
regES:                dw 0
nomeModulo: times 8   db 0

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov edi, lshmod.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, lshmod.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov esi, [parametro]
    
    Hexagonix cortarString
    
    Hexagonix tamanhoString
    
    cmp eax, 13
    jl .obterInformacoes
    
    mov esi, lshmod.arquivoInvalido
    
    imprimirString
    
    jmp .fim
    
.obterInformacoes:

    Hexagonix arquivoExiste

    jc .semArquivo
    
    push eax
    push esi

    mov esi, lshmod.infoArquivo
    
    imprimirString
    
    pop esi

    call manterArquivo

    imprimirString

    mov esi, lshmod.tamanhoArquivo
    
    imprimirString
    
    pop eax 
    
    imprimirInteiro
    
    mov esi, lshmod.bytes
    
    imprimirString

;; Primeiro vamos ver se se trata de uma imagem executável. Se sim, podemos pular todo o
;; restante do processamento. Isso garante que imagens executáveis sejam relatadas como
;; tal mesmo se tiverem diferentes extensões, visto que cada shell pode procurar por um
;; tipo de extensão específico/preferido além de .APP. Imagens acessórias que necessitam
;; de ser chamadas por outro processo no âmbito de sua execução podem apresentar outra extensão.
;; O próprio Hexagon® é uma imagem HAPP mas apresenta extensão .SIS

    call verificarArquivoHBootMod

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

    jmp .fim

.semArquivo:

    mov esi, lshmod.semArquivo
   
    imprimirString

    jmp .fim    
    
.fim:
    
    novaLinha

    jmp terminar

;;************************************************************************************

verificarArquivoHBootMod:

    mov esi, nomeArquivo
    mov edi, bufferArquivo

    Hexagonix abrir

    jc inicioAPP.semArquivo

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHBootMod

    cmp byte[edi+1], "B"
    jne .naoHBootMod

    cmp byte[edi+2], "O"
    jne .naoHBootMod

    cmp byte[edi+3], "O"
    jne .naoHBootMod

    cmp byte[edi+4], "T"
    jne .naoHBootMod

    mov dh, byte[edi+5]
    mov byte[lshmod.arquitetura], dh

    mov dh, byte[edi+6]
    mov byte[lshmod.verMod], dh

    mov dh, byte[edi+7]
    mov byte[lshmod.subverMod], dh

    mov esi, dword[edi+8]
    mov dword[nomeModulo+0], esi

    mov esi, dword[edi+12]
    mov dword[nomeModulo+4], esi

    mov dword[nomeModulo+8], 0

    mov esi, nomeModulo

    Hexagonix cortarString

    mov esi, lshmod.cabecalho
    
    imprimirString

    mov esi, lshmod.tipoArquitetura

    imprimirString

    cmp byte[lshmod.arquitetura], 01h
    je .i386

    cmp byte[lshmod.arquitetura], 02h
    je .amd64

    cmp byte[lshmod.arquitetura], 02h
    jg .arquiteturaInvalida

.i386:

    mov esi, lshmod.i386

    imprimirString

    jmp .continuar

.amd64:

    mov esi, lshmod.amd64

    imprimirString

    jmp .continuar

.arquiteturaInvalida:

    mov esi, lshmod.arquiteturaInvalida

    imprimirString

    jmp .continuar

.continuar:

    mov esi, lshmod.ponto

    imprimirString

    mov esi, lshmod.verModulo

    imprimirString

    mov dh, byte[lshmod.verMod]
    movzx eax, dh

    imprimirInteiro

    mov esi, lshmod.ponto

    imprimirString

    mov dh, byte[lshmod.subverMod]
    movzx eax, dh

    imprimirInteiro

    mov esi, lshmod.ponto

    imprimirString

    mov esi, lshmod.entradaCodigo

    imprimirString

    mov esi, nomeModulo
    
    imprimirString

    mov esi, lshmod.ponto

    imprimirString

    ret

.naoHBootMod:

    mov esi, lshmod.imagemInvalida

    imprimirString

    ret

;;************************************************************************************

usoAplicativo:

    mov esi, lshmod.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

manterArquivo:

    push esi
    push eax

    Hexagonix cortarString

    Hexagonix tamanhoString

    mov ecx, eax

    mov edi, nomeArquivo

    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI
    
    pop eax

    pop esi

    ret

;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

bufferArquivo:
