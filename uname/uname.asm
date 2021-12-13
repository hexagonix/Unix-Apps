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
include "../../../LibAPP/Unix.s"
include "../../../LibAPP/sistema.s"
include "../../../LibAPP/verUtils.s"
	

;;************************************************************************************			

inicioAPP: ;; Ponto de entrada do aplicativo

    mov	[parametro], edi
	
	mov edi, uname.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, uname.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	mov edi, uname.parametroExibirTudo
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc exibirTudo
	
	mov edi, uname.parametroExibirVersao
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc exibirVersaoApenas
	
	mov edi, uname.parametroExibirAndromeda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc exibirInfoAndromeda
	
	jmp exibirVersaoApenas

;;************************************************************************************

exibirTudo:

	novaLinha
	novaLinha
	
	Andromeda retornarVersao
	
	imprimirString
	
	mov esi, uname.maquina
	
	imprimirString

	mov esi, uname.espaco
	
	imprimirString
	
	Andromeda retornarVersao
	
	imprimirString
	
	mov esi, uname.versao
	
	imprimirString
	
	call versaoHexagon
	
	cmp edx, 01h 
	je .i386

	cmp edx, 02h
	je .amd64

.i386:

	mov esi, uname.arquiteturai386

	imprimirString

	jmp .continuar

.amd64:

	mov esi, uname.arquiteturaamd64

	imprimirString

	jmp .continuar

.continuar:
	
	mov esi, uname.hexagonix
	
	imprimirString
	
	novaLinha
	
	jmp terminar

;;************************************************************************************

exibirInfoAndromeda:

	novaLinha
	novaLinha
	
	mov esi, uname.sistemaOperacional
	
	imprimirString
	
	mov esi, uname.versao
	
	imprimirString
	
	call versaoAndromeda
	
	novaLinha
	
	jmp terminar
	
;;************************************************************************************

exibirVersaoApenas:

	novaLinha
	novaLinha
	
	Andromeda retornarVersao
	
	imprimirString
	
	novaLinha
	
	jmp terminar

;;************************************************************************************
	
;; Solicita a versão do Kernel, a decodifica e exibe para o usuário
 	
versaoHexagon:

	Andromeda retornarVersao
	
	push ecx
	push ebx
	
	imprimirInteiro
	
	mov esi, ponto
	
	imprimirString
	
	pop eax
	
	imprimirInteiro
	
	pop ecx
	
	mov al, ch
	
	Andromeda imprimirCaractere
	
	ret

;;************************************************************************************

versaoAndromeda:

	call obterVersaoDistribuicao

	jc .erro 

	mov esi, versaoObtida
	
	imprimirString

	mov al, ' '

	Andromeda imprimirCaractere

	mov esi, uname.colcheteEsquerdo

	imprimirString

	mov esi, codigoObtido

	imprimirString

	mov esi, uname.colcheteDireito

	imprimirString

.continuar:

	ret

.erro:

	mov esi, sistemaBase.versaoAndromeda

	imprimirString

	jmp .continuar

;;************************************************************************************

usoAplicativo:

	mov esi, uname.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************	

terminar:	

	Andromeda encerrarProcesso
	
;;*****************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
ponto: db ".", 0

parametro: dd ?

uname:

.uso:                      db 10, 10, "Uso: uname [parametro]", 10, 10
                           db "Exibe informacoes do Sistema.", 10, 10 
                           db "Parametros possiveis (em caso de falta de parametros, a opcao '-v' sera selecionada):", 10, 10
                           db "-t - Exibe todas as informacoes possiveis do Sistema, do Kernel e da maquina.", 10
                           db "-a - Exibe a versao do sistema operacional.", 10    
                           db "-v - Exibe apenas o nome do Sistema.", 10, 10                                    
                           db "uname versao ", versaoUNAME, 10, 10
                           db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                           db "Todos os direitos reservados.", 10, 0
.parametrosSistema:        db " Unix" , 0 
.sistemaOperacional:       db "Sistema Operacional Andromeda(R)", 0
.usuario:                  db " ", 0
.espaco:                   db " ", 0
.maquina:                  db " Hexagonix-PC", 0
.colcheteEsquerdo:         db "[", 0
.colcheteDireito:          db "]", 0
.pontoVirgula:             db "; ", 0
.nucleo:                   db " Kernel ", 0
.versao:                   db " versao ", 0 
.arquiteturai386:          db " i386", 0
.arquiteturaamd64:         db " amd64", 0
.hexagonix:                db " Hexagonix(R)", 0
.parametroAjuda:           db "?", 0  
.parametroAjuda2:          db "--ajuda", 0
.parametroExibirTudo:      db "-t", 0
.parametroExibirVersao:    db "-v", 0   
.parametroExibirAndromeda: db "-a", 0           

nomeProcessador: db 0

nomeUsuario: times 32 db 0

enderecoCarregamento: