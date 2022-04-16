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

include "../../../LibAPP/HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 9, 00, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/hexagon.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************

align 32

man:

.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda",0
.man:             db "Manual do Hexagonix(R)", 0
.uso:             db 10, 10, "Uso: man [utilitario]", 10, 10
                  db "Exibe ajuda detalhada dos utilitarios Unix instalados.", 10, 10      
                  db "Versao CoreUtils: ", versaoCoreUtils, 10
                  db "Versao UnixUtils: ", versaoUnixUtils, 10, 10                        
                  db "man versao ", versaoMAN, 10, 10
                  db "Copyright (C) 2018-2022 Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.aguardar:        db "Pressione <q> para sair.", 0
.naoEncontrado:   db ": manual nao encontrado para este utilitario.", 10, 0
.separador:       db 10, "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++", 10, 0
.extensaoManual:  db ".man", 0

;;************************************************************************************

inicioAPP:

    mov	[utilitario], edi

	cmp byte[edi], 0
	je usoAplicativo

	mov edi, man.parametroAjuda
	mov esi, [utilitario]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

    mov edi, man.parametroAjuda2
	mov esi, [utilitario]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov esi, [utilitario]

    Hexagonix tamanhoString

	mov ebx, eax

	mov al, byte[man.extensaoManual+0]
	
	mov byte[esi+ebx+0], al
	
	mov al, byte[man.extensaoManual+1]
	
	mov byte[esi+ebx+1], al
	
	mov al, byte[man.extensaoManual+2]
	
	mov byte[esi+ebx+2], al
	
	mov al, byte[man.extensaoManual+3]
	
	mov byte[esi+ebx+3], al
	
	mov byte[esi+ebx+4], 0		;; Fim da string

    push esi

    Hexagonix arquivoExiste

    jc manualNaoEncontrado

    mov edi, bufferArquivo

    pop esi
	
	Hexagonix abrir
	
	jc manualNaoEncontrado

;; Preparação do ambiente

    Hexagonix limparTela

    call montarInterface
	
	mov esi, bufferArquivo
	
	imprimirString

    novaLinha

    jmp terminar

;;************************************************************************************

montarInterface:
    
    mov esi, man.man

    imprimirString

	mov ecx, 22

.loopEspaco:

	mov al, ' '
	
	Hexagonix imprimirCaractere
	
	dec ecx
	
	cmp ecx, 0
	je .terminado
	
	jmp .loopEspaco

.terminado:

    mov esi, [utilitario]

    imprimirString

    novaLinha
    novaLinha

    ret

;;************************************************************************************

manualNaoEncontrado:

    novaLinha
    novaLinha

    mov esi, [utilitario]

    imprimirString

    mov esi, man.naoEncontrado

    imprimirString

   jmp terminar

;;************************************************************************************

usoAplicativo:

	mov esi, man.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

terminar:	

	Hexagonix encerrarProcesso
	
;;*****************************************************************************

utilitario: dd ?

bufferArquivo:
