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

;;************************************************************************************

inicioAPP: ;; Ponto de entrada do aplicativo

    mov [parametro], edi
    
    novaLinha
    
    mov edi, ps.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, ps.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    mov edi, ps.parametroPID
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc parametroPID
    
    mov edi, ps.parametroMemoria
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc parametroMemoria
    
    mov edi, ps.parametroOutros
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc parametroOutrosProcessos
    
    jmp parametroMemoria

;;************************************************************************************          

parametroPID:
    
    hx.syscall hx.getpid
    
    push eax
    
    fputs ps.pid
    
    pop eax
    
    imprimirInteiro
    
    novaLinha
    novaLinha
    
    jmp parametroMemoria.linha

;;************************************************************************************          

parametroMemoria:

.linha:
    
    fputs ps.usoMem
    
    hx.syscall usoMemoria
    
    imprimirInteiro
    
    fputs ps.kbytes
    
    jmp terminar

;;************************************************************************************

parametroOutrosProcessos:

    hx.syscall hx.getpid
    
    push eax
    
    fputs ps.numeroProcessos
    
    pop eax
    
    imprimirInteiro
    
    fputs ps.processos
        
    jmp terminar
    
;;************************************************************************************
    
usoAplicativo:

    fputs ps.uso
    
    jmp terminar

;;************************************************************************************  

terminar:   
    
    hx.syscall encerrarProcesso

;;************************************************************************************

versaoPS equ "1.1.2"

parametro: dd ?

ps:
    
.pid:              db "PID of this process: ", 0
.usoMem:           db "Memory usage: ", 0
.kbytes:           db " bytes used by running processes.", 0
.uso:              db "Usage: ps [parameter]", 10, 10
                   db "Displays process information and usage of memory and system resources.", 10, 10
                   db "Possible parameters (in case of missing parameters, the '-v' option will be selected):", 10, 10
                   db "-t - Displays all possible process and system resource information.", 10
                   db "-v - Display only memory usage of running processes.", 10, 10
                   db "-o - Displays the number of processes in the execution queue.", 10, 10
                   db "ps version ", versaoPS, 10, 10
                   db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                   db "All rights reserved.", 0
.parametroAjuda:   db "?", 0  
.parametroAjuda2:  db "--help", 0
.parametroPID:     db "-t", 0
.parametroOutros:  db "-o", 0
.parametroMemoria: db "-v", 0     
.numeroProcessos:  db "There are currently ", 0
.processos:        db " processes in the Hexagonix(R) runtime stack.", 0
    
