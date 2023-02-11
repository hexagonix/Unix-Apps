;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2015-2023 Felipe Miguel Nery Lunkes
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

;;************************************************************************************
;;                                                                                  
;;              Utilitário Unix init para Sistema Operacional Hexagonix®                 
;;                                                                   
;;                  Copyright © 2016-2023 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************

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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, initHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"
include "log.s"

;;************************************************************************************

versaoINIT equ "2.5.0"

tamanhoLimiteBusca = 32768

shellPadrao:               db "sh", 0  ;; Nome do arquivo que contêm o shell padrão Unix
vd0:                       db "vd0", 0 ;; Console principal
vd1:                       db "vd1", 0 ;; Primeiro console virtual
arquivo:                   db "rc", 0  ;; Nome do arquivo de configuração do init
tentarShellPadrao:         db 0        ;; Sinaliza a tentativa de se carregar o shell padrão
servicoHexagonix: times 12 db 0        ;; Armazena o nome do shell à ser utilizado pelo sistema
posicaoBX:                 dw 0        ;; Marcação da posição de busca no conteúdo do arquivo

init:

.inicioInit:             db "init version ", versaoINIT, ".", 0
.iniciandoSistema:       db "The system is coming up. Please wait.", 0
.sistemaPronto:          db "The system is ready.", 0
.procurarArquivo:        db "Looking for /rc...", 0
.arquivoEncontrado:      db "Configuration file (/rc) found.", 0
.arquivoAusente:         db "Configuration file (/rc) not found. The default shell will be executed (sh).", 0
.erroGeral:              db "An unhandled error was encountered.", 0
.registrandoComponentes: db "Starting service...", 0
.configurarConsole:      db "Setting up consoles (vd0, vd1)...", 0

;;************************************************************************************          

;; Aqui temos o ponto de entrada do init 

initHexagonix: ;; Ponto de entrada do init

;; Primeiramente, devemos checar qual o PID do processo. Por padrão, init só deve ser executado 
;; diretamente pelo Hexagon. Fora isso, ele não deve desempenhar sua função. Caso o PID seja 
;; diferente de 1, o init deve ser finalizado. Caso seja 1, prosseguir com o processo de 
;; inicialização do ambiente de usuário do Hexagonix

    hx.syscall hx.getpid
    
    cmp eax, 01h
    je .configurarTerminal ;; O PID é 1? Prosseguir
    
    hx.syscall encerrarProcesso ;; Não é? Finalizar agora

;; Configura o terminal do Hexagonix

.configurarTerminal:

    logSistema init.inicioInit, 0, Log.Prioridades.p5
    logSistema init.iniciandoSistema, 0, Log.Prioridades.p5

;; Agora, o buffer de memória do double buffering deve ser limpo. Isto evita que memória 
;; poluída seja utilizada como base para a exibição, quando um aplicativo é fechado de forma forçada.
;; Nesta situação, o sistema descarrega o buffer de memória, atualizando o vídeo com seu conteúdo.
;; Essa etapa também pode ser realizada pelo gerenciador de sessão, posteriormente.
    
    call limparTerminal
        
;; Aqui poderão ser adicionadas rotinas de configuração do Hexagonix

iniciarExecucao:

    hx.syscall travar ;; Impede que o usuário mate o processo de login com uma tecla especial
    
;; Agora o init irá verificar a existência do arquivo de configuração de inicialização.
;; Caso este arquivo esteja presente, o init irá buscar a declaração de uma imagem para ser utilizada
;; com o sistema, assim como declarações de configuração do Hexagonix. Caso este arquivo não seja
;; encontrado, o init irá carregar o shell padrão. O padrão é o utilitário de login do Hexagonix.
  
    logSistema init.procurarArquivo, 0, Log.Prioridades.p4

    mov word[posicaoBX], 0FFFFh ;; Inicia na posição -1, para que se possa encontrar os delimitadores

    call encontrarConfiguracaoInit          

    logSistema init.sistemaPronto, 0, Log.Prioridades.p5

.carregarServico:

    logSistema init.registrandoComponentes, 0, Log.Prioridades.p4

    mov esi, servicoHexagonix
    
    hx.syscall arquivoExiste
    
    jc .proximoServico

    mov eax, 0                     ;; Não passar argumentos
    mov esi, servicoHexagonix      ;; Nome do arquivo
    
    stc
    
    hx.syscall iniciarProcesso      ;; Solicitar o carregamento do primeiro serviço
 
    jnc .proximoServico

.proximoServico:

    clc 

    call encontrarConfiguracaoInit

    jmp .carregarServico

.naoEncontrado:                    ;; O serviço não pôde ser localizado
    
    cmp byte[tentarShellPadrao], 0 ;; Verifica se já se tentou carregar o shell padrão do Hexagonix
    je .tentarShellPadrao          ;; Se não, tente carregar o shell padrão do Hexagonix
    
    hx.syscall encerrarProcesso    ;; Se sim, o shell padrão também não pode ser executado  

.tentarShellPadrao:                ;; Tentar carregar o shell padrão do Hexagonix

    call obterShellPadrao          ;; Solicitar a configuração do nome do shell padrão do Hexagonix
    
    mov byte[tentarShellPadrao], 1 ;; Sinalizar a tentativa de carregamento do shell padrão do Hexagonix
    
    hx.syscall destravar           ;; O shell pode ser terminado utilizando uma tecla especial
    
    jmp .carregarServico           ;; Tentar carregar o shell padrão do Hexagonix
    
;;************************************************************************************

limparTerminal:

    logSistema init.configurarConsole, 0, Log.Prioridades.p5

    mov esi, vd1         ;; Abrir o primeiro console virtual 
    
    hx.syscall hx.open   ;; Abre o dispositivo
    
    mov esi, vd0         ;; Reabre o console padrão
    
    hx.syscall hx.open   ;; Abre o dispositivo
    
    ret
    
;;************************************************************************************
 
encontrarConfiguracaoInit:

    pusha
    
    push es

    push ds
    pop es
    
    mov esi, arquivo
    mov edi, bufferArquivo
    
    hx.syscall hx.open
    
    jc .arquivoConfiguracaoAusente
    
    mov si, bufferArquivo           ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, word[posicaoBX]         
    
    jmp .procurarEntreDelimitadores

.procurarEntreDelimitadores:

    inc bx
    
    mov word[posicaoBX], bx

    cmp bx, tamanhoLimiteBusca
    je iniciarExecucao.tentarShellPadrao  ;; Caso nada seja encontrado até o tamanho limite, cancele a busca
    
    mov al, [ds:si+bx]
    
    cmp al, ':'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
    
;; BX agora aponta para o primeira caractere do nome do shell resgatado do arquivo
    
    push ds
    pop es
    
    mov di, servicoHexagonix        ;; O nome do shell será copiado para ES:DI - servicoHexagonix
    
    mov si, bufferArquivo
    
    add si, bx                      ;; Mover SI para aonde BX aponta
    
    mov bx, 0                       ;; Iniciar em 0
    
.obterNomeServico:

    inc bx
    
    cmp bx, 13              
    je .nomeShellInvalido           ;; Se nome de arquivo maior que 11, o nome é inválido     
    
    mov al, [ds:si+bx]
    
;; Agora vamos procurar os limitadores finais do nome de um serviço, que podem ser:
;;
;; EOL - nova linha (10)
;; Espaço - um espaço após o último caractere
;; # - Se usado após o último caractere do nome do serviço, marcar como comentário

    cmp al, 10                     ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeShellObtido

    cmp al, ' '                     ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeShellObtido

    cmp al, '#'                     ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeShellObtido
    
;; Se não estiver pronto, armazenar o caractere obtido

    stosb
    
    jmp .obterNomeServico

.nomeShellObtido:

    pop es
    
    popa

    logSistema init.arquivoEncontrado, 0, Log.Prioridades.p4

    ret
    
.nomeShellInvalido:

    pop es
    
    popa
    
    jmp obterShellPadrao

    
.arquivoConfiguracaoAusente:

    pop es
    
    popa

    logSistema init.arquivoAusente, 0, Log.Prioridades.p4

    jmp obterShellPadrao

;;************************************************************************************
    
obterShellPadrao:

    push es
    
    push ds
    pop es
    
    mov esi, servicoHexagonix
    
    hx.syscall tamanhoString
    
    push eax
    
    mov edi, servicoHexagonix
    mov esi, ' '
    
    pop ecx
    
    rep movsb
    
    pop es
    
    push es
    
    push ds
    pop es
    
    mov esi, shellPadrao
    
    hx.syscall tamanhoString
    
    push eax
    
    mov edi, servicoHexagonix
    mov esi, shellPadrao
    
    pop ecx
    
    rep movsb
    
    pop es
    
    ret                     
        
;;************************************************************************************               
                
bufferArquivo:                  ;; Local onde o arquivo de configuração será aberto
