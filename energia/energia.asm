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
include "log.s"

;;************************************************************************************

inicioAPP:  

    push ds
    pop es          
    
    mov [parametro], edi ;; Salvar os parâmetros da linha de comando para uso futuro
    
    logSistema energia.Verbose.inicio, 00h, Log.Prioridades.p4
    logSistema energia.Verbose.estado, 00h, Log.Prioridades.p4

    mov esi, [parametro]
    
    cmp byte[esi], 0
    je faltaArgumento

    mov edi, energia.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, energia.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, energia.parametroDesligar
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc iniciarDesligamento
    
    mov edi, energia.parametroReiniciar
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc iniciarReinicio

    mov edi, energia.parDesligarSemEco
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc iniciarDesligamentoSemEco

    mov edi, energia.parReiniciarSemEco
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc iniciarReinicioSemEco

    jmp usoAplicativo

;;************************************************************************************

iniciarDesligamento:
    
    novaLinha
    
    mov esi, energia.sistema

    imprimirString
    
    jmp desligarHexagon

;;************************************************************************************

iniciarDesligamentoSemEco:

    logSistema energia.Verbose.parametroDesligar, 00h, Log.Prioridades.p4

    call prepararSistemaSemEco

    logSistema energia.Verbose.parametroSolicitar, 00h, Log.Prioridades.p4

    Hexagonix desligarPC

    jmp terminar

;;************************************************************************************

iniciarReinicioSemEco:

    logSistema energia.Verbose.parametroReiniciar, 00h, Log.Prioridades.p4

    call prepararSistemaSemEco

    logSistema energia.Verbose.parametroSolicitar, 00h, Log.Prioridades.p4

    Hexagonix reiniciarPC

    jmp terminar

;;************************************************************************************

iniciarReinicio:

    novaLinha
    
    mov esi, energia.sistema

    imprimirString
    
    jmp reiniciarHexagon

;;************************************************************************************
    
desligarHexagon:

    logSistema energia.Verbose.parametroDesligar, 00h, Log.Prioridades.p4

    call prepararSistema

    logSistema energia.Verbose.parametroSolicitar, 00h, Log.Prioridades.p4

    Hexagonix desligarPC

    jmp terminar

;;************************************************************************************

reiniciarHexagon:

    logSistema energia.Verbose.parametroReiniciar, 00h, Log.Prioridades.p4

    call prepararSistema

    logSistema energia.Verbose.parametroSolicitar, 00h, Log.Prioridades.p4

    Hexagonix reiniciarPC

    jmp terminar

;;************************************************************************************

prepararSistemaSemEco:

;; Qualquer ação que possa ser incluída aqui

    ret

;;************************************************************************************

prepararSistema:

    mov esi, energia.msgDesligamento

    imprimirString

    mov ecx, 500
    
    Hexagonix causarAtraso
    
    mov esi, energia.msgPronto

    imprimirString

    mov esi, energia.msgFinalizando

    imprimirString

    mov ecx, 500
    
    Hexagonix causarAtraso
    
    mov esi, energia.msgPronto

    imprimirString

    mov esi, energia.msgHexagonix

    imprimirString

    mov ecx, 500
    
    Hexagonix causarAtraso
    
    mov esi, energia.msgPronto

    imprimirString

    mov esi, energia.msgDiscos

    imprimirString

    mov ecx, 500
    
    Hexagonix causarAtraso
    
    mov esi, energia.msgPronto

    imprimirString

    novaLinha

    ret

;;************************************************************************************

usoAplicativo:

    mov esi, energia.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

faltaArgumento:

    mov esi, energia.argumentos
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

terminar:

    logSistema energia.Verbose.falhaSolicitacao, 00h, Log.Prioridades.p4

    Hexagonix encerrarProcesso

;;************************************************************************************
;;
;; Dados do aplicativo
;;
;;************************************************************************************

rotuloMENSAGEM equ "[Energia]: "

versaoENERGIA  equ "1.0"

energia:

.parametroDesligar:  db "-d", 0
.parDesligarSemEco:  db "-de", 0
.parametroReiniciar: db "-r", 0
.parReiniciarSemEco: db "-re", 0
.msgDesligamento:    db 10, 10, "!> Preparing to shut down your computer... ", 0
.msgFinalizando:     db 10, 10, "#> Terminating all processes still running...  ", 0
.msgHexagonix:       db 10, 10, "#> Shutting down the Hexagonix(R) Operating System...    ", 0
.msgDiscos:          db 10, 10, "#> Stoping disks and shutting down your computer... ", 0
.msgPronto:          db "[Ok]", 0
.msgFalha:           db "[Fail]", 0
.parametroAjuda:     db "?", 0  
.parametroAjuda2:    db "--help", 0
.sistema:            db 10, "Hexagonix(R) Operating System", 10, 10
                     db "Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes", 10
                     db "All rights reserved.", 10, 0
.argumentos:         db 10, 10, "An argument is required to control the state of this device.", 10, 0
.uso:                db 10, 10, "Usage: energia [argument]", 10, 10
                     db "Controls the state of the computer.", 10, 10
                     db "Possible arguments:", 10, 10
                     db "-d - Prepares and initiates computer shutdown.", 10
                     db "-r - Prepare and restart the computer.", 10, 10
                     db "energia version ", versaoENERGIA, 10, 10
                     db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
                     db "All rights reserved.", 10, 0

energia.Verbose:

.inicio:             db rotuloMENSAGEM, "starting power management (version ", versaoENERGIA, ")...", 0
.estado:             db rotuloMENSAGEM, "getting device state...", 0
.parametroDesligar:  db rotuloMENSAGEM, "received shutdown request.", 0
.parametroReiniciar: db rotuloMENSAGEM, "reboot request received.", 0
.parametroSolicitar: db rotuloMENSAGEM, "sending signal to processes and request to Hexagon...", 0
.falhaSolicitacao:   db rotuloMENSAGEM, "failed to process the request or request failed by Hexagon.", 0

parametro: dd ?
