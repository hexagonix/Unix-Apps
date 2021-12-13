;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Andromeda®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
;;        @#@%!$&%$&$#@#             Todos os direitos reservados
;;        !@$%#%&#&@&$%#
;;        @$#!%&@&@#&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 40, inicioAPP, 01h

;;************************************************************************************


include "../../../LibAPP/andrmda.s"
include "../../../LibAPP/erros.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************

inicioAPP:
	
	push ds
	pop es			
	
	mov	[parametros], edi
	
	mov esi, edi
	
	cmp byte[esi], 0
	je exibirMontagens
	
	call obterParametros
	
	jc	usoAplicativo
	
	mov edi, mount.parametroAjuda
	mov esi, [parametros]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, mount.dispositivoPadrao
	mov esi, [pontoMontagem]

	Andromeda compararPalavrasString
	
	jc .realizarMontagem
	
	jmp erroPontoMontagem	
	
.realizarMontagem:
	
	mov esi, mount.volume
	
	imprimirString
	
	mov esi, [volume]
	
	imprimirString
	
	mov esi, mount.pontoMontagem
	
	imprimirString
	
	mov esi, [pontoMontagem]
	
	imprimirString
	
	mov esi, mount.fecharColchete
	
	imprimirString

	mov esi, [volume]
	
	Andromeda abrir
	
	jc erroAbertura
	
	mov esi, mount.montado
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

exibirMontagens:

    mov esi, mount.volumeMontado
  
    imprimirString  
	
	Andromeda obterDisco
	
	push eax
	push edi
	push esi
	
	pop esi
	
	imprimirString
	
	mov esi, mount.infoVolume
	
	imprimirString
	
	mov esi, mount.dispositivoPadrao
	
	imprimirString
	
	mov esi, mount.rotuloVolume
	
	imprimirString
	
	pop edi
	
	mov esi, edi
	
	Andromeda cortarString
	
	imprimirString
	
	mov esi, mount.parenteses1

	imprimirString

	pop eax

	cmp ah, 01h
	je .fat12

	cmp ah, 04h
	je .fat16_32

	cmp ah, 06h
	je .fat16

	jmp terminar

.fat12:

	mov esi, mount.FAT12

	imprimirString

	mov esi, mount.parenteses2

	imprimirString

	jmp terminar

.fat16_32:

	mov esi, mount.FAT16_32

	imprimirString

	mov esi, mount.parenteses2

	imprimirString

	jmp terminar

.fat16:

	mov esi, mount.FAT16

	imprimirString

	mov esi, mount.parenteses2

	imprimirString

	jmp terminar

;;************************************************************************************

erroPontoMontagem:

	mov esi, mount.erroPontoMontagem
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

erroAbertura:

	cmp eax, IO.operacaoNegada
	je .operacaoNegada

	mov esi, mount.erroAbrindo
	
	imprimirString

	jmp terminar

.operacaoNegada:

	mov esi, mount.operacaoNegada

	imprimirString

	jmp terminar

;;************************************************************************************

terminar:	

	Andromeda encerrarProcesso

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

	mov esi, [parametros]
	mov [volume], esi
		
	cmp byte[esi], 0
	je usoAplicativo
	
	mov al, ' '
	
	Andromeda encontrarCaractere
	
	jc usoAplicativo

	mov al, ' '
	
	call encontrarCaractereCP
	
	mov [pontoMontagem], esi
	
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

	mov esi, mount.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************	

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
mount:

.volume:            db 10, 10, "Montando [", 0
.fecharColchete:    db "]...", 10, 10, 0
.pontoMontagem:     db "] em [", 0
.montado:           db "Sucesso na montagem.", 10, 0
.uso:               db 10, 10, "Uso: mount [volume] [ponto de montagem]", 10, 10
                    db "Realiza a montagem de um volume em um ponto de montagem do sistema de arquivos.", 10, 10
                    db "Caso nenhum parametro seja fornecido, quaisquer montagens realizadas serao exibidas.", 10, 10
                    db "mount versao ", versaoMOUNT, 10, 10
                    db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                    db "Todos os direitos reservados.", 10, 0
.erroAbrindo:       db "Erro ao montar o volume no ponto de montagem especificado.", 10
                    db "Tente informar um nome valido ou referencia de um volume conectado.", 10, 0
.parametroAjuda:    db "?", 0
.dispositivoPadrao: db "/", 0
.erroPontoMontagem: db 10, 10, "Infome um ponto de montagem valido para este volume e sistema de arquivos.", 10, 0
.volumeMontado:     db 10, 10, "Volume ", 0
.infoVolume:        db " montado em ", 0
.rotuloVolume:      db " com o rotulo ", 0
.operacaoNegada:    db "A montagem foi recusada pelo Sistema. Isso pode ser explicado devido ao fato do usuario atual", 10
                    db "nao possuir previlegios administrativos, nao sendo usuario raiz (root).", 10, 10
					db "Apenas o usuario raiz (root) pode realizar montagens. Realize login neste usuario para realizar", 10
					db "a montagem desejada.", 10, 0
.parenteses1:       db " (", 0
.parenteses2:       db ")", 10, 0
.FAT16:             db "FAT16B", 0
.FAT12:             db "FAT12", 0
.FAT16_32:          db "FAT16 <32 MB", 0
              
parametros:    dd 0     
volume:        dd ?
pontoMontagem: dd ?

regES:	dw 0
     
