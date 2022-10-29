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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioAPP, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"
include "Estelar/estelar.s"

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi
    
;;************************************************************************************

    Hexagonix obterCor

    mov dword[top.corFonte], eax
    mov dword[top.corFundo], ebx

;;************************************************************************************

    novaLinha
    novaLinha
    
    mov edi, top.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, top.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    jmp exibirProcessos

exibirProcessos:

    mov esi, top.inicio
    
    imprimirString
    
    mov esi, top.processosCarregados
    
    imprimirString
    
    Hexagonix obterProcessos
    
    push eax
    
    mov eax, VERMELHO
    
    call definirCorTexto
    
    imprimirString
    
    call definirCorPadrao
    
    novaLinha
    
    mov esi, top.numeroProcessos
    
    imprimirString
    
    mov eax, VERMELHO
    
    call definirCorTexto
    
    pop eax
    
    imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, top.usoMem
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
    
    call definirCorTexto
    
    Hexagonix usoMemoria
    
    imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, top.bytes
    
    imprimirString
    
    mov esi, top.memTotal
    
    imprimirString
    
    mov eax, VERDE_FLORESTA
    
    call definirCorTexto
    
    Hexagonix usoMemoria
    
    mov eax, ecx
    
    imprimirInteiro
    
    call definirCorPadrao
    
    mov esi, top.mbytes
    
    imprimirString
    
    jmp terminar
    
;;************************************************************************************
    
usoAplicativo:

    mov esi, top.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************  

terminar:   

    novaLinha
    
    Hexagonix encerrarProcesso

;;************************************************************************************

;; Função para definir a cor do conteúdo à ser exibido
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorTexto:

    mov ebx, [top.corFundo]
    
    Hexagonix definirCor
    
    ret

;;************************************************************************************

definirCorPadrao:

    mov eax, [top.corFonte]
    mov ebx, [top.corFundo]
    
    Hexagonix definirCor
    
    ret

;;************************************************************************************

parametro: dd ?

versaoTOP equ "1.1"

top:

.inicio:              db "Visualizador de processos do Sistema Operacional Hexagonix(R)", 10, 10, 0   
.pid:                 db "PID deste processo: ", 0
.usoMem:              db 10, 10, "Uso de memoria: ", 0
.memTotal:            db 10, "Total de memoria instalada identificada: ", 0
.bytes:               db " bytes utilizados pelos processos em execucao.", 0
.kbytes:              db " kbytes.", 0
.mbytes:              db " megabytes.", 0
.uso:                 db "Uso: top", 10, 10
                      db "Exibe os processos carregados na pilha de execucao do Hexagonix(R).", 10, 10 
                      db "Processos do Kernel sao filtrados e nao exibidos nesta lista.", 10, 10            
                      db "top versao ", versaoTOP, 10, 10
                      db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 0
.parametroAjuda:      db "?", 0  
.parametroAjuda2:     db "--ajuda", 0
.processos:           db " processos na pilha de execucao.", 0
.processosCarregados: db "Processos presentes na pilha de execucao do Sistema: ", 10, 10, 0
.numeroProcessos:     db 10, "Numero de processos presentes na pilha de execucao: ", 0 
.corFonte:            dd 0
.corFundo:            dd 0
