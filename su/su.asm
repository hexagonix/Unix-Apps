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

;;************************************************************************************
;;                                                                                  
;;               Gerenciador de Login do Sistema Operacional Hexagonix®                 
;;                                                                   
;;                  Copyright © 2015-2023 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
;;                                                                   
;;************************************************************************************

;; AVISO! Esta ferramenta Unix utiliza a mesma sintaxe e módulos da ferramenta Unix login.
;;
;; Ficar atento à possíveis alterações na estrutura do arquivo utilizado por login.
;;
;; O utilitário Unix su utiliza o mesmo arquivo 'usuario.unx' que login.

use32       

tamanhoLimiteBusca = 12288

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo. Anteriormente,
;; o cabeçalho era criado em cada imagem e poderia diferir de uma para outra. Caso algum
;; campo da especificação HAPP mudasse, os cabeçalhos de todos os aplicativos deveriam ser
;; alterados manualmente. Com uma estrutura padronizada, basta alterar um arquivo que deve
;; ser incluído e montar novamente o aplicativo, sem a necessidade de alterar manualmente
;; arquivo por arquivo. O arquivo contém uma estrutura instanciável com definição de 
;; parâmetros no momento da instância, tornando o cabeçalho tão personalizável quanto antes.

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, suHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"

;;************************************************************************************          

suHexagonix: ;; Ponto de entrada
    
    mov [usuarioSolicitado], edi
        
    mov edi, su.parametroAjuda
    mov esi, [usuarioSolicitado]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, su.parametroAjuda2
    mov esi, [usuarioSolicitado]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
        
    mov esi, [usuarioSolicitado]
            
    cmp byte[esi], 0
    je usoAplicativo
    
iniciarExecucao:

    novaLinha
    
    call salvarUsuarioAtual         ;; Salva o usuário da sessão atual
    
    clc
    
    call encontrarNomeUsuario 
    
    jc .semUsuario
    
    call encontrarSenhaUsuario 
    
    fputs su.solicitarSenha
        
    mov eax, 64
    
    mov ebx, 1234h                  ;; Não queremos eco na senha! 
    
    hx.syscall obterString
    
    hx.syscall cortarString
    
    mov edi, senhaObtida
    
    hx.syscall compararPalavrasString
    
    jc .loginAceito
    
    jmp finalizarExecucao

.semUsuario:

    cmp byte[parametros], 0
    je terminar
    
.loginAceito:

    call registrarUsuario
    
    call encontrarShell

    call verificarUsuario

    jc .grandesPoderes

    jmp .carregarShell

.grandesPoderes:

    fputs su.grandesPoderes
    
.carregarShell:
    
    mov eax, 0                     ;; Não passar argumentos
    mov esi, shellHexagonix        ;; Nome do arquivo
    
    stc
    
    hx.syscall iniciarProcesso      ;; Solicitar o carregamento do shell do Hexagonix®
 
    jnc .shellFinalizado

.naoEncontrado:                    ;; O shell não pôde ser localizado
    
   cmp byte[tentarShellPadrao], 0  ;; Verifica se já se tentou carregar o shell padrão do Hexagonix®
   je .tentarShellPadrao           ;; Se não, tente carregar o shell padrão do Hexagonix®
    
   hx.syscall encerrarProcesso      ;; Se sim, o shell padrão também não pode ser executado  

.tentarShellPadrao:                ;; Tentar carregar o shell padrão do Hexagonix®

   call obterShellPadrao           ;; Solicitar a configuração do nome do shell padrão do Hexagonix®
    
   mov byte[tentarShellPadrao], 1  ;; Sinalizar a tentativa de carregamento do shell padrão do Hexagonix®
    
   jmp .carregarShell              ;; Tentar carregar o shell padrão do Hexagonix®
    
.shellFinalizado:                  ;; Tentar carregar o shell novamente
    
    call restaurarUsuario          ;; Restaura o usuário da sessão anterior
    
    jmp terminar
    
;;************************************************************************************

limparTerminal:

    mov esi, vd1          ;; Abrir o dispositivo de saída secundário em memória (Buffer) 
    
    hx.syscall hx.open    ;; Abre o dispositivo
    
    hx.syscall limparTela ;; Limpa seu conteúdo
    
    mov esi, vd0          ;; Reabre o dispositivo de saída padrão 
    
    hx.syscall hx.open    ;; Abre o dispositivo
    
    ret
    
;;************************************************************************************

verificarUsuario:
    
    clc
    
    mov esi, su.usuarioROOT
    mov edi, usuario
    
    hx.syscall compararPalavrasString
    
    ret

;;************************************************************************************

registrarUsuario:
    
    clc
    
    mov esi, su.usuarioROOT
    mov edi, usuario
    
    hx.syscall compararPalavrasString
    
    jc .root
    
    mov eax, 555 ;; Código de um usuário comum
    
    jmp .registrar
    
.root:
    
    mov eax, 777 ;; Código de um usuário raiz

.registrar:
    
    mov esi, usuario
    
    hx.syscall definirUsuario
    
    ret
    
;;************************************************************************************
    
encontrarNomeUsuario:

    pusha
    
    push es

    push ds
    pop es
    
    mov esi, arquivo
    mov edi, bufferArquivo
    
    hx.syscall hx.open
    
    jc .arquivoUsuarioAusente
    
    mov si, bufferArquivo           ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, 0FFFFh                  ;; Inicia na posição -1, para que se possa encontrar os delimitadores
    
.procurarEntreDelimitadores:

    inc bx
    
    mov word[posicaoBX], bx
    
    cmp bx, tamanhoLimiteBusca
    je .nomeUsuarioInvalido         ;; Caso nada seja encontrado até o tamanho limite, cancele a busca
    
    mov al, [ds:si+bx]
    
    cmp al, '@'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
    
;; BX agora aponta para o primeiro caractere do nome de usuário resgatado do arquivo
    
    push ds
    pop es
    
    mov di, usuario                 ;; O nome do usuário será copiado para ES:DI
    
    mov si, bufferArquivo
    
    add si, bx                      ;; Mover SI para aonde BX aponta
    
    mov bx, 0                       ;; Iniciar em 0
    
.obterNomeUsuario:

    inc bx
    
    cmp bx, 17              
    je .nomeUsuarioInvalido         ;; Se nome de usuário maior que 15, o mesmo é inválido     
    
    mov al, [ds:si+bx]
    
    cmp al, '|'                     ;; Se encontrar outro delimitador, o nome de usuário foi carregado com sucesso
    je .nomeUsuarioObtido
    
;; Se não estiver pronto, armazenar o caractere obtido

    stosb
    
    jmp .obterNomeUsuario

.nomeUsuarioObtido:

    mov edi, usuario
    mov esi, [usuarioSolicitado]
    
    hx.syscall compararPalavrasString
    
    jc .obtido
    
    call limparVariavel
    
    mov word bx, [posicaoBX]
    
    mov si, bufferArquivo
    
    jmp .procurarEntreDelimitadores
    
.obtido:
    
    pop es
    
    popa
    
    clc

    ret
    
.nomeUsuarioInvalido:

    pop es
    
    popa
    
    fputs su.semUsuario
        
    fputs [usuarioSolicitado]
    
    stc
    
    ret
    
.arquivoUsuarioAusente:

    pop es
    
    popa
    
    fputs su.semArquivoUnix
        
    jmp terminar

;;************************************************************************************

limparVariavel:

    push es
    
    push ds
    pop es
    
    mov esi, usuario
    
    hx.syscall tamanhoString
    
    push eax
    
    mov esi, 0
    
    mov edi, usuario
    
    pop ecx
    
    rep movsb
    
    pop es
    
    ret     
    
;;************************************************************************************
    
encontrarSenhaUsuario:

    pusha
    
    push es

    push ds
    pop es
    
    mov esi, arquivo
    mov edi, bufferArquivo
    
    hx.syscall hx.open
    
    jc .arquivoUsuarioAusente
    
    mov si, bufferArquivo    ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, word [posicaoBX] ;; Continua de onde a opção anterior parou
    
    dec bx
    
.procurarEntreDelimitadores:

    inc bx
    
    mov word[posicaoBX], bx
    
    cmp bx, tamanhoLimiteBusca
    
    je .senhaUsuarioInvalida ;; Caso nada seja encontrado até o tamanho limite, cancele a busca
    
    mov al, [ds:si+bx]
    
    cmp al, '|'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
    
;; BX agora aponta para o primeiro caractere da senha recuperada do arquivo
    
    push ds
    pop es
    
    mov di, senhaObtida      ;; A senha será copiada para ES:DI
    
    mov si, bufferArquivo
    
    add si, bx               ;; Mover SI para onde BX aponta
    
    mov bx, 0                ;; Iniciar em 0
    
.obterSenhaUsuario:

    inc bx
    
    cmp bx, 66              
    je .senhaUsuarioInvalida ;; Se senha maior que 66, a mesma é inválida    
    
    mov al, [ds:si+bx]
    
    cmp al, '&'              ;; Se encontrar outro delimitador, a senha foi carregada com sucesso
    je .senhaUsuarioObtida
    
;; Se não estiver pronto, armazenar o caractere obtido

    stosb
    
    jmp .obterSenhaUsuario

.senhaUsuarioObtida:

    pop es
    
    popa

    ret
    
.senhaUsuarioInvalida:

    pop es
    
    popa
    
    stc
    
    ret

.arquivoUsuarioAusente:

    pop es
    
    popa
    
    fputs su.semArquivoUnix
        
    jmp terminar
    
;;************************************************************************************
 
