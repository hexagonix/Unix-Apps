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
;;                     Sistema Operacional Hexagonix - Hexagonix Operating System
;;
;;                         Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
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
;;                        Utilitário Unix login para Hexagonix
;;
;;                 Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
;;                          Todos os direitos reservados.
;;
;;************************************************************************************

use32

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo.

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, loginHexagonix, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"
include "log.s"

tamanhoLimiteBusca = 32768

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

;;************************************************************************************

versaoLOGIN equ "4.9.0"

login:

;; Mensagens gerais

.shellPadrao: ;; Nome do arquivo que contêm o shell padrão do Hexagonix
db "sh", 0
.arquivo: ;; Nome do arquivo de gerenciamento de login
db "passwd", 0
.semArquivoUnix:
db 10, 10, "The user database was not found on the volume.", 10, 0
.solicitarUsuario:
db 10, "Login: ", 0
.solicitarSenha:
db 10, "Password: ", 0
.uso:
db 10, 10, "Usage: login [user]", 10, 10
db "Log in a registered user.", 10, 10
db "login version ", versaoLOGIN, 10, 10
db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 10, 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.usuarioROOT:
db "root", 0
.dadosErrados:
db 10, 10, "Authentication failed.", 10, 0
.logind:
db "logind", 0

;; Mensagens de verbose

.verboseLogin:
db "login version ", versaoLOGIN, ".", 0
.verboseProcurarArquivo:
db "Searching user database in /...", 0
.verboseArquivoEncontrado:
db "The user database was found.", 0
.verboseArquivoAusente:
db "The user database was not found. The default shell will run (sh.app).", 0
.verboseErro:
db "An unhandled error was encountered.", 0
.verboseLoginAceito:
db "Login accepted.", 0
.verboseLoginRecusado:
db "Login attempt prevented by authentication failure.", 0
.verboseLogout:
db "Logout performed successfully.", 0

;; Buffers

tentarShellPadrao: db 0 ;; Sinaliza a tentativa de se carregar o shell padrão
codigoAnterior:    dd 0
errado:            db 0
execucaoViaInit:   db 0
parametros:        db 0 ;; Se o aplicativo recebeu algum parâmetro
posicaoBX:         dw 0 ;; Marcação da posição de busca no conteúdo do arquivo

shellHexagonix: ;; Armazena o nome do shell à ser utilizado
times 11 db 0
usuario: ;; Nome de usuário obtido no arquivo
times 15 db 0
senhaObtida: ;; Senha obtida no arquivo
times 64 db 0
usuarioSolicitado:
times 17 db 0
usuarioAnterior:
times 17 db 0

;;************************************************************************************

loginHexagonix: ;; Ponto de entrada

    mov [usuarioSolicitado], edi

    mov edi, login.parametroAjuda
    mov esi, [usuarioSolicitado]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    mov edi, login.parametroAjuda2
    mov esi, [usuarioSolicitado]

    hx.syscall compararPalavrasString

    jc usoAplicativo

    call checarBaseDados

    logSistema login.verboseLogin, 0, Log.Prioridades.p4

iniciarExecucao:

    hx.syscall hx.getpid

    cmp eax, 02h
    je .viaInit

    mov byte [execucaoViaInit], 00h

    jmp .continuarAposValidacao

.viaInit:

    mov byte [execucaoViaInit], 01h

.continuarAposValidacao:

    call executarLogind

    cmp byte[errado], 1
    jne .execucaoInicial

;; Não precisamos executar o logind novamente

.continuarAposLoginRecusado:

    clc

    logSistema login.verboseLoginRecusado, 0, Log.Prioridades.p4

    fputs login.dadosErrados

    mov byte[errado], 0

.execucaoInicial:

    logSistema login.verboseProcurarArquivo, 0, Log.Prioridades.p4

    call limparVariaveisUsuario

    fputs login.solicitarUsuario

    mov eax, 15

    mov ebx, 01h

    hx.syscall obterString

    hx.syscall cortarString

    mov [usuarioSolicitado], esi

    call encontrarNomeUsuario

    jc .semUsuario

    call encontrarSenhaUsuario

    fputs login.solicitarSenha

    mov eax, 64

    mov ebx, 1234h ;; Não queremos eco na senha!

    hx.syscall obterString

    hx.syscall cortarString

    cmp byte[errado], 1
    jne .continuarProcessamento

    jmp .loginRecusado

.continuarProcessamento:

    mov edi, senhaObtida

    hx.syscall compararPalavrasString

    jc .loginAceito

.loginRecusado:

    logSistema login.verboseLoginRecusado, 00h, Log.Prioridades.p4

    mov byte[errado], 1

    jmp iniciarExecucao.continuarAposLoginRecusado

.semUsuario:

    cmp byte[parametros], 0
    je terminar

.loginAceito:

    logSistema login.verboseLoginAceito, 0, Log.Prioridades.p4

    call registrarUsuario

    call encontrarShell

    hx.syscall destravar

.carregarShell:

    clc

    mov esi, shellHexagonix

    hx.syscall arquivoExiste

    jc .naoEncontrado

    mov eax, 0 ;; Não passar argumentos
    mov esi, shellHexagonix ;; Nome do arquivo

    clc

    hx.syscall iniciarProcesso ;; Solicitar o carregamento do shell do Hexagonix

    jc .tentarShellPadrao

    hx.syscall travar

    jmp .shellFinalizado

.tentarShellPadrao: ;; Tentar carregar o shell padrão do Hexagonix

   call obterShellPadrao ;; Solicitar a configuração do nome do shell padrão do Hexagonix

   mov byte[tentarShellPadrao], 1 ;; Sinalizar a tentativa de carregamento do shell padrão do Hexagonix

   jmp .carregarShell ;; Tentar carregar o shell padrão do Hexagonix

.shellFinalizado: ;; Tentar carregar o shell novamente

    hx.syscall travar

;; Verificar a consistência da interface. Caso algum processo seja encerrado antes de retornar
;; as propriedades de tema ao padrão, retorne para as condições presentes nas configurações,
;; mantendo a consistência do sistema

    logSistema login.verboseLogout, 0, Log.Prioridades.p4

;; Aqui vamos implementar uma mudança na forma como o login deve interpretar o encerramento do shell.
;; Caso login tenha PID 2, significa que ele foi invocado via init. Desa forma, ele deve ficar residente,
;; neste momento. Se for PID 2, solicitar a entrada do usuário novamente

    novaLinha

    cmp byte [execucaoViaInit], 01h
    jne terminar

    jmp .execucaoInicial

.naoEncontrado: ;; O shell não pôde ser localizado

   cmp byte[tentarShellPadrao], 0 ;; Verifica se já se tentou carregar o shell padrão do Hexagonix
   je .tentarShellPadrao ;; Se não, tente carregar o shell padrão do Hexagonix

   jmp terminar ;; Se sim, o shell padrão também não pode ser executado

;;************************************************************************************

registrarUsuario:

    clc

    mov esi, login.usuarioROOT
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

    clc

    pusha

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov esi, login.arquivo
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc .arquivoUsuarioAusente

    mov si, bufferArquivo ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, 0FFFFh ;; Inicia na posição -1, para que se possa encontrar os delimitadores

.procurarEntreDelimitadores:

    inc bx

    mov word[posicaoBX], bx

    cmp bx, tamanhoLimiteBusca
    je .nomeUsuarioInvalido ;; Caso nada seja encontrado até o tamanho limite, cancele a busca

    mov al, [ds:si+bx]

    cmp al, '@'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado

;; BX agora aponta para o primeiro caractere do nome de usuário resgatado do arquivo

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov di, usuario ;; O nome do usuário será copiado para ES:DI

    mov si, bufferArquivo

    add si, bx ;; Mover SI para aonde BX aponta

    mov bx, 0 ;; Iniciar em 0

.obterNomeUsuario:

    inc bx

    cmp bx, 17
    je .nomeUsuarioInvalido ;; Se nome de usuário maior que 15, o mesmo é inválido

    mov al, [ds:si+bx]

    cmp al, '|' ;; Se encontrar outro delimitador, o nome de usuário foi carregado com sucesso
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

    mov byte[errado], 1

    clc

    ret

.arquivoUsuarioAusente:

    pop es

    popa

    fputs login.semArquivoUnix

    jmp terminar

;;************************************************************************************

limparVariavel:

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
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

limparVariaveisUsuario:

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov esi, usuario

    hx.syscall tamanhoString

    push eax

    mov esi, ' '

    mov edi, usuario

    pop ecx

    rep movsb

    mov esi, usuarioSolicitado

    hx.syscall tamanhoString

    push eax

    mov esi, ' '

    mov edi, senhaObtida

    pop ecx

    rep movsb

    mov esi, shellHexagonix

    hx.syscall tamanhoString

    push eax

    mov esi, " "

    mov edi, shellHexagonix

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

encontrarSenhaUsuario:

    pusha

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov esi, login.arquivo
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

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov di, senhaObtida ;; A senha será copiada para ES:DI

    mov si, bufferArquivo

    add si, bx ;; Mover SI para onde BX aponta

    mov bx, 0 ;; Iniciar em 0

.obterSenhaUsuario:

    inc bx

    cmp bx, 66
    je .senhaUsuarioInvalida ;; Se senha maior que 66, a mesma é inválida

    mov al, [ds:si+bx]

    cmp al, '&' ;; Se encontrar outro delimitador, a senha foi carregada com sucesso
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

    mov byte[errado], 1

    clc

    ret

.arquivoUsuarioAusente:

    pop es

    popa

    fputs login.semArquivoUnix

    jmp terminar

;;************************************************************************************

encontrarShell:

    pusha

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov esi, login.arquivo
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc .arquivoConfiguracaoAusente

    mov si, bufferArquivo   ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, word[posicaoBX] ;; Continua de onde a opção anterior parou

    dec bx

.procurarEntreDelimitadores:

    inc bx

    mov word[posicaoBX], bx

    cmp bx, tamanhoLimiteBusca

    je .arquivoConfiguracaoAusente  ;; Caso nada seja encontrado até o tamanho limite, cancele a busca

    mov al, [ds:si+bx]

    cmp al, '&'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado

;; BX agora aponta para o primeiro caractere do nome do shell resgatado do arquivo

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov di, shellHexagonix ;; O nome do shell será copiado para ES:DI - shellHexagonix

    mov si, bufferArquivo

    add si, bx ;; Mover SI para aonde BX aponta

    mov bx, 0 ;; Iniciar em 0

.obterNomeShell:

    inc bx

    cmp bx, 13
    je .nomeShellInvalido ;; Se nome de arquivo maior que 11, o nome é inválido

    mov al, [ds:si+bx]

    cmp al, '#' ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
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

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov esi, login.shellPadrao

    hx.syscall tamanhoString

    push eax

    mov edi, shellHexagonix
    mov esi, login.shellPadrao

    pop ecx

    rep movsb

    pop es

    ret

;;************************************************************************************

salvarUsuarioAtual:

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
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

    fputs login.uso

    jmp terminar

;;************************************************************************************

executarLogind:

    mov eax, 0 ;; Não passar argumentos
    mov esi, login.logind ;; Nome do arquivo

    clc

    hx.syscall iniciarProcesso ;; Solicitar o carregamento do daemon de login

    ret

;;************************************************************************************

terminar:

    hx.syscall encerrarProcesso

;;************************************************************************************

loginPadrao:

;; Se o arquivo de banco de dados de usuários não for encontrado, devemos
;; iniciar um shell padrão do sistema, logado como root.

;; Primeiro, logar como root

    mov eax, 777 ;; Código de um usuário raiz

    mov esi, login.usuarioROOT

    hx.syscall definirUsuario

    mov eax, 0
    mov esi, login.shellPadrao

    clc

    hx.syscall iniciarProcesso

    je terminar

;;************************************************************************************

;; Primeiramente, devemos checar a base da dados de usuários. Se a base de
;; dados não estiver disponível, o sistema deve ser logado com usuário root
;; e o shell padrão deve ser iniciado.

checarBaseDados:

    clc

    mov esi, login.arquivo

    hx.syscall arquivoExiste

    jc loginPadrao

    ret

;;************************************************************************************

bufferArquivo: ;; Local onde o arquivo de configuração será aberto
