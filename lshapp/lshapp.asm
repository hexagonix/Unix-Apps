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
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov edi, lshapp.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, lshapp.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov esi, [parametro]
    
    Hexagonix cortarString
    
    Hexagonix tamanhoString
    
    cmp eax, 13
    jl .obterInformacoes
    
    mov esi, lshapp.arquivoInvalido
    
    imprimirString
    
    jmp .fim
    
.obterInformacoes:

    Hexagonix arquivoExiste

    jc .semArquivo
    
    push eax
    push esi

    mov esi, lshapp.infoArquivo
    
    imprimirString
    
    pop esi

    call manterArquivo

    imprimirString

    mov esi, lshapp.tamanhoArquivo
    
    imprimirString
    
    pop eax 
    
    imprimirInteiro
    
    mov esi, lshapp.bytes
    
    imprimirString

;; Primeiro vamos ver se se trata de uma imagem executável. Se sim, podemos pular todo o
;; restante do processamento. Isso garante que imagens executáveis sejam relatadas como
;; tal mesmo se tiverem diferentes extensões, visto que cada shell pode procurar por um
;; tipo de extensão específico/preferido além de .APP. Imagens acessórias que necessitam
;; de ser chamadas por outro processo no âmbito de sua execução podem apresentar outra extensão.
;; O próprio Hexagon® é uma imagem HAPP mas apresenta extensão .SIS

    call verificarArquivoHAPP 

;; Se não for uma imagem executável, tentar identificar pela extensão, sem verificar o conteúdo
;; do arquivo

    jmp .fim

.semArquivo:

    mov esi, lshapp.semArquivo
   
    imprimirString

    jmp .fim    
    
.fim:
    
    jmp terminar

;;************************************************************************************

verificarArquivoHAPP:

    mov esi, nomeArquivo
    mov edi, bufferArquivo

    Hexagonix abrir

    jc inicioAPP.semArquivo

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHAPP

    cmp byte[edi+1], "A"
    jne .naoHAPP

    cmp byte[edi+2], "P"
    jne .naoHAPP

    cmp byte[edi+3], "P"
    jne .naoHAPP

    mov dh, byte[edi+4]
    mov byte[lshapp.arquitetura], dh

    mov dh, byte[edi+5]
    mov byte[lshapp.versaoMinima], dh

    mov dh, byte[edi+6]
    mov byte[lshapp.subverMinima], dh

    mov eax, dword[edi+7]
    mov dword[lshapp.pontoEntrada], eax

    mov ah, byte[edi+11]
    mov byte[lshapp.especieImagem], ah

    mov esi, lshapp.cabecalho
    
    imprimirString

    mov esi, lshapp.tipoArquitetura

    imprimirString

    cmp byte[lshapp.arquitetura], 01h
    je .i386

    cmp byte[lshapp.arquitetura], 02h
    je .amd64

    cmp byte[lshapp.arquitetura], 02h
    jg .arquiteturaInvalida

.i386:

    mov esi, lshapp.i386

    imprimirString

    jmp .continuar

.amd64:

    mov esi, lshapp.amd64

    imprimirString

    jmp .continuar

.arquiteturaInvalida:

    mov esi, lshapp.arquiteturaInvalida

    imprimirString

    jmp .continuar

.continuar:

    mov esi, lshapp.campoArquitetura

    imprimirString

    mov esi, lshapp.verHexagon

    imprimirString

    mov dh, byte[lshapp.versaoMinima]
    movzx eax, dh

    imprimirInteiro

    mov esi, lshapp.ponto

    imprimirString

    mov dh, byte[lshapp.subverMinima]
    movzx eax, dh

    imprimirInteiro

    mov esi, lshapp.camposVersaoHexagon

    imprimirString

    mov esi, lshapp.entradaCodigo

    imprimirString

    mov eax, dword[lshapp.pontoEntrada]
    
    imprimirHexadecimal

    mov esi, lshapp.campoEntrada

    imprimirString

    mov esi, lshapp.tipoImagem

    imprimirString

    ;; mov dh, byte[lshapp.especieImagem]
    ;; movzx eax, dh

    ;; imprimirInteiro

    cmp byte[lshapp.especieImagem], 01h
    je .HAPPExec

    cmp byte[lshapp.especieImagem], 02h
    je .HAPPLibS

    cmp byte[lshapp.especieImagem], 03h
    je .HAPPLibD

    mov esi, lshapp.HAPPDesconhecido

    imprimirString

    jmp .tipoHAPPListado

.HAPPExec:

    mov esi, lshapp.HAPPExec

    imprimirString

    jmp .tipoHAPPListado

.HAPPLibS:

    mov esi, lshapp.HAPPLibS

    imprimirString

    jmp .tipoHAPPListado

.HAPPLibD:

    mov esi, lshapp.HAPPLibD

    imprimirString

    jmp .tipoHAPPListado

.tipoHAPPListado:

    mov esi, lshapp.campoImagem

    imprimirString

    novaLinha

    ret

.naoHAPP:

    mov esi, lshapp.imagemInvalida

    imprimirString

    ret

;;************************************************************************************

usoAplicativo:

    mov esi, lshapp.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

manterArquivo:

    push esi
    push eax

    Hexagonix cortarString

    Hexagonix tamanhoString

    mov ecx, eax

    mov edi, nomeArquivo

    rep movsb       ;; Copiar (ECX) caracteres de ESI para EDI
    
    pop eax

    pop esi

    ret

;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

align 16

versaoLSHAPP equ "1.9.1"

lshapp:

.uso:                 db 10, 10, "Uso: lshapp [arquivo]", 10, 10
                      db "Recupera as informacoes de uma imagem HAPP.", 10, 10
                      db "lshapp versao ", versaoLSHAPP, 10, 10
                      db "Copyright (C) 2020-2022 Felipe Miguel Nery Lunkes", 10
                      db "Todos os direitos reservados.", 10, 0
.arquivoInvalido:     db 10, 10, "O nome de arquivo e invalido. Digite um nome de arquivo valido.", 10, 0
.infoArquivo:         db 10, 10, "Nome do arquivo: ", 0
.tamanhoArquivo:      db 10, "Tamanho deste arquivo: ", 0
.bytes:               db " bytes.", 10, 0
.imagemInvalida:      db 10, "<!> Esta nao e uma imagem HAPP valida -> [HAPP:-]. Tente outro arquivo.", 10, 0
.semArquivo:          db 10, 10, "<!> O arquivo solicitado nao esta disponivel neste disco.", 10, 10
                      db "<!> Verifique a ortografia e tente novamente.", 10, 0  
.tipoArquitetura:     db 10, 10, "> Arquitetura de destino da imagem: ", 0
.verHexagon:          db 10, "> Versao minima do Hexagon(R) necessaria a execucao: ", 0
.camposVersaoHexagon: db " -> [HAPP:versao e HAPP:subversao].", 0
.cabecalho:           db 10, "<+> Este arquivo contem uma imagem HAPP valida -> [HAPP:+].", 0
.i386:                db "i386", 0
.amd64:               db "amd64", 0
.campoArquitetura:    db " -> [HAPP:arquitetura].", 0
.arquiteturaInvalida: db "desconhecida", 0
.entradaCodigo:       db 10, "> Ponto de entrada da imagem: ?:", 0
.campoEntrada:        db " -> [HAPP:pontoEntrada].", 0
.tipoImagem:          db 10, "> Formato (tipo) de imagem HAPP: ", 0
.HAPPExec:            db "(Exec)", 0
.HAPPLibS:            db "(LibS)", 0
.HAPPLibD:            db "(LibD)", 0
.HAPPDesconhecido:    db "(?)", 0
.campoImagem:         db " -> [HAPP:formatoImagem].", 0
.parametroAjuda:      db "?", 0
.parametroAjuda2:     db "--ajuda", 0
.ponto:               db ".", 0

.pontoEntrada:        dd 0
.arquitetura:         db 0
.versaoMinima:        db 0
.subverMinima:        db 0
.especieImagem:       db 0

parametro:            dd ?
nomeArquivo: times 13 db 0
regES:                dw 0

;;************************************************************************************

bufferArquivo:
