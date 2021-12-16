;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2016-2022 Felipe Miguel Nery Lunkes
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 40, inicioShell, 01h

;;************************************************************************************

include "../../../LibAPP/andrmda.s"
include "../../../LibAPP/erros.s"
include "../../../LibAPP/Unix.s"

;;************************************************************************************

inicioShell:	

    mov	[linhaComando], edi
	
	mov edi, sh.parametroAjuda
	mov esi, [linhaComando]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	mov edi, sh.parametroAjuda2
	mov esi, [linhaComando]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
		
	mov esi, [linhaComando]
	    	
	cmp byte[esi], 0
	je .iniciar

.iniciar:

;; Iniciar a configuração do terminal
	
	novaLinha
	
	Andromeda obterInfoTela

	mov byte[maxColunas], bl
	mov byte[maxLinhas], bh

	Andromeda obterCursor
	
	dec dh
	
	Andromeda definirCursor
	
	novaLinha
	
.iniciarSessao:

	Andromeda obterUsuario
	
	push eax
	
	push es
	
	push ds
	pop es
	
	push esi
	
	Andromeda tamanhoString
	
	pop esi
	
	push eax
	
	mov edi, sh.nomeUsuario
	
	pop ecx
	
	rep movsb
	
	pop es	
	
	pop eax
	
	cmp eax, 555
	je .usuarioNormal
	
	cmp eax, 777
	je .usuarioRoot
	
.usuarioNormal:

	push es
	
	push ds
	pop es
	
	mov esi, sh.usuarioNormal
	
	Andromeda tamanhoString
	
	push eax
	
	mov edi, sh.separador
	mov esi, sh.usuarioNormal
	
	pop ecx
	
	rep movsb
	
	pop es	
	
	jmp .finalizarPrompt

.usuarioRoot:

	push es
	
	push ds
	pop es
	
	mov esi, sh.usuarioRoot
	
	Andromeda tamanhoString
	
	push eax
	
	mov edi, sh.separador
	mov esi, sh.usuarioRoot
	
	pop ecx
	
	rep movsb
	
	pop es	
	
	jmp .finalizarPrompt

;;************************************************************************************

.finalizarPrompt:

	mov esi, sh.separador
	
	Andromeda tamanhoString
	
	inc eax
	
	mov byte[sh.separador+eax], 0
	
;;************************************************************************************

.obterComando:	

	novaLinha
   
	Andromeda obterCursor
	
	Andromeda definirCursor
	
	mov esi, sh.nomeUsuario
	
	imprimirString
	
	mov esi, sh.prompt
	
	imprimirString
	
	mov esi, sh.separador
	
	imprimirString
	
	mov al, byte[maxColunas]		 ;; Máximo de caracteres para obter

	sub al, 20
	
	Andromeda obterString
	
	Andromeda cortarString			 ;; Remover espaços em branco extras
		
	cmp byte[esi], 0		         ;; Nenhum comando inserido
	je .obterComando
	
;; Comparar com comandos internos disponíveis

	;; Comando SAIR
	
	mov edi, comandos.sair		
	
	Andromeda compararPalavrasString

	jc finalizarShell

;;************************************************************************************

;; Tentar carregar um programa
	
	call obterArgumentos		      ;; Separar comando e argumentos
	
	push esi
	push edi
	
	Andromeda tamanhoString
	
	add esi, eax

	sub esi, 4
	
	mov edi, sh.extensaoProgramas
	
	Andromeda compararPalavrasString  ;; Checar por extensão .APP
	
	jc .carregarPrograma
	
	pop edi
	pop esi
	
.semExtensao:
		
;; Tentar adicionar extensão

	Andromeda tamanhoString
	
	mov ebx, eax

	mov al, byte[sh.extensaoProgramas+0]
	
	mov byte[esi+ebx+0], al
	
	mov al, byte[sh.extensaoProgramas+1]
	
	mov byte[esi+ebx+1], al
	
	mov al, byte[sh.extensaoProgramas+2]
	
	mov byte[esi+ebx+2], al
	
	mov al, byte[sh.extensaoProgramas+3]
	
	mov byte[esi+ebx+3], al
	
	mov byte[esi+ebx+4], 0		;; Fim da string
	
	push esi
	push edi
	
	jmp .carregarPrograma
	
.falhaExecutando:

;; Agora o erro enviado pelo Sistema será analisado, para que o Shell conheça
;; sua natureza

	cmp eax, Hexagon.limiteProcessos ;; Limite de processos em execução atingido
	je .limiteAtingido               ;; Se sim, exibir a mensagem apropriada
	
	cmp eax, Hexagon.imagemInvalida
	je .imagemHAPPInvalida

	Andromeda obterCursor
	
	mov dl, byte[maxColunas]    ;; Máximo de caracteres para obter

	sub dl, 17
	
	Andromeda definirCursor
	
	push esi
	
	novaLinha
	novaLinha
	
	pop esi
	
	imprimirString
	
	mov esi, sh.comandoNaoEncontrado
	
	imprimirString
	
	jmp .obterComando	
	
.limiteAtingido:

	Andromeda obterCursor
	
	mov dl, byte[maxColunas]    ;; Máximo de caracteres para obter

	sub dl, 17
	
	Andromeda definirCursor
	
	mov esi, sh.limiteProcessos
	
	imprimirString
	
	jmp .obterComando	

.imagemHAPPInvalida:

	push esi

	Andromeda obterCursor
	
	mov dl, byte[maxColunas]    ;; Máximo de caracteres para obter

	sub dl, 17
	
	Andromeda definirCursor
	
	novaLinha
	novaLinha
	
	pop esi
	
	imprimirString

	mov esi, sh.imagemInvalida
	
	imprimirString
	
	jmp .obterComando	

.carregarPrograma:
	
	pop edi

	mov esi, edi
	
	Andromeda cortarString
	
	pop esi
	
	mov eax, edi
	
	stc
	
	Andromeda iniciarProcesso
	
	jc .falhaExecutando
	
	jmp .obterComando

;;************************************************************************************

;;************************************************************************************
;;
;; Fim dos comandos internos do Shell Unix do Andromeda®
;;
;; Funções úteis para o manipulação de dados no Shell Unix do Andromeda® 
;;
;;************************************************************************************

;; Separar nome de comando e argumentos
;;
;; Entrada:
;;
;; ESI - Endereço do comando
;; 
;; Saída:
;;
;; ESI - Endereço do comando
;; EDI - Argumentos do comando
;; CF  - Definido em caso de falta de extensão

obterArgumentos:

	push esi
	
.loop:

	lodsb			;; mov AL, byte[ESI] & inc ESI
	
	cmp al, 0
	je .naoencontrado
	
	cmp al, ' '
	je .espacoEncontrado
	
	jmp .loop
	
.naoencontrado:

	pop esi
	
	mov edi, 0
	
	stc
	
	jmp .fim

.espacoEncontrado:

	mov byte[esi-1], 0
	mov ebx, esi
	
	Andromeda tamanhoString
	
	mov ecx, eax
	
	inc ecx			;; Incluindo o último caractere (NULL)
	
	push es
	
	push ds
	pop es
	
	mov esi, ebx
	mov edi, bufferArquivo
	
	rep movsb		;; Copiar (ECX) caracteres da string de ESI para EDI
	
	pop es
	
	mov edi, bufferArquivo
	
	pop esi
	
	clc
	
.fim:

	ret
	
;;************************************************************************************

usoAplicativo:

	mov esi, sh.uso
	
	imprimirString
	
	jmp finalizarShell	

;;************************************************************************************

finalizarShell:
	
	mov ebx, 00h
	
	Andromeda encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;; Dados, variáveis e constantes utilizadas pelo Shell
;;
;;************************************************************************************

;; A versão do sh é independente da versão do restante do Sistema.
;; Ela deve ser utilizada para identificar para qual versão do Andromeda® o sh foi
;; desenvolvido.
                    
;;**************************

sh:

.prompt:               db "@Andromeda", 0
.extensaoProgramas:    db ".app", 0	;; Extensão de aplicativos (executáveis Hexagon®)
.comandoNaoEncontrado: db ": comando nao encontrado.", 10, 0
.imagemInvalida:       db ": nao e possivel carregar a imagem. Formato executavel nao suportado.", 10, 0
.limiteProcessos:      db 10, 10, "Nao existe memoria disponivel para executar o aplicativo solicitado.", 10
                       db "Tente primeiramente finalizar aplicativos ou suas instancias, e tente novamente.", 10, 0		             
.ponto:                db ".", 0
.usuarioNormal:        db "$ ", 0
.usuarioRoot:          db "# ", 0
.uso:                  db 10, 10, "Uso: sh", 10, 10
                       db "Inicia um Shell Unix para o usuario atual.", 10, 10               
                       db "sh versao ", versaoSH, 10, 10
                       db "Copyright (C) 2017-2022 Felipe Miguel Nery Lunkes", 10
                       db "Todos os direitos reservados.", 10, 0
.parametroAjuda:       db "?", 0   
.parametroAjuda2:      db "--ajuda", 0
.nomeUsuario:          times 64 db 0
.separador:            times 8 db 0
 
;;**************************

comandos:

.sair: db "sair",0

maxColunas:   db 0 ;; Total de colunas disponíveis no vídeo na resolução atual
maxLinhas:    db 0 ;; Total de linhas disponíveis no vídeo na resolução atual

linhaComando: dd 0
		           
;;************************************************************************************

bufferArquivo:  ;; Endereço para carregamento de arquivos
