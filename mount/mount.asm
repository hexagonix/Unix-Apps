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
include "erros.s"

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametros], edi
    
    mov esi, edi
    
    cmp byte[esi], 0
    je exibirMontagens
    
    call obterParametros
    
    jc  usoAplicativo
    
    mov edi, mount.parametroAjuda
    mov esi, [parametros]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, mount.dispositivoPadrao
    mov esi, [pontoMontagem]

    hx.syscall compararPalavrasString
    
    jc .realizarMontagem
    
    jmp erroPontoMontagem   
    
.realizarMontagem:
    
    mov esi, mount.volume
    
    imprimirString
    
    mov esi, [volume]
    
    imprimirString
    
    mov esi, mount.pontoMontagem
    
    imprimirString
    
    mov esi, [pontoMontagem]
    
    imprimirString
    
    mov esi, mount.fecharColchete
    
    imprimirString

    mov esi, [volume]
    
    hx.syscall hx.open
    
    jc erroAbertura
    
    mov esi, mount.montado
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

exibirMontagens:

    mov esi, mount.volumeMontado
  
    imprimirString  
    
    hx.syscall obterDisco
    
    push eax
    push edi
    push esi
    
    pop esi
    
    imprimirString
    
    mov esi, mount.infoVolume
    
    imprimirString
    
    mov esi, mount.dispositivoPadrao
    
    imprimirString
    
    mov esi, mount.rotuloVolume
    
    imprimirString
    
    pop edi
    
    mov esi, edi
    
    hx.syscall cortarString
    
    imprimirString
    
    mov esi, mount.parenteses1

    imprimirString

    pop eax

    cmp ah, 01h
    je .fat12

    cmp ah, 04h
    je .fat16_32

    cmp ah, 06h
    je .fat16

    jmp terminar

.fat12:

    mov esi, mount.FAT12

    imprimirString

    mov esi, mount.parenteses2

    imprimirString

    jmp terminar

.fat16_32:

    mov esi, mount.FAT16_32

    imprimirString

    mov esi, mount.parenteses2

    imprimirString

    jmp terminar

.fat16:

    mov esi, mount.FAT16

    imprimirString

    mov esi, mount.parenteses2

    imprimirString

    jmp terminar

;;************************************************************************************

erroPontoMontagem:

    mov esi, mount.erroPontoMontagem
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

erroAbertura:

    cmp eax, IO.operacaoNegada
    je .operacaoNegada

    mov esi, mount.erroAbrindo
    
    imprimirString

    jmp terminar

.operacaoNegada:

    mov esi, mount.operacaoNegada

    imprimirString

    jmp terminar

;;************************************************************************************

terminar:   

    hx.syscall encerrarProcesso

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

    mov esi, [parametros]
    mov [volume], esi
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov al, ' '
    
    hx.syscall encontrarCaractere
    
    jc usoAplicativo

    mov al, ' '
    
    call encontrarCaractereCP
    
    mov [pontoMontagem], esi
    
    jmp .pronto
    
.pronto:

    clc
    
    ret

;;************************************************************************************  

;; Realiza a busca de um caractere específico na String fornecida
;;
;; Entrada:
;;
;; ESI - String à ser verificada
;; AL  - Caractere para procurar
;;
;; Saída:
;;
;; ESI - Posição do caractere na String fornecida

encontrarCaractereCP:

    lodsb
    
    cmp al, ' '
    je .pronto
    
    jmp encontrarCaractereCP
    
.pronto:

    mov byte[esi-1], 0
    
    ret

;;************************************************************************************  

usoAplicativo:

    mov esi, mount.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************  

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoMOUNT equ "2.2.1"

mount:

.volume:            db 10, "Mounting [", 0
.fecharColchete:    db "]...", 10, 10, 0
.pontoMontagem:     db "] on [", 0
.montado:           db "Success mouting the volume.", 10, 0
.uso:               db 10, "Usage: mount [volume] [mount point]", 10, 10
                    db "Performs mounting a volume to a file system mount point.", 10, 10
                    db "If no parameter is provided, the mounting points will be displayed.", 10, 10
                    db "mount version ", versaoMOUNT, 10, 10
                    db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                    db "All rights reserved.", 0
.erroAbrindo:       db "Error mounting volume at specified mount point.", 10
                    db "Try to enter a valid name or reference of an attached volume.", 10, 0
.parametroAjuda:    db "?", 0
.dispositivoPadrao: db "/", 0
.erroPontoMontagem: db 10, "Please enter a valid mount point for this volume and file system.", 10, 0
.volumeMontado:     db 10, "Volume ", 0
.infoVolume:        db " mounted on ", 0
.rotuloVolume:      db " with the label ", 0
.operacaoNegada:    db "The mount was refused by the system. This may be explained due to the fact that the current user", 10
                    db "does not have administrative privileges, not being a root user (root).", 10, 10
                    db "Only the root user (root) can perform mounts. Login in this user to perform", 10
                    db "the desired mount.", 10, 0
.parenteses1:       db " (", 0
.parenteses2:       db ")", 0
.FAT16:             db "FAT16B", 0
.FAT12:             db "FAT12", 0
.FAT16_32:          db "FAT16 <32 MB", 0
              
parametros:    dd 0     
volume:        dd ?
pontoMontagem: dd ?
regES:         dw 0
     
