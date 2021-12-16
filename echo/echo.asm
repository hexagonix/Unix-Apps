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
	
	mov	[parametro], edi
	
    mov esi, [parametro]
		
	cmp byte[esi], 0
	je usoAplicativo
	
	mov edi, echo.parametroAjuda
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
	jc usoAplicativo

	mov edi, echo.parametroAjuda2
	mov esi, [parametro]
	
	Andromeda compararPalavrasString
	
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

	Andromeda encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************
	
echo:

match =PT, IDIOMA
{

include "idiomas/echo.pt.s"

}

match =EN, IDIOMA
{

include "idiomas/echo.en.s"

}
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--ajuda", 0
     
parametro: dd ?

regES:     dw 0
