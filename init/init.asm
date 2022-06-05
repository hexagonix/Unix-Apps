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
;;              Utilitário Unix init para Sistema Operacional Hexagonix®                 
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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 9, 03, initHexagonix, 01h

;;************************************************************************************

include "../../../LibAPP/hexagon.s"
include "../../../LibAPP/macros.s"
include "../../../LibAPP/log.s"

;;************************************************************************************

tamanhoLimiteBusca = 32768

;;************************************************************************************

versaoINIT equ "1.4.1"

shellPadrao: db "sh.app", 0     ;; Nome do arquivo que contêm o shell padrão Unix
vd0: db "vd0", 0                ;; Dispositivo de saída padrão do sistema
vd1: db "vd1", 0	            ;; Dispositivo de saída secundário em memória (buffer)
arquivo: db "init.unx", 0       ;; Nome do arquivo de configuração do init
tentarShellPadrao: db 0         ;; Sinaliza a tentativa de se carregar o shell padrão
servicoHexagonix: times 11 db 0 ;; Armazena o nome do shell à ser utilizado pelo sistema

match =SIM, VERBOSE
{

init:

.verboseInit:                   db "init versao ", versaoINIT, ".", 0
.verboseProcurarArquivo:        db "Procurando arquivo de configuracao no volume...", 0
.verboseArquivoEncontrado:      db "Arquivo de configuracao encontrado.", 0
.verboseArquivoAusente:         db "Arquivo de configuracao nao encontrado. O shell padrao sera executado (sh.app)", 0
.verboseErro:                   db "Um erro nao manipulavel foi encontrado.", 0
.verboseRegistrandoComponentes: db "Registrando componentes do sistema...", 0

} 

;;************************************************************************************			

;; Aqui temos o ponto de entrada do init 

initHexagonix: ;; Ponto de entrada do init

;; Primeiramente, devemos checar qual o PID do processo. Por padrão, init só deve ser executado 
;; diretamente pelo Hexagon. Fora isso, ele não deve desempenhar sua função. Caso o PID seja 
;; diferente de 1, o init deve ser finalizado. Caso seja 1, prosseguir com o processo de 
;; inicialização do ambiente de usuário do Hexagonix

	Hexagonix obterPID
	
	cmp eax, 01h
	je .configurarTerminal ;; O PID é 1? Prosseguir
	
	Hexagonix encerrarProcesso ;; Não é? Finalizar agora
	
;; Configura o terminal do Hexagonix

.configurarTerminal:

;; Agora, o buffer de memória do double buffering deve ser limpo. Isto evita que memória 
;; poluída seja utilizada como base para a exibição, quando um aplicativo é fechado de forma forçada.
;; Nesta situação, o sistema descarrega o buffer de memória, atualizando o vídeo com seu conteúdo.
;; Essa etapa também pode ser realizada pelo gerenciador de sessão, posteriormente.
	
	call limparTerminal
		
;; Aqui poderão ser adicionadas rotinas de configuração do Hexagonix

iniciarExecucao:

match =SIM, VERBOSE
{

	logSistema init.verboseInit, 0, Log.Prioridades.p5

}

	Hexagonix travar ;; Impede que o usuário mate o processo de login com uma tecla especial
	
;; Agora o init irá verificar a existência do arquivo de configuração de inicialização.
;; Caso este arquivo esteja presente, o init irá buscar a declaração de uma imagem para ser utilizada
;; com o sistema, assim como declarações de configuração do Hexagonix. Caso este arquivo não seja
;; encontrado, o init irá carregar o shell padrão. O padrão é o utilitário de login do Hexagonix.
  
match =SIM, VERBOSE
{

	logSistema init.verboseProcurarArquivo, 0, Log.Prioridades.p4

}

	call encontrarConfiguracaoInit          

.carregarServico:

match =SIM, VERBOSE
{

	logSistema init.verboseRegistrandoComponentes, 0, Log.Prioridades.p5

}

	mov esi, servicoHexagonix
	
	Hexagonix arquivoExiste
	
	jc .tentarShellPadrao

	mov eax, 0			           ;; Não passar argumentos
	mov esi, servicoHexagonix      ;; Nome do arquivo
	
	stc
	
	Hexagonix iniciarProcesso      ;; Solicitar o carregamento do primeiro serviço
 
	jnc .servicoFinalizado

.naoEncontrado:                    ;; O serviço não pôde ser localizado
    
    cmp byte[tentarShellPadrao], 0 ;; Verifica se já se tentou carregar o shell padrão do Hexagonix
    je .tentarShellPadrao          ;; Se não, tente carregar o shell padrão do Hexagonix
    
	Hexagonix encerrarProcesso     ;; Se sim, o shell padrão também não pode ser executado  

.tentarShellPadrao:                ;; Tentar carregar o shell padrão do Hexagonix

	call obterShellPadrao          ;; Solicitar a configuração do nome do shell padrão do Hexagonix
	
	mov byte[tentarShellPadrao], 1 ;; Sinalizar a tentativa de carregamento do shell padrão do Hexagonix
	
	Hexagonix destravar            ;; O shell pode ser terminado utilizando uma tecla especial
	
	jmp .carregarServico           ;; Tentar carregar o shell padrão do Hexagonix
	
.servicoFinalizado:                ;; Tentar carregar o serviço novamente

	call limparTerminal
	
	jmp .carregarServico
	
;;************************************************************************************

limparTerminal:

	mov esi, vd1         ;; Abrir o dispositivo de saída secundário em memória (buffer) 
	
	Hexagonix abrir      ;; Abre o dispositivo
	
	;; Hexagonix limparTela ;; Limpa seu conteúdo
	
	mov esi, vd0         ;; Reabre o dispositivo de saída padrão 
	
	Hexagonix abrir      ;; Abre o dispositivo
	
	ret
	
;;************************************************************************************
 
encontrarConfiguracaoInit:

	pusha
	
	push es

	push ds
	pop es
	
	mov esi, arquivo
	mov edi, bufferArquivo
	
	Hexagonix abrir
	
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
	
;; BX agora aponta para o primeira caractere do nome do shell resgatado do arquivo
	
	push ds
	pop es
	
	mov di, servicoHexagonix        ;; O nome do shell será copiado para ES:DI - servicoHexagonix
	
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
	
	mov esi, servicoHexagonix
	
	Hexagonix tamanhoString
	
	push eax
	
	mov edi, servicoHexagonix
	mov esi, ' '
	
	pop ecx
	
	rep movsb
	
	pop es
	
	push es
	
	push ds
	pop es
	
	mov esi, shellPadrao
	
	Hexagonix tamanhoString
	
	push eax
	
	mov edi, servicoHexagonix
	mov esi, shellPadrao
	
	pop ecx
	
	rep movsb
	
	pop es
	
	ret						
		
;;************************************************************************************               
                
bufferArquivo:                  ;; Local onde o arquivo de configuração será aberto
