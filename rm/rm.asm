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
include "erros.s"

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je semParametro
    
    mov edi, rm.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, rm.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    mov esi, [parametro]
    
    Hexagonix arquivoExiste
    
    jc .arquivoNaoEncontrado
    
    novaLinha
    novaLinha
    
    mov esi, rm.confirmacao
    
    imprimirString
    
.obterTeclas:

    Hexagonix aguardarTeclado
    
    cmp al, 's'
    je .deletar
    
    cmp al, 'S'
    je .deletar
    
    cmp al, 'n'
    je .abortar
    
    cmp al, 'N'
    je .abortar

    jmp .obterTeclas        
    
    
.arquivoNaoEncontrado:

    mov esi, rm.naoEncontrado
    
    imprimirString
    
    jmp terminar

.deletar:

    Hexagonix imprimirCaractere
    
    mov esi, [parametro]
    
    Hexagonix deletarArquivo
    
    jc .erroDeletando
    
    mov esi, rm.deletado
    
    imprimirString
    
    jmp terminar

.abortar:

    Hexagonix imprimirCaractere
    
    mov esi, rm.abortar
    
    imprimirString
    
    jmp terminar
    
.erroDeletando:

    push eax

    mov esi, rm.erroDeletando
    
    imprimirString  
    
    pop eax
    
    cmp eax, IO.operacaoNegada
    je .permissaoNegada
    
    jmp terminar

.permissaoNegada:

    mov esi, rm.permissaoNegada
    
    imprimirString
    
    jmp terminar
    
;;************************************************************************************

usoAplicativo:

    mov esi, rm.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

semParametro:

    mov esi, rm.semParametro
    
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

versaoRM equ "1.0"

rm:

.naoEncontrado:   db 10, 10, "Arquivo nao encontrado. Verifique a ortografia e tente novamente.", 10, 0
.uso:             db 10, 10, "Uso: rm [arquivo]", 10, 10
                  db "Solicita a exclusao de um arquivo no disco atual.", 10, 10
                  db "rm versao ", versaoRM, 10, 10
                  db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.confirmacao:     db "Voce tem certeza que deseja excluir este arquivo (s/N)? ", 0
.deletado:        db 10, 10, "O arquivo solicitado foi deletado com sucesso.", 10, 0
.erroDeletando:   db 10, 10, "Um erro ocorreu durante a solicitacao. Nenhum arquivo foi deletado.", 10, 10, 0  
.abortar:         db 10, 10, "A operacao foi abortada pelo usuario.", 10, 0  
.parametroAjuda:  db "?", 0  
.parametroAjuda2: db "--ajuda", 0    
.semParametro:    db 10, 10, "Um nome de arquivo necessario esta ausente.", 10
                  db "Utilize 'rm ?' para ajuda com este utilitario.", 10, 0  
.permissaoNegada: db "Apenas um usuario administrativo pode concluir essa acao.", 10
                  db "Para tanto, realize o login em um destes usuarios com poderes administrativos.", 10, 0                 
    
parametro: dd ?

regES:  dw 0
     
bufferArquivo:
