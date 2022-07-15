;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
;;              ┌─┘│          
;;              └──┘          
;;
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

    mov esi, energia.msgAndromeda

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

align 128

rotuloMENSAGEM equ "[Energia]: "

versaoENERGIA  equ "1.0"

energia:

.parametroDesligar:  db "-d", 0
.parDesligarSemEco:  db "-de", 0
.parametroReiniciar: db "-r", 0
.parReiniciarSemEco: db "-re", 0
.msgDesligamento:    db 10, 10, "!> Preparando para desligar seu computador... ", 0
.msgFinalizando:     db 10, 10, "#> Finalizando todos os processos ainda em execucao...  ", 0
.msgAndromeda:       db 10, 10, "#> Finalizando o Sistema Operacional Hexagonix(R)...    ", 0
.msgDiscos:          db 10, 10, "#> Finalizando os discos e desligando seu computador... ", 0
.msgPronto:          db "[Concluido]", 0
.msgFalha:           db "[Falha]", 0
.parametroAjuda:     db "?", 0  
.parametroAjuda2:    db "--ajuda", 0
.sistema:            db 10, "Sistema Operacional Hexagonix(R)", 10, 10
                     db "Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes", 10
                     db "Todos os direitos reservados.", 10, 0
.argumentos:         db 10, 10, "Um argumento e necessario para controlar o estado deste dispositivo.", 10, 0
.uso:                db 10, 10, "Uso: energia [argumento]", 10, 10
                     db "Controla o estado do computador.", 10, 10 
                     db "Argumentos possiveis:", 10, 10
                     db "-d - Prepara e inicia o desligamento do computador.", 10
                     db "-r - Prepara e reinicia o computador.", 10, 10                                    
                     db "energia versao ", versaoENERGIA, 10, 10
                     db "Copyright (C) 2022 Felipe Miguel Nery Lunkes", 10
                     db "Todos os direitos reservados.", 10, 0

energia.Verbose:

.inicio:             db rotuloMENSAGEM, "iniciando o gerenciamento de energia (versao ", versaoENERGIA, ")...", 0
.estado:             db rotuloMENSAGEM, "obtendo o estado do dispositivo...", 0
.parametroDesligar:  db rotuloMENSAGEM, "recebida solicitacao de desligamento.", 0
.parametroReiniciar: db rotuloMENSAGEM, "recebida solicitacao de reinicializacao.", 0
.parametroSolicitar: db rotuloMENSAGEM, "enviando sinal para processos e solicitacao ao Hexagon...", 0
.falhaSolicitacao:   db rotuloMENSAGEM, "falha ao processar a solicitacao ou falha na requisicao pelo Hexagon.", 0

parametro: dd ?