encontrarShell:

    pusha
    
    push es

    push ds
    pop es
    
    mov esi, arquivo
    mov edi, bufferArquivo
    
    hx.syscall hx.open
    
    jc .arquivoConfiguracaoAusente
    
    mov si, bufferArquivo           ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, word [posicaoBX]        ;; Continua de onde a opção anterior parou
    
    dec bx
    
.procurarEntreDelimitadores:

    inc bx
    
    mov word[posicaoBX], bx
    
    cmp bx, tamanhoLimiteBusca
    
    je .arquivoConfiguracaoAusente  ;; Caso nada seja encontrado até o tamanho limite, cancele a busca
    
    mov al, [ds:si+bx]
    
    cmp al, '&'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
    
;; BX agora aponta para o primeira caractere do nome do shell resgatado do arquivo
    
    push ds
    pop es
    
    mov di, shellHexagonix   ;; O nome do shell será copiado para ES:DI - shellHexagonix
    
    mov si, bufferArquivo
    
    add si, bx               ;; Mover SI para aonde BX aponta
    
    mov bx, 0                ;; Iniciar em 0
    
.obterNomeShell:

    inc bx
    
    cmp bx, 13              
    je .nomeShellInvalido    ;; Se nome de arquivo maior que 11, o nome é inválido     
    
    mov al, [ds:si+bx]
    
    cmp al, '#'              ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
    je .nomeShellObtido
    
;; Se não estiver pronto, armazenar o caractere obtido

    stosb
    
    jmp .obterNomeShell

.nomeShellObtido:

    pop es
    
    popa

    ret
    
.nomeShellInvalido:

    pop es
    
    popa
    
    jmp obterShellPadrao

    
.arquivoConfiguracaoAusente:

    pop es
    
    popa
    
    jmp obterShellPadrao

;;************************************************************************************
    
obterShellPadrao:

    push es
    
    push ds
    pop es
    
    mov esi, shellPadrao
    
    hx.syscall tamanhoString
    
    push eax
    
    mov edi, shellHexagonix
    mov esi, shellPadrao
    
    pop ecx
    
    rep movsb
    
    pop es
    
    ret                     

;;************************************************************************************

salvarUsuarioAtual:

    push es
    
    push ds
    pop es
    
    hx.syscall obterUsuario
    
    push esi
    
    hx.syscall tamanhoString
    
    pop esi
    
    push eax
    
    mov edi, usuarioAnterior
    
    pop ecx
    
    rep movsb
    
    pop es
    
    hx.syscall obterUsuario
    
    mov [codigoAnterior], eax
    
    ret         

;;************************************************************************************

restaurarUsuario:

    mov esi, usuarioAnterior
    mov eax, [codigoAnterior]
    
    hx.syscall definirUsuario
    
    ret

;;************************************************************************************
    
usoAplicativo:

    fputs su.uso
        
    jmp terminar

;;************************************************************************************

finalizarExecucao:

    fputs su.falhaAutenticacao

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

versaoSU equ "2.3.2"

shellPadrao:       db "sh", 0          ;; Nome do arquivo que contêm o shell padrão do Hexagonix®
vd0:               db "vd0", 0         ;; Console principal
vd1:               db "vd1", 0         ;; Console secundário
arquivo:           db "passwd", 0      ;; Nome do arquivo de gerenciamento de login
tentarShellPadrao: db 0                ;; Sinaliza a tentativa de se carregar o shell padrão
shellHexagonix:    times 11 db 0       ;; Armazena o nome do shell à ser utilizado pelo sistema
usuario:           times 15 db 0       ;; Nome de usuário obtido no arquivo
senhaObtida:       times 64 db 0       ;; Senha obtida no arquivo
parametros:        db 0                ;; Se o aplicativo recebeu algum parâmetro
ponto:             db ".", 0
posicaoBX:         dw 0

su:

.grandesPoderes:    db 10, 10, "You are now an administrative user. This means you can make deep changes to", 10
                    db "system, so be careful.", 10, 10
                    db 'Remember: "Great power comes with great responsibility"!', 0  
.solicitarSenha:    db "Enter your UNIX password: ", 0 
.uso:               db 10, "Usage: su [user]", 10, 10
                    db "Change to a registered user.", 10, 10
                    db "su version ", versaoSU, 10, 10
                    db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                    db "All rights reserved.", 0
.semArquivoUnix:    db 10, "The user account database was not found on the volume.", 10, 0 
.semUsuario:        db 10, "The requested user was not found: ", 0              
.parametroAjuda:    db "?", 0   
.parametroAjuda2:   db "--help", 0
.usuarioROOT:       db "root", 0
.falhaAutenticacao: db 10, "su: Authentication failed.", 0

usuarioSolicitado:  times 17 db 0
usuarioAnterior:    times 17 db 0
codigoAnterior:              dd 0

;;************************************************************************************

bufferArquivo:                ;; Local onde o arquivo de configuração será aberto
