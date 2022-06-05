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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 9, 04, inicioAPP, 01h

;;************************************************************************************

include "../../../LibAPP/hexagon.s"
include "../../../LibAPP/macros.s"
include "../../../LibAPP/log.s"

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoSYSLOGD equ "0.1" 

syslogd:

.uso:              db 10, 10, "Uso: syslogd [mensagem]", 10, 10
                   db "Envia uma mensagem de componentes do Hexagonix e de utilitarios para o log so sistema.", 10, 10
                   db "syslogd versao ", versaoSYSLOGD, 10, 10
                   db "Copyright (C) 2022 Felipe Miguel Nery Lunkes", 10
                   db "Todos os direitos reservados.", 10, 0
.parametroAjuda:   db "?", 0
.parametroAjuda2:  db "--ajuda", 0
.verboseIniciando: db "Iniciando syslogd versao ", versaoSYSLOGD, "...", 0

parametro: dd ? ;; Endereço do parâmetro

;;************************************************************************************

;; Syslogd é responsável por receber logs de utilitários, publicá-los no serviço de 
;; mensagens oferecido pelo Hexagon(R) e, futuramente, salvar esses logs em arquivos
;; de texto editáveis

inicioAPP:

	push ds
	pop es			
	
	mov	[parametro], edi
	
    logSistema syslogd.verboseIniciando, 0, Log.Prioridades.p4

    mov esi, [parametro]
		
	cmp byte[esi], 0
	je usoAplicativo
	
	mov edi, syslogd.parametroAjuda
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo

	mov edi, syslogd.parametroAjuda2
	mov esi, [parametro]
	
	Hexagonix compararPalavrasString
	
	jc usoAplicativo
	
    logSistema [parametro], 0, Log.Prioridades.p4

	jmp terminar

;;************************************************************************************

usoAplicativo:

	mov esi, syslogd.uso
	
	imprimirString
	
	jmp terminar

;;************************************************************************************

terminar:	

	Hexagonix encerrarProcesso

;;************************************************************************************

enviarMensagensHexagon:

;;************************************************************************************

processarMensagem:

;;************************************************************************************

adicionarArquivo:

;;************************************************************************************

