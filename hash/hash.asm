;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2022 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2022, Felipe Miguel Nery Lunkes
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioShell, 01h

;;************************************************************************************

include "hexagon.s"
include "erros.s"
include "macros.s"

;;************************************************************************************

inicioShell:    

    mov [linhaComando], edi
    
    mov edi, hash.parametroAjuda
    mov esi, [linhaComando]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, hash.parametroAjuda2
    mov esi, [linhaComando]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
        
    mov esi, [linhaComando]
            
    cmp byte[esi], 0
    je .iniciar

.iniciar:

;; Iniciar a configuração do terminal
    
    novaLinha
    
    Hexagonix obterInfoTela

    mov byte[maxColunas], bl
    mov byte[maxLinhas], bh

    Hexagonix obterCursor
    
    dec dh
    
    Hexagonix definirCursor
    
    novaLinha
    
.iniciarSessao:

    Hexagonix obterUsuario
    
    push eax
    
    push es
    
    push  ds
    pop es
    
    push  esi
    
    Hexagonix tamanhoString
    
    pop esi
    
    push  eax
    
    mov edi, hash.nomeUsuario
    
    pop ecx
    
    rep movsb
    
    pop es  
    
    pop eax
    
    cmp eax, 555
    je .usuarioNormal
    
    cmp eax, 777
    je .usuarioRoot
    
.usuarioNormal:

    push  es
    
    push  ds
    pop es
    
    mov esi, hash.usuarioNormal
    
    Hexagonix tamanhoString
    
    push  eax
    
    mov edi, hash.separador
    mov esi, hash.usuarioNormal
    
    pop ecx
    
    rep movsb
    
    pop es  
    
    jmp .finalizarPrompt

.usuarioRoot:

    push  es
    
    push  ds
    pop es
    
    mov esi, hash.usuarioRoot
    
    Hexagonix tamanhoString
    
    push  eax
    
    mov edi, hash.separador
    mov esi, hash.usuarioRoot
    
    pop ecx
    
    rep movsb
    
    pop es  
    
    jmp .finalizarPrompt

;;************************************************************************************

.finalizarPrompt:

    mov esi, hash.separador
    
    Hexagonix tamanhoString
    
    inc eax
    
    mov byte[hash.separador+eax], 0
    
;;************************************************************************************

.obterComando:  

    novaLinha
   
    Hexagonix obterCursor
    
    Hexagonix definirCursor
    
    mov esi, hash.nomeUsuario
    
    imprimirString
    
    mov esi, hash.prompt
    
    imprimirString
    
    mov esi, hash.separador
    
    imprimirString
    
    mov al, byte[maxColunas]         ;; Máximo de caracteres para obter

    sub al, 20
    
    Hexagonix obterString
    
    Hexagonix cortarString           ;; Remover espaços em branco extras
        
    cmp byte[esi], 0                 ;; Nenhum comando inserido
    je .obterComando
    
;; Comparar com comandos internos disponíveis

    ;; Comando SAIR
    
    mov edi, comandos.sair      
    
    Hexagonix compararPalavrasString

    jc finalizarhashell

;;************************************************************************************

;; Tentar carregar um programa
    
    call obterArgumentos              ;; Separar comando e argumentos
    
    push  esi
    push  edi
    
    jmp .carregarPrograma
    
.falhaExecutando:

;; Agora o erro enviado pelo sistema será analisado, para que o Shell conheça
;; sua natureza

    cmp eax, Hexagon.limiteProcessos ;; Limite de processos em execução atingido
    je .limiteAtingido               ;; Se sim, exibir a mensagem apropriada
    
    cmp eax, Hexagon.imagemInvalida
    je .imagemHAPPInvalida

    Hexagonix obterCursor
    
    mov dl, byte[maxColunas]    ;; Máximo de caracteres para obter

    sub dl, 17
    
    Hexagonix definirCursor
    
    push esi
    
    novaLinha
    novaLinha
    
    pop esi
    
    imprimirString
    
    mov esi, hash.comandoNaoEncontrado
    
    imprimirString
    
    jmp .obterComando   
    
.limiteAtingido:

    Hexagonix obterCursor
    
    mov dl, byte[maxColunas]    ;; Máximo de caracteres para obter

    sub dl, 17
    
    Hexagonix definirCursor
    
    mov esi, hash.limiteProcessos
    
    imprimirString
    
    jmp .obterComando   

.imagemHAPPInvalida:

    push esi

    Hexagonix obterCursor
    
    mov dl, byte[maxColunas]    ;; Máximo de caracteres para obter

    sub dl, 17
    
    Hexagonix definirCursor
    
    novaLinha
    novaLinha
    
    pop esi
    
    imprimirString

    mov esi, hash.imagemInvalida
    
    imprimirString
    
    jmp .obterComando   

.carregarPrograma:
    
    pop edi

    mov esi, edi
    
    Hexagonix cortarString
    
    pop esi
    
    mov eax, edi
    
    stc
    
    Hexagonix iniciarProcesso
    
    jc .falhaExecutando
    
    jmp .obterComando

;;************************************************************************************

;;************************************************************************************
;;
;; Fim dos comandos internos do shell Unix do Hexagonix®
;;
;; Funções úteis para o manipulação de dados no hashell Unix do Hexagonix® 
;;
;;************************************************************************************

;; Separar nome de comando e argumentos
;;
;; Entrada:
;;
;; ESI - Endereço do comando
;; 
;; Saída:
;;
;; ESI - Endereço do comando
;; EDI - Argumentos do comando
;; CF  - Definido em caso de falta de extensão

obterArgumentos:

    push  esi
    
.loop:

    lodsb           ;; mov AL, byte[ESI] & inc ESI
    
    cmp al, 0
    je .naoencontrado
    
    cmp al, ' '
    je .espacoEncontrado
    
    jmp .loop
    
.naoencontrado:

    pop esi
    
    mov edi, 0
    
    stc
    
    jmp .fim

.espacoEncontrado:

    mov byte[esi-1], 0
    mov ebx, esi
    
    Hexagonix tamanhoString
    
    mov ecx, eax
    
    inc ecx         ;; Incluindo o último caractere (NULL)
    
    push es
    
    push ds
    pop es
    
    mov esi, ebx
    mov edi, bufferArquivo
    
    rep movsb       ;; Copiar (ECX) caracteres da string de ESI para EDI
    
    pop es
    
    mov edi, bufferArquivo
    
    pop esi
    
    clc
    
.fim:

    ret
    
;;************************************************************************************

usoAplicativo:

    mov esi, hash.uso
    
    imprimirString
    
    jmp finalizarhashell    

;;************************************************************************************

finalizarhashell:
    
    mov ebx, 00h
    
    Hexagonix encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;; Dados, variáveis e constantes utilizadas pelo hash
;;
;;************************************************************************************

;; A versão do hash é independente da versão do restante do sistema.
;; Ela deve ser utilizada para identificar para qual versão do Hexagonix® o hash foi
;; desenvolvido.

versaoHASH equ "1.0"

hash:

.prompt:               db "@Hexagonix", 0
.comandoNaoEncontrado: db ": file not found.", 10, 0
.imagemInvalida:       db ": unable to load image. Unsupported executable format.", 10, 0
.limiteProcessos:      db 10, 10, "There is not enough memory available to run the requested application.", 10
                       db "Try to terminate applications or their instances first, and try again.", 10, 0                  
.ponto:                db ".", 0
.usuarioNormal:        db "$ ", 0
.usuarioRoot:          db "# ", 0
.uso:                  db 10, 10, "Usage: hash", 10, 10
                       db "Start a Unix shell for the current user.", 10, 10
                       db "hash version ", versaoHASH, 10, 10
                       db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
                       db "All rights reserved.", 10, 0
.parametroAjuda:       db "?", 0   
.parametroAjuda2:      db "--help", 0   
.nomeUsuario: times 64 db 0
.separador:    times 8 db 0
 
;;**************************

comandos:

.sair: db "sair",0

;;**************************

maxColunas:   db 0 ;; Total de colunas disponíveis no vídeo na resolução atual
maxLinhas:    db 0 ;; Total de linhas disponíveis no vídeo na resolução atual
linhaComando: dd 0
                   
;;************************************************************************************

bufferArquivo:  ;; Endereço para carregamento de arquivos
