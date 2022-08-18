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

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov edi, echo.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, echo.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    novaLinha
    novaLinha
    
    mov esi, [parametro]
    
    imprimirString
    
    novaLinha
    
    jmp terminar

;;************************************************************************************

usoAplicativo:

    mov esi, echo.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoECHO equ "1.0"

echo:

.uso:             db 10, 10, "Uso: echo [mensagem]", 10, 10
                  db "Envia o conteudo de uma mensagem para o console principal.", 10, 10
                  db "echo versao ", versaoECHO, 10, 10
                  db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
     
parametro: dd ?

regES:     dw 0
