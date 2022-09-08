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
;; Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes
;; Todos os direitos reservados.

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

inicioAPP:

    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
    
    mov edi, clear.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, clear.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    jmp realizarLimpeza

;;************************************************************************************

realizarLimpeza:

    mov esi, vd1         ;; Abrir o primeiro console virtual
    
    Hexagonix abrir      ;; Abre o dispositivo
    
    jc .erro
    
    Hexagonix limparTela ;; Limpa seu conteúdo
    
    mov esi, vd0         ;; Reabre o console principal
    
    Hexagonix abrir      ;; Abre o dispositivo

    Hexagonix limparTela
    
    jmp terminar
    
.erro:

    mov esi, clear.erro
    
    imprimirString
    
    jmp terminar
    
;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

usoAplicativo:
    
    mov esi, clear.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoCLEAR equ "1.0"

clear:

.erro:            db 10, 10, "Erro abrindo um console.", 10, 10, 0
.uso:             db 10, 10, "Uso: clear", 10, 10
                  db "Limpa o conteudo do console principal (vd0) e de consoles virtuais.", 10, 10
                  db "clear versao ", versaoCLEAR, 10, 10
                  db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
       
vd0:   db "vd0", 0 ;; Console principal
vd1:   db "vd1", 0 ;; Primeiro console virtual

parametro: dd ?

