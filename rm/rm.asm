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
include "console.s"
include "macros.s"
include "erros.s"

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je semParametro
    
    mov edi, rm.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, rm.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    mov esi, [parametro]
    
    hx.syscall arquivoExiste
    
    jc .arquivoNaoEncontrado
    
    novaLinha
    
    fputs rm.confirmacao
        
.obterTeclas:

    hx.syscall aguardarTeclado
    
    cmp al, 'y'
    je .deletar
    
    cmp al, 'Y'
    je .deletar
    
    cmp al, 'n'
    je .abortar
    
    cmp al, 'N'
    je .abortar

    jmp .obterTeclas        
    
    
.arquivoNaoEncontrado:

    fputs rm.naoEncontrado
        
    jmp terminar

.deletar:

    hx.syscall imprimirCaractere
    
    mov esi, [parametro]
    
    hx.syscall hx.unlink
    
    jc .erroDeletando
    
    ;; fputs rm.deletado
        
    jmp terminar

.abortar:

    hx.syscall imprimirCaractere
    
    fputs rm.abortar
        
    jmp terminar
    
.erroDeletando:

    push eax

    fputs rm.erroDeletando
        
    pop eax
    
    cmp eax, IO.operacaoNegada
    je .permissaoNegada
    
    jmp terminar

.permissaoNegada:

    fputs rm.permissaoNegada
        
    jmp terminar
    
;;************************************************************************************

usoAplicativo:

    fputs rm.uso
        
    jmp terminar

;;************************************************************************************

semParametro:

    fputs rm.semParametro
        
    jmp terminar

;;************************************************************************************

terminar:   

    hx.syscall encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoRM equ "1.1.4.1"

rm:

.naoEncontrado:
db 10, "File not found.", 0
.uso:
db 10, "Usage: rm [file]", 10, 10
db "Requests to delete a file on the current volume.", 10, 10
db "rm version ", versaoRM, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.confirmacao:
db "Are you sure you want to delete this file (y/N)? ", 0
.deletado:
db 10, "The requested file was successfully removed.", 0
.erroDeletando:
db 10, "An error occurred during the request. No files were removed.", 0  
.abortar:
db 10, "The operation was aborted by the user.", 0  
.parametroAjuda:
db "?", 0  
.parametroAjuda2:
db "--help", 0    
.semParametro:
db 10, "A required filename is missing.", 10
db "Use 'rm ?' for help with this utility.", 0
.permissaoNegada:
db "Only an administrative (or root) user can complete this action.", 10
db "Login in this user to perform the desired operation.", 0                 
    
parametro: dd ?
regES:     dw 0
     
bufferArquivo:
