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
include "macros.s"
include "erros.s"

;;************************************************************************************

inicioShell:    

    mov [linhaComando], edi
    
    mov edi, sh.parametroAjuda
    mov esi, [linhaComando]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    mov edi, sh.parametroAjuda2
    mov esi, [linhaComando]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
        
    mov esi, [linhaComando]
            
    cmp byte[esi], 0
    je .iniciar

.iniciar:

;; Iniciar a configuração do terminal
    
    novaLinha
    
    hx.syscall obterInfoTela

    mov byte[maxColunas], bl
    mov byte[maxLinhas], bh

    hx.syscall obterCursor
    
    dec dh
    
    hx.syscall definirCursor

    novaLinha

.processarRC:

    mov esi, sh.arquivorc

    hx.syscall arquivoExiste

    jc .continuar 

    jmp .processarArquivoShell

.processarArquivoShell:

    mov esi, sh.arquivorc
    mov edi, bufferArquivo

    hx.syscall abrir 

    novaLinha

    fputs bufferArquivo

    jmp .continuar

.continuar:
    
.iniciarSessao:

    hx.syscall obterUsuario
    
    push eax
    
    push es
    
    push ds
    pop es
    
    push esi
    
    hx.syscall tamanhoString
    
    pop esi
    
    push eax
    
    mov edi, sh.nomeUsuario
    
    pop ecx
    
    rep movsb
    
    pop es  
    
    pop eax
    
    cmp eax, 555
    je .usuarioNormal
    
    cmp eax, 777
    je .usuarioRoot
    
.usuarioNormal:

    push es
    
    push ds
    pop es
    
    mov esi, sh.usuarioNormal
    
    hx.syscall tamanhoString
    
    push eax
    
    mov edi, sh.separador
    mov esi, sh.usuarioNormal
    
    pop ecx
    
    rep movsb
    
    pop es  
    
    jmp .finalizarPrompt

.usuarioRoot:

    push es
    
    push ds
    pop es
    
    mov esi, sh.usuarioRoot
    
    hx.syscall tamanhoString
    
    push eax
    
    mov edi, sh.separador
    mov esi, sh.usuarioRoot
    
    pop ecx
    
    rep movsb
    
    pop es  
    
    jmp .finalizarPrompt

;;************************************************************************************

.finalizarPrompt:

    mov esi, sh.separador
    
    hx.syscall tamanhoString
    
    inc eax
    
    mov byte[sh.separador+eax], 0
    
;;************************************************************************************

.obterComando:  

    novaLinha
   
    hx.syscall obterCursor
    
    hx.syscall definirCursor
    
    fputs sh.nomeUsuario
        
    fputs sh.prompt
        
    fputs sh.separador
    
    mov al, byte[maxColunas]         ;; Máximo de caracteres para obter

    sub al, 20
    
    hx.syscall obterString
    
    hx.syscall cortarString           ;; Remover espaços em branco extras
        
    cmp byte[esi], 0                 ;; Nenhum comando inserido
    je .obterComando
    
;; Comparar com comandos internos disponíveis

    ;; Comando SAIR
    
    mov edi, comandos.sair      
    
    hx.syscall compararPalavrasString

    jc finalizarShell

    ;; Comando EXEC

    mov edi, comandos.exec      
    
    hx.syscall compararPalavrasString

    jc executarExec ;; Iniciar a execução de arquivo em lote

;;************************************************************************************

;; Tentar carregar um programa
    
    call obterArgumentos ;; Separar comando e argumentos
    
.entradaCarregamentoImagem:

    push esi
    push edi
    
    jmp .carregarPrograma
    
.falhaExecutando:

;; Agora o erro enviado pelo Sistema será analisado, para que o Shell conheça
;; sua natureza

    cmp eax, Hexagon.limiteProcessos ;; Limite de processos em execução atingido
    je .limiteAtingido               ;; Se sim, exibir a mensagem apropriada
    
    cmp eax, Hexagon.imagemInvalida
    je .imagemHAPPInvalida
    
    push esi
    
    novaLinha
    
    pop esi
    
    imprimirString
    
    fputs sh.comandoNaoEncontrado
        
    jmp .obterComando   
    
.limiteAtingido:

    novaLinha

    fputs sh.limiteProcessos
        
    jmp .obterComando   

.imagemHAPPInvalida:

    push esi

    novaLinha
    
    pop esi
    
    imprimirString

    fputs sh.imagemInvalida
    
    jmp .obterComando   

.carregarPrograma:
    
    pop edi

    mov esi, edi
    
    hx.syscall cortarString
    
    pop esi
    
    mov eax, edi
    
    stc
    
    hx.syscall iniciarProcesso
    
    jc .falhaExecutando
    
    jmp .obterComando

;;************************************************************************************

;; Outras funções auxiliares 

executarExec:

    add esi, 04h
    
    hx.syscall cortarString

    cmp byte[esi], 0
    je .argumentonNecessario

    mov word[sh.posicaoBX], 0FFFFh ;; A cada execução, zerar o contador.

    mov edi, bufferArquivo
    
    hx.syscall hx.open
    
    jc .arquivoShellAusente

    call procurarComandos

    jc .naoEncontrado

.carregarImagem:

    mov esi, sh.imagemDisco
    
    hx.syscall arquivoExiste
    
    jc .proximoComando

    mov eax, 0                     ;; Não passar argumentos
    mov esi, sh.imagemDisco        ;; Nome do arquivo
    
    stc
    
    hx.syscall iniciarProcesso     ;; Solicitar o carregamento do primeiro comando
 
    jnc .proximoComando

.proximoComando:

    clc 

    call procurarComandos

    jmp .carregarImagem

.naoEncontrado:                    ;; O serviço não pôde ser localizado
    
    jmp inicioShell.obterComando

.arquivoShellAusente:

    fputs sh.semArquivoShell

    jmp inicioShell.obterComando

.argumentonNecessario:

    fputs sh.argumentoNecessario

    jmp inicioShell.obterComando

;;************************************************************************************

;; Componentes do comando exec para execução do comando em lotes do shell

procurarComandos:

    pusha
    
    push es

    push ds
    pop es
    
    mov si, bufferArquivo           ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, word[sh.posicaoBX]         
    
    jmp .procurarEntreDelimitadores

.procurarEntreDelimitadores:

    inc bx
    
    mov word[sh.posicaoBX], bx

    cmp bx, tamanhoLimiteBusca
    je inicioShell.obterComando
    
    mov al, [ds:si+bx]
    
    cmp al, '>'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
    
;; BX agora aponta para o primeira caractere do nome do shell resgatado do arquivo
    
    push ds
    pop es
    
    mov di, sh.imagemDisco          ;; O nome do shell será copiado para ES:DI
    
    mov si, bufferArquivo
    
    add si, bx                      ;; Mover SI para aonde BX aponta
    
    mov bx, 0                       ;; Iniciar em 0
    
.obterComando:

    inc bx
    
    cmp bx, 13              
    je .nomeComandoInvalido           ;; Se nome de arquivo maior que 11, o nome é inválido     
    
    mov al, [ds:si+bx]
    
;; Agora vamos procurar os limitadores finais do nome de um comando, que podem ser:
;;
;; EOL - nova linha (10)
;; Espaço - um espaço após o último caractere
;; # - Se usado após o último caractere do nome do serviço, marcar como comentário

    cmp al, 10                     ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeComandoObtido

    cmp al, ' '                     ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeComandoObtido

    cmp al, '#'                     ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeComandoObtido
    
;; Se não estiver pronto, armazenar o caractere obtido

    stosb
    
    jmp .obterComando

.nomeComandoObtido:

    pop es
    
    popa

    ret
    
.nomeComandoInvalido:

    pop es
    
    popa
    
    stc 

    ret

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

    push esi
    
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
    
    hx.syscall tamanhoString
    
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

    fputs sh.uso
    
    jmp finalizarShell  

;;************************************************************************************

finalizarShell:
    
    mov ebx, 00h
    
    hx.syscall encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;; Dados, variáveis e constantes utilizadas pelo Shell
;;
;;************************************************************************************

;; TODO: melhorar suporta a script de shell

;; A versão do sh é independente da versão do restante do Sistema.
;; Ela deve ser utilizada para identificar para qual versão do Hexagonix® o sh foi
;; desenvolvido.
            
versaoSH equ "1.7.0.2"

tamanhoLimiteBusca = 32768

sh:

.prompt:               db "@Hexagonix", 0
.comandoNaoEncontrado: db ": command not found.", 0
.arquivorc:            db "shrc", 0
.imagemInvalida:       db ": unable to load image. Unsupported executable format.", 0
.limiteProcessos:      db 10, 10, "There is no memory available to run the requested application.", 10
                       db "First try to terminate applications or their instances, and try again.", 0                  
.ponto:                db ".", 0
.usuarioNormal:        db "$ ", 0
.usuarioRoot:          db "# ", 0
.uso:                  db 10, 10, "Usage: sh", 10, 10
                       db "Start a Unix shell for the current user.", 10, 10
                       db "sh version ", versaoSH, 10, 10
                       db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                       db "All rights reserved.", 10, 0
.parametroAjuda:       db "?", 0   
.parametroAjuda2:      db "--help", 0
.semArquivoShell:      db 10, "Shell script not found.", 0
.argumentoNecessario:  db 10, "An argument is necessary.", 0
.imagemDisco: times 12 db 0        ;; Armazena o nome do shell à ser utilizado pelo sistema
.posicaoBX:            dw 0        ;; Marcação da posição de busca no conteúdo do arquivo
.nomeUsuario: times 64 db 0
.separador:    times 8 db 0
 
;;**************************

comandos:

.sair: db "exit", 0
.exec: db "exec", 0

;;**************************

maxColunas:   db 0 ;; Total de colunas disponíveis no vídeo na resolução atual
maxLinhas:    db 0 ;; Total de linhas disponíveis no vídeo na resolução atual
linhaComando: dd 0

;;************************************************************************************

bufferArquivo:  ;; Endereço para carregamento de arquivos
