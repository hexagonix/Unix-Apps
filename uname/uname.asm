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
include "verUtils.s"
    
;;************************************************************************************          

align 4

versaoUNAME equ "2.5"

uname:

;; Parâmetros (novos) POSIX.2 e compatível com o uname do BSD:
;;
;; -a: tudo
;; -s: nome do kernel
;; -n: hostname
;; -r: lançamento do kernel
;; -v: versão do kernel
;; -m: tipo de máquina
;; -p: tipo de processador
;; -i: plataforma de hardware
;; -o: sistema operacional

.parametrosSistema:         db " Unix" , 0 
.sistemaOperacional:        db "Hexagonix", 0
.usuario:                   db " ", 0
.espaco:                    db " ", 0
.maquina:                   db "Hexagonix-PC", 0
.colcheteEsquerdo:          db "[", 0
.colcheteDireito:           db "]", 0
.pontoVirgula:              db "; ", 0
.nucleo:                    db " Kernel ", 0
.buildHexagon:              db "(build ", 0
.fecharParenteses:          db ")", 0
.versao:                    db " version ", 0 
.arquiteturai386:           db " i386", 0
.arquiteturaamd64:          db " amd64", 0
.hexagonix:                 db "Hexagonix", 0
.parametroAjuda:            db "?", 0  
.parametroAjuda2:           db "--help", 0
.parametroExibirTudo:       db "-a", 0
.parametroExibirNomeKernel: db "-s", 0
.parametroExibirHostname:   db "-n", 0
.parametroExibirLancamento: db "-r", 0
.parametroExibirTipo:       db "-m", 0
.parametroExibirArch:       db "-p", 0
.parametroExibirPlataforma: db "-i", 0
.parametroExibirVersao:     db "-v", 0   
.parametroExibirSO:         db "-o", 0   
.arquivoUnix:               db "host.unx", 0
.naoSuportado:              db "Unknown architecture.", 0      
.plataformaPC:              db "PC", 0  
.uso:                       db 10, "Usage: uname [parameter]", 10, 10
                            db "Displays system information.", 10, 10
                            db "Possible parameters (in case of missing parameters, the '-s' option will be selected):", 10, 10
                            db " -a: Displays all possible system, kernel and machine information.", 10
                            db " -s: Running kernel name.", 10
                            db " -n: Display the hostname of the machine running the system.", 10
                            db " -r: Release of the running kernel.", 10
                            db " -v: Running kernel version.", 10
                            db " -m: Machine type.", 10
                            db " -p: System processor architecture.", 10
                            db " -i: System hardware platform.", 10
                            db " -o: Name of running operating system.", 10, 10
                            db "uname version ", versaoUNAME, 10, 10
                            db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                            db "All rights reserved.", 0                     
ponto:                      db ".", 0

parametro: dd ?

;;************************************************************************************

align 32

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi
    
    mov edi, uname.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, uname.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

;; -a

    mov edi, uname.parametroExibirTudo
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirTudo

;; -s

    mov edi, uname.parametroExibirNomeKernel
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirNomeKernel

;; -n

    mov edi, uname.parametroExibirHostname
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirHostname

;; -r

    mov edi, uname.parametroExibirLancamento
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirLancamento

;; -m

    mov edi, uname.parametroExibirTipo
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirArquitetura

;; -p

    mov edi, uname.parametroExibirArch
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirArquitetura

;; -i 

    mov edi, uname.parametroExibirPlataforma
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirPlataforma

;; -v

    mov edi, uname.parametroExibirVersao
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirVersaoApenas

;; -o

    mov edi, uname.parametroExibirSO
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc exibirInfoSistemaOperacional

    jmp exibirNomeKernel

;;************************************************************************************

exibirNomeKernel:

    call espacoPadrao 
    
    hx.syscall retornarVersao
    
    imprimirString

    jmp terminar 

;;************************************************************************************

exibirHostname:

    call espacoPadrao

    call obterHostname

    jmp terminar 

;;************************************************************************************

exibirLancamento:

    call espacoPadrao

    call versaoHexagon

    jmp terminar 

;;************************************************************************************

exibirArquitetura:

    call espacoPadrao

    hx.syscall retornarVersao

;; Em EDX temos a arquitetura
    
    cmp edx, 01
    je .i386

    cmp edx, 02
    je .x86_64 

    mov esi, uname.naoSuportado

    imprimirString

    jmp .terminar 

.i386:

    mov esi, uname.arquiteturai386

    imprimirString
    
    jmp .terminar

.x86_64:

    mov esi, uname.arquiteturaamd64

    imprimirString

    jmp .terminar

.terminar:

    jmp terminar

;;************************************************************************************

exibirPlataforma:

    call espacoPadrao

    mov esi, uname.plataformaPC

    imprimirString

    jmp terminar 

;;************************************************************************************

exibirTudo:

    call espacoPadrao 
    
    mov esi, uname.sistemaOperacional

    imprimirString

    mov esi, uname.espaco
    
    imprimirString

    call obterHostname

.continuarHost:

    mov esi, uname.espaco
    
    imprimirString
    
    hx.syscall retornarVersao
    
    imprimirString

;; Para ficar de acordo com o padrão do FreeBSD, a mensagem "versao" não é exibido

    ;; mov esi, uname.versao
    
    ;; imprimirString

    mov esi, uname.espaco
    
    imprimirString
    
    call versaoHexagon
    
    cmp edx, 01h 
    je .i386

    cmp edx, 02h
    je .amd64

.i386:

    mov esi, uname.arquiteturai386

    imprimirString

    jmp .continuar

.amd64:

    mov esi, uname.arquiteturaamd64

    imprimirString

    jmp .continuar

.continuar:
    
    mov al, " "

    hx.syscall imprimirCaractere

    mov esi, uname.hexagonix
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

exibirInfoSistemaOperacional:

    call espacoPadrao 
    
    mov esi, uname.sistemaOperacional
    
    imprimirString
    
    jmp terminar
    
;;************************************************************************************

exibirVersaoApenas:

    call espacoPadrao 
    
    hx.syscall retornarVersao
    
    imprimirString
    
    mov esi, uname.espaco

    imprimirString

    call versaoHexagon

    jmp terminar

;;************************************************************************************
    
;; Solicita a versão do kernel, a decodifica e exibe para o usuário
    
versaoHexagon:

    hx.syscall retornarVersao
    
    push ecx
    push ebx
    
    imprimirInteiro
    
    mov esi, ponto
    
    imprimirString
    
    pop eax
    
    imprimirInteiro
    
    pop ecx
    
    cmp ch, 0
    je .continuar

    push ecx

    mov esi, ponto
    
    imprimirString
    
    pop ecx 
    
    mov al, ch
    
    hx.syscall imprimirCaractere

.continuar:

    mov esi, uname.espaco

    imprimirString

    mov esi, uname.buildHexagon

    imprimirString

    hx.syscall retornarVersao
    
    mov esi, edi 

    imprimirString

    mov esi, uname.fecharParenteses

    imprimirString

    ret

;;************************************************************************************

usoAplicativo:

    mov esi, uname.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************  

terminar:    

    hx.syscall encerrarProcesso
    
;;*****************************************************************************

espacoPadrao:

    novaLinha

    ret

;;*****************************************************************************

obterHostname:

;; Vamos agora exibir o nome de host 

    mov edi, enderecoCarregamento
    mov esi, uname.arquivoUnix
    
    hx.syscall abrir
    
    jc .arquivoNaoEncontrado ;; Se não for encontrado, exibir o padrão

;; Se encontrado, exibir o nome de host definido 

    clc 

    mov esi, enderecoCarregamento

    hx.syscall tamanhoString

    mov edx, eax 
    dec edx

    mov al, 0
    
    hx.syscall inserirCaractere

    mov esi, enderecoCarregamento
    
    imprimirString

    jmp .retornar 

.arquivoNaoEncontrado:

    stc 

    mov esi, uname.maquina
    
    imprimirString

.retornar:

    ret

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

enderecoCarregamento: