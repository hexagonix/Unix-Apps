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

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametros], edi
    
    call obterParametros
    
    jc  usoAplicativo
    
    push esi
    push edi
    
    mov edi, cp.parametroAjuda
    mov esi, [parametros]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, cp.parametroAjuda2
    mov esi, [parametros]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    pop edi
    pop esi
    
    mov esi, [arquivoEntrada]
    
    Hexagonix arquivoExiste
    
    jc fonteNaoEncontrado
    
    mov esi, [arquivoSaida]
    
    Hexagonix arquivoExiste
    
    jnc destinoPresente
 
;; Agora vamos abrir o arquivo fonte para cópia
    
    mov esi, [arquivoEntrada]
    mov edi, bufferArquivo
    
    Hexagonix abrir
    
    jc erroAoAbrir
    
    mov esi, [arquivoEntrada]
    
    Hexagonix arquivoExiste

;; Salvar arquivo no disco

    mov esi, [arquivoSaida]
    mov edi, bufferArquivo
    
    Hexagonix salvarArquivo
    
    jc erroAoSalvar
    
    mov esi, cp.copiaConcluida
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

erroAoSalvar:

    mov esi, cp.erroSalvando
    
    imprimirString
    
    jmp terminar

;;************************************************************************************
    
erroAoAbrir:

    mov esi, cp.erroAbrindo
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

fonteNaoEncontrado:

    mov esi, cp.fonteIndisponivel
    
    imprimirString
    
    jmp terminar

;;************************************************************************************
    
destinoPresente:

    mov esi, cp.destinoExistente
    
    imprimirString
    
    jmp terminar
    
;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

    mov esi, [parametros]
    mov [arquivoEntrada], esi
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov al, ' '
    
    Hexagonix encontrarCaractere
    
    jc usoAplicativo

    mov al, ' '
    
    call encontrarCaractereCP
    
    mov [arquivoSaida], esi
    
    jmp .pronto
    
.pronto:

    clc
    
    ret

;;************************************************************************************  

;; Realiza a busca de um caractere específico na String fornecida
;;
;; Entrada:
;;
;; ESI - String à ser verificada
;; AL  - Caractere para procurar
;;
;; Saída:
;;
;; ESI - Posição do caractere na String fornecida

encontrarCaractereCP:

    lodsb
    
    cmp al, ' '
    je .pronto
    
    jmp encontrarCaractereCP
    
.pronto:

    mov byte[esi-1], 0
    
    ret

;;************************************************************************************  

usoAplicativo:

    mov esi, cp.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************  

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoCP equ "2.0"  

cp:
    
.naoEncontrado:     db 10, 10, "Arquivo nao encontrado. verifique a ortografia e tente novamente.", 10, 0
.uso:               db 10, 10, "Uso: cp [arquivo de entrada] [arquivo de saida]", 10, 10
                    db "Realiza a copia de um arquivo fornecido em outro. Dois nomes de arquivo sao necessarios, sendo um", 10
                    db "de entrada e outro de saida.", 10, 10
                    db "cp versao ", versaoCP, 10, 10
                    db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                    db "Todos os direitos reservados.", 10, 0
.fonteIndisponivel: db 10, 10, "O arquivo fonte fornecido nao pode ser encontrado neste disco.", 10, 0                              
.destinoExistente:  db 10, 10, "Ja existe um arquivo com o nome fornecido para o destino. Por favor, remova o arquivo com o mesmo", 10
                    db "nome do destino e tente novamente.", 10, 0
.erroAbrindo:       db 10, 10, "Um erro ocorreu ao tentar abrir o arquivo de origem da copia.", 10
                    db "Tente novamente. Se o erro persistir, reinicie o computador.", 10, 0
.erroSalvando:      db 10, 10, "Um erro ocorreu ao solicitar o salvamento do arquivo de destino no disco.", 10
                    db "Isso pode ter ocorrido devido a uma protecao de escrita, remocao da unidade", 10
                    db "de armazenamento ou devido ao fato do Sistema estar ocupado. Tente novamente", 10
                    db "mais tarde.", 10, 0
.copiaConcluida:    db 10, 10, "O arquivo foi copiado com sucesso.", 10, 0
 .parametroAjuda:   db "?", 0
 .parametroAjuda2:  db "--ajuda", 0
               
parametros dd 0     

arquivoEntrada: dd ?
arquivoSaida:   dd ?

regES:  dw 0
     
bufferArquivo:
