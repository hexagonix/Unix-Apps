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
;;                          Daemon de login para Hexagonix
;;
;;                 Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
;;                          Todos os direitos reservados.
;;
;;************************************************************************************

use32

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo.

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, iniciologind, 01h

;;************************************************************************************

include "hexagon.s"
include "Estelar/estelar.s"
include "macros.s"
include "log.s"
include "dev.s"
include "verUtils.s"

tamanhoLimiteBusca = 32768

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

;;************************************************************************************

versaoLOGIND equ "1.9.1"

align 4

logind:

match =Moderno, TIPOLOGIN
{

.sobreSistema:
db 10,10
db "  88                                                                                88", 10
db "  88                                                                                ''", 10
db "  88", 10
db "  88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8", 10
db "  88P'    '88 a8P     88  `P8, ,8P'  ''     `P8 a8'    `P88 a8'     '8a 88P'   `'88 88  `P8, ,8P'", 10
db "  88       88 8PP'''''''    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(", 10
db "  88       88 '8b,   ,aa  ,d8' '8b,  88,    ,88 '8a,   ,d88 '8a,   ,a8' 88       88 88  ,d8' '8b,", 10
db "  88       88  `'Pbbd8'' 8P'     `P8 `'8bbdP'P8  `'PbbdP'P8  `'PbbdP''  88       88 88 8P'     `P8", 10
db "                                                 aa,    ,88", 10
db "                                                  'P8bbdP'", 10, 10
db "                                  Hexagonix Operating System", 10, 10
db "                       Copyright (C) 2015-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "                                     All rights reserved.", 10, 0

}

match =Hexagonix, TIPOLOGIN
{

.sobreSistema:
db 0

}

.arquivo:
db "passwd", 0 ;; Nome do arquivo de configuração de login
.posicaoBX: ;; Marcação da posição de busca no conteúdo do arquivo
dw 0
.versaoSistema:
db 10, "Hexagonix version ", 0
.console:
db " (tty0)", 0
.semArquivoUnix:
db 10, 10, "The user database was not found on the volume.", 10, 0
.colcheteEsquerdo:
db " [", 0
.colcheteDireito:
db "]", 0
.temaClaro:
db "light", 0
.temaEscuro:
db "dark", 0
.semVersao:
db "[unknown]", 0
.verboseLogind:
db "logind version ", versaoLOGIND, ".", 0
.OOBE:
db "oobe", 0

;; Buffers

escolhaTema: times 7 db 0

;;************************************************************************************

iniciologind: ;; Ponto de entrada

;; O logind é um daemon que só deve ser utilizado durante a inicialização.
;; Para isso, ele deve checar se o PID é 3 (init=1 e login=2).

    hx.syscall obterPID

    cmp eax, 03h
    je iniciarExecucao

    hx.syscall encerrarProcesso

iniciarExecucao:

    logSistema logind.verboseLogind, 0, Log.Prioridades.p4

;; Agora vamos inicializar o console virtual tty1, limpando seu conteúdo e definindo suas
;; propriedades gráficas. Primeiro, devemos salvar a posição do cursor no console atual,
;; uma vez que ele terá sua posição reiniciada com a limpeza do console. Essa etapa tira essa
;; complexidade do Hexagon, reduzindo possíveis bugs e permitindo expandir para outros consoles
;; no futuro sem precisar alterar algo no kernel.

    hx.syscall obterCursor

    push edx ;; Salvar posição atual do console

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Abre o console secundário

    hx.syscall hx.open ;; Abre o dispositivo

    hx.syscall limparTela

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reabre o console padrão

    hx.syscall hx.open ;; Abre o dispositivo

    pop edx ;; Restaurar posição do console

    hx.syscall definirCursor

.verificarOOBE:

    mov esi, logind.OOBE

    hx.syscall arquivoExiste

    mov esi, logind.OOBE
    mov eax, 0h

    hx.syscall iniciarProcesso

    jc .continuar

.continuar:

    call checarBaseDados

match =Moderno, TIPOLOGIN
{

    call verificarTema

    hx.syscall limparTela

}

    call exibirInfoSistema

    jmp terminar

;;************************************************************************************

verificarTema:

    pusha

    push es

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov esi, logind.arquivo
    mov edi, bufferArquivo

    hx.syscall hx.open

    jc .arquivoUsuarioAusente

    mov si, bufferArquivo ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, 0FFFFh ;; Inicia na posição -1, para que se possa encontrar os delimitadores

.procurarEntreDelimitadores:

    inc bx

    mov word[logind.posicaoBX], bx

    cmp bx, tamanhoLimiteBusca
    je .nomeTemaInvalido ;; Caso nada seja encontrado até o tamanho limite, cancele a busca

    mov al, [ds:si+bx]

    cmp al, '<'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado

;; BX agora aponta para o primeiro caractere do nome de usuário resgatado do arquivo

    push ds ;; Segmento de dados do modo usuário (seletor 38h)
    pop es

    mov di, escolhaTema ;; O tema será copiado para ES:DI

    mov si, bufferArquivo

    add si, bx ;; Mover SI para aonde BX aponta

    mov bx, 0 ;; Iniciar em 0

.obterTema:

    inc bx

    cmp bx, 7
    je .nomeTemaInvalido ;; Se nome de usuário maior que 15, o mesmo é inválido

    mov al, [ds:si+bx]

    cmp al, '>' ;; Se encontrar outro delimitador, o nome de usuário foi carregado com sucesso
    je .temaObtido

;; Se não estiver pronto, armazenar o caractere obtido

    stosb

    jmp .obterTema

.temaObtido:

    mov edi, escolhaTema
    mov esi, logind.temaClaro

    hx.syscall compararPalavrasString

    jc .selecionarTemaClaro

    mov edi, escolhaTema
    mov esi, logind.temaEscuro

    hx.syscall compararPalavrasString

    jc .selecionarTemaEscuro

    mov word bx, [logind.posicaoBX]

    mov si, bufferArquivo

    jmp .procurarEntreDelimitadores

.selecionarTemaClaro:

    pop es

    popa

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Abrir primeiro console virtual

    hx.syscall hx.open ;; Abre o dispositivo

    mov eax, PRETO
    mov ebx, BRANCO_ANDROMEDA

    hx.syscall definirCor

    hx.syscall limparTela ;; Limpa seu conteúdo

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reabre o dispositivo de saída padrão

    hx.syscall hx.open ;; Abre o dispositivo

    mov eax, PRETO
    mov ebx, BRANCO_ANDROMEDA

    hx.syscall definirCor

    hx.syscall limparTela ;; Limpa seu conteúdo

    ret

.selecionarTemaEscuro:

    mov esi, Hexagon.LibASM.Dev.video.tty1 ;; Abrir primeiro console virtual

    hx.syscall hx.open ;; Abre o dispositivo

    mov eax, BRANCO_ANDROMEDA
    mov ebx, PRETO

    hx.syscall definirCor

    hx.syscall limparTela ;; Limpa seu conteúdo

    mov esi, Hexagon.LibASM.Dev.video.tty0 ;; Reabre o console padrão

    hx.syscall hx.open ;; Abre o dispositivo

    mov eax, BRANCO_ANDROMEDA
    mov ebx, PRETO

    hx.syscall definirCor

    hx.syscall limparTela ;; Limpa seu conteúdo

.nomeTemaInvalido:

    pop es

    popa

    ret

.arquivoUsuarioAusente:

    pop es

    popa

    fputs logind.semArquivoUnix

    jmp terminar

;;************************************************************************************

exibirInfoSistema:

    fputs logind.sobreSistema

    fputs logind.versaoSistema

    call obterVersaoDistribuicao

    jc .erro

    fputs versaoObtida

match =Moderno, TIPOLOGIN
{

    fputs logind.colcheteEsquerdo

    fputs codigoObtido

    fputs logind.colcheteDireito

}

    jmp .continuar

.erro:

    fputs logind.semVersao

    jmp .continuar

.continuar:

    fputs logind.console

    novaLinha

    ret

;;************************************************************************************

verificarConsistencia:

    call verificarTema ;; Caso algum processo seja finalizado após alterar
                       ;; o plano de fundo padrão

    hx.syscall limparTela

    ret

;;************************************************************************************

terminar:

    hx.syscall encerrarProcesso

;;************************************************************************************

checarBaseDados:

    clc

    mov esi, logind.arquivo

    hx.syscall arquivoExiste

    ret

;;************************************************************************************

enderecoCarregamento:

bufferArquivo: ;; Local onde o arquivo de configuração será aberto
