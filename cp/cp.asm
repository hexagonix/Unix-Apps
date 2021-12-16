;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
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

;;************************************************************************************

inicioAPP:
	
	push ds
	pop es			
	
	mov	[parametros], edi
	
	call obterParametros
	
	jc	usoAplicativo
	
	push esi
	push edi
	
	mov edi, cp.parametroAjuda
	mov esi, [parametros]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, cp.parametroAjuda2
	mov esi, [parametros]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo
	
	pop edi
	pop esi
	
	mov esi, [arquivoEntrada]
	
	Andromeda arquivoExiste
	
	jc fonteNaoEncontrado
	
	mov esi, [arquivoSaida]
	
	Andromeda arquivoExiste
	
	jnc destinoPresente

;; Agora vamos abrir o arquivo fonte para cópia
	
	mov esi, [arquivoEntrada]
	mov edi, bufferArquivo
	
	Andromeda abrir
	
	jc erroAoAbrir
	
	mov esi, bufferArquivo
	
	Andromeda tamanhoString
	
;; Salvar arquivo no disco

	mov esi, [arquivoSaida]
	mov edi, bufferArquivo
	
	Andromeda salvarArquivo
	
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

	Andromeda encerrarProcesso

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

	mov esi, [parametros]
	mov [arquivoEntrada], esi
		
	cmp byte[esi], 0
	je usoAplicativo
	
	mov al, ' '
	
	Andromeda encontrarCaractere
	
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
	
cp:
	
match =PT, IDIOMA
{

include "idiomas/cp.pt.s"

}

match =EN, IDIOMA
{

include "idiomas/cp.en.s"

}
               
parametros dd 0     

arquivoEntrada: dd ?
arquivoSaida:   dd ?

regES:	dw 0
     
bufferArquivo:
