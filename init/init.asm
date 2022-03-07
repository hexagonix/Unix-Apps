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
;;                                                                                  
;;              Inicializador (Init) do Sistema Operacional Hexagonix®                 
;;                                                                   
;;                  Copyright © 2016-2022 Felipe Miguel Nery Lunkes                
;;                          Todos os direitos reservados.                    
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 8, 55, initAndromeda, 01h

;;************************************************************************************

include "../../../LibAPP/hexagon.s"
include "../../../LibAPP/Unix.s"
include "../../../LibAPP/macros.s"
include "../../../LibAPP/log.s"

;;************************************************************************************

tamanhoLimiteBusca = 32768

;;************************************************************************************			

initAndromeda: ;; Ponto de entrada do Inicializador do Sistema (Init) do Andromeda®

	Andromeda obterPID
	
	cmp eax, 01h
	je .configurarTerminal
	
	Andromeda encerrarProcesso
	
;; Configura o terminal do Andromeda®

.configurarTerminal:

;; Primeiramente, o Buffer de memória do Double Buffering deve ser limpo. Isto evita que memória 
;; poluída seja utilizada como base para a exibição, quando um aplicativo é fechado de forma forçada.
;; Nesta situação, o sistema descarrega o Buffer de memória, atualizando o vídeo com seu conteúdo.
	
	call limparTerminal
		
;; Aqui poderão ser adicionadas rotinas de configuração do Andromeda®

iniciarExecucao:

match =SIM, VERBOSE
{

	logSistema init.verboseInit, 0, Log.Prioridades.p5

}

	Andromeda travar ;; Impede que o usuário mate o processo de login com uma tecla especial
	
;; Agora o Inicializador do Sistema (Init) do Andromeda® irá verificar a existência de algum arquivo
;; de configuração de inicialização. Caso este arquivo esteja presente, o Inicializador do Sistema (Init)
;; do Andromeda® irá buscar a declaração de um Shell para ser utilizado com o Sistema, assim como declarações
;; de configuração do Andromeda®. Caso este arquivo não seja encontrado, o Inicializador do Sistema (Init) 
;; do Andromeda® irá carregar o Shell padrão.
  
match =SIM, VERBOSE
{

	logSistema init.verboseProcurarArquivo, 0, Log.Prioridades.p4

}

	call encontrarConfiguracaoInit          

.carregarServico:
	
	mov esi, servicoAndromeda
	
	Andromeda arquivoExiste
	
	jc .tentarShellPadrao

	mov eax, 0			           ;; Não passar argumentos
	mov esi, servicoAndromeda      ;; Nome do arquivo
	
	stc
	
	Andromeda iniciarProcesso      ;; Solicitar o carregamento do primeiro serviço
 
	jnc .servicoFinalizado

.naoEncontrado:                    ;; O serviço não pôde ser localizado
    
    cmp byte[tentarShellPadrao], 0 ;; Verifica se já se tentou carregar o Shell padrão do Andromeda®
    je .tentarShellPadrao          ;; Se não, tente carregar o Shell padrão do Andromeda®
    
	Andromeda encerrarProcesso     ;; Se sim, o Shell padrão também não pode ser executado  

.tentarShellPadrao:                ;; Tentar carregar o Shell padrão do Andromeda®

	call obterShellPadrao          ;; Solicitar a configuração do nome do Shell padrão do Andromeda®
	
	mov byte[tentarShellPadrao], 1 ;; Sinalizar a tentativa de carregamento do Shell padrão do Andromeda®
	
	Andromeda destravar            ;; O Shell pode ser terminado utilizando uma tecla especial
	
	jmp .carregarServico           ;; Tentar carregar o Shell padrão do Andromeda®
	
.servicoFinalizado:                ;; Tentar carregar o serviço novamente

	call limparTerminal
	
	jmp .carregarServico
	
;;************************************************************************************

limparTerminal:

	mov esi, vd1         ;; Abrir o dispositivo de saída secundário em memória (Buffer) 
	
	Andromeda abrir      ;; Abre o dispositivo
	
	;; Andromeda limparTela ;; Limpa seu conteúdo
	
	mov esi, vd0         ;; Reabre o dispositivo de saída padrão 
	
	Andromeda abrir      ;; Abre o dispositivo
	
	ret
	
;;************************************************************************************
 
encontrarConfiguracaoInit:

	pusha
	
	push es

	push ds
	pop es
	
	mov esi, arquivo
	mov edi, bufferArquivo
	
	Andromeda abrir
	
	jc .arquivoConfiguracaoAusente
	
	mov si, bufferArquivo           ;; Aponta para o buffer com o conteúdo do arquivo
	mov bx, 0FFFFh                  ;; Inicia na posição -1, para que se possa encontrar os delimitadores
	
.procurarEntreDelimitadores:

	inc bx
	
	cmp bx, tamanhoLimiteBusca
	
	je .arquivoConfiguracaoAusente  ;; Caso nada seja encontrado até o tamanho limite, cancele a busca
	
	mov al, [ds:si+bx]
	
	cmp al, '['
	jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
	
;; BX agora aponta para o primeira caractere do nome do Shell resgatado do arquivo
	
	push ds
	pop es
	
	mov di, servicoAndromeda        ;; O nome do Shell será copiado para ES:DI - servicoAndromeda
	
	mov si, bufferArquivo
	
	add si, bx				        ;; Mover SI para aonde BX aponta
	
	mov bx, 0				        ;; Iniciar em 0
	
.obterNomeShell:

	inc bx
	
	cmp bx, 13				
	je .nomeShellInvalido           ;; Se nome de arquivo maior que 11, o nome é inválido     
	
	mov al, [ds:si+bx]
	
	cmp al, ']'					    ;; Se encontrar outro delimitador, o nome foi carregado com sucesso
	je .nomeShellObtido
	
;; Se não estiver pronto, armazenar o caractere obtido

	stosb
	
	jmp .obterNomeShell

.nomeShellObtido:

	pop es
	
	popa

match =SIM, VERBOSE
{

	logSistema init.verboseArquivoEncontrado, 0, Log.Prioridades.p4

}

	ret
	
.nomeShellInvalido:

	pop es
	
	popa
	
	jmp obterShellPadrao

	
.arquivoConfiguracaoAusente:

	pop es
	
	popa
	
match =SIM, VERBOSE
{

	logSistema init.verboseArquivoAusente, 0, Log.Prioridades.p4

}

	jmp obterShellPadrao

;;************************************************************************************
	
obterShellPadrao:

	push es
	
	push ds
	pop es
	
	mov esi, servicoAndromeda
	
	Andromeda tamanhoString
	
	push eax
	
	mov edi, servicoAndromeda
	mov esi, ' '
	
	pop ecx
	
	rep movsb
	
	pop es
	
	push es
	
	push ds
	pop es
	
	mov esi, shellPadrao
	
	Andromeda tamanhoString
	
	push eax
	
	mov edi, servicoAndromeda
	mov esi, shellPadrao
	
	pop ecx
	
	rep movsb
	
	pop es
	
	ret						
		
;;************************************************************************************

shellPadrao: db "sh.app", 0     ;; Nome do arquivo que contêm o Shell padrão Unix
vd0: db "vd0", 0                ;; Dispositivo de saída padrão do Sistema
vd1: db "vd1", 0	            ;; Dispositivo de saída secundário em memória (Buffer)
arquivo: db "init.unx", 0       ;; Nome do arquivo de configuração do Inicializador do Sistema (Init) do Andromeda®
tentarShellPadrao: db 0         ;; Sinaliza a tentativa de se carregar o Shell padrão
servicoAndromeda: times 11 db 0 ;; Armazena o nome do Shell à ser utilizado pelo Sistema

match =SIM, VERBOSE
{

init:

.verboseInit:              db "init versao ", versaoINIT, ".", 0
.verboseProcurarArquivo:   db "Procurando arquivo de configuracao em /...", 0
.verboseArquivoEncontrado: db "Arquivo de configuracao encontrado.", 0
.verboseArquivoAusente:    db "Arquivo de configuracao nao encontrado. O shell padrao sera executado (sh.app)", 0
.verboseErro:              db "Um erro nao manipulavel foi encontrado.", 0

}

;;************************************************************************************                
                
bufferArquivo:                  ;; Local onde o arquivo de configuração será aberto
