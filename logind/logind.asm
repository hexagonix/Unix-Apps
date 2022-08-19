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
;;                Daemon de login para Sistema Operacional Hexagonix®                 
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

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, iniciologind, 01h

;;************************************************************************************
                    
include "hexagon.s"
include "Estelar/estelar.s"
include "macros.s"
include "log.s"
include "verUtils.s"

tamanhoLimiteBusca = 32768

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

;;************************************************************************************

versaoLOGIND equ "1.2"

arquivo:    db "usuario.unx", 0 ;; Nome do arquivo de gerenciamento de login
vd0:        db "vd0", 0         ;; Console padrão
vd1:        db "vd1", 0         ;; Primeiro console virtual
posicaoBX:  dw 0                ;; Marcação da posição de busca no conteúdo do arquivo

align 32

logind:

match =UNIX, TIPOLOGIN
{

.sobreSistema:     db 10, "Seja bem-vindo ao Hexagonix (vd0)", 0

}

match =Andromeda, TIPOLOGIN
{

.sobreSistema:     db 10, 10   
                   db "        %#@$%&@$%&@$%$ tm          Sistema Operacional Andromeda(R)", 10
                   db "        #$@$@$@#@#@#@$", 10
                   db "        @#@$&    %#$#%", 10
                   db "        @#$@$    #@#$@", 10
                   db "        #@#$$    !@#@#     Copyright (C) 2016-", __stringano, " Felipe Miguel Nery Lunkes",10
                   db "        @#@%!$&%$&$#@#              Todos os direitos reservados",10
                   db "        !@$%#%&#&@&$%#", 10
                   db "        @$#!%&@&@#&*@&", 10
                   db "        $#$#%    &%$#@", 10
                   db "        @#!$$    !#@#@", 10, 10, 0

.versaoSistema:    db "Sistema Operacional Andromeda versao ", 0

} 

.semArquivoUnix:   db 10, 10, "O arquivo de configuracao do ambiente Unix de controle de contas nao foi encontrado.", 10, 0        
.colcheteEsquerdo: db " [", 0
.colcheteDireito:  db "]", 0
.temaClaro:        db "claro", 0
.temaEscuro:       db "escuro", 0
.semVersao:        db "[desconhecida]", 0
.verboseLogind:    db "logind versao ", versaoLOGIND, ".", 0

align 4

escolhaTema:       times 7  db 0

;;************************************************************************************          

iniciologind: ;; Ponto de entrada

;; O logind é um daemon que só deve ser utilizado durante a inicialização.
;; Para isso, ele deve checar se o PID é 3 (init=1 e login=2).

    Hexagonix obterPID
    
    cmp eax, 03h
    je iniciarExecucao
    
    Hexagonix encerrarProcesso

iniciarExecucao:

    logSistema logind.verboseLogind, 0, Log.Prioridades.p4

    call checarBaseDados
    
match =Andromeda, TIPOLOGIN
{
     
    call verificarTema

    Hexagonix limparTela

} 

    call exibirLogoSistema

    jmp terminar

;;************************************************************************************
    
verificarTema:

    pusha
    
    push es

    push ds
    pop es
    
    mov esi, arquivo
    mov edi, bufferArquivo
    
    Hexagonix abrir
    
    jc .arquivoUsuarioAusente
    
    mov si, bufferArquivo           ;; Aponta para o buffer com o conteúdo do arquivo
    mov bx, 0FFFFh                  ;; Inicia na posição -1, para que se possa encontrar os delimitadores
    
.procurarEntreDelimitadores:

    inc bx
    
    mov word[posicaoBX], bx
    
    cmp bx, tamanhoLimiteBusca
    je .nomeTemaInvalido         ;; Caso nada seja encontrado até o tamanho limite, cancele a busca
    
    mov al, [ds:si+bx]
    
    cmp al, '<'
    jne .procurarEntreDelimitadores ;; O limitador inicial foi encontrado
    
;; BX agora aponta para o primeiro caractere do nome de usuário resgatado do arquivo
    
    push ds
    pop es
    
    mov di, escolhaTema             ;; O tema será copiado para ES:DI
    
    mov si, bufferArquivo
    
    add si, bx                      ;; Mover SI para aonde BX aponta
    
    mov bx, 0                       ;; Iniciar em 0
    
.obterTema:

    inc bx
    
    cmp bx, 7               
    je .nomeTemaInvalido            ;; Se nome de usuário maior que 15, o mesmo é inválido     
    
    mov al, [ds:si+bx]
    
    cmp al, '>'                     ;; Se encontrar outro delimitador, o nome de usuário foi carregado com sucesso
    je .temaObtido
    
;; Se não estiver pronto, armazenar o caractere obtido

    stosb
    
    jmp .obterTema

.temaObtido:

    mov edi, escolhaTema
    mov esi, logind.temaClaro
    
    Hexagonix compararPalavrasString
    
    jc .selecionarTemaClaro
    
    mov edi, escolhaTema
    mov esi, logind.temaEscuro
    
    Hexagonix compararPalavrasString
    
    jc .selecionarTemaEscuro
    
    mov word bx, [posicaoBX]
    
    mov si, bufferArquivo
    
    jmp .procurarEntreDelimitadores
    
.selecionarTemaClaro:
    
    pop es
    
    popa

    mov esi, vd1         ;; Abrir primeiro console virtual 
    
    Hexagonix abrir      ;; Abre o dispositivo
    
    mov eax, PRETO 
    mov ebx, BRANCO_ANDROMEDA

    Hexagonix definirCor

    Hexagonix limparTela ;; Limpa seu conteúdo
    
    mov esi, vd0         ;; Reabre o dispositivo de saída padrão 
    
    Hexagonix abrir      ;; Abre o dispositivo

    mov eax, PRETO 
    mov ebx, BRANCO_ANDROMEDA

    Hexagonix definirCor

    Hexagonix limparTela ;; Limpa seu conteúdo

    ret

.selecionarTemaEscuro:

    mov esi, vd1         ;; Abrir primeiro console virtual 
    
    Hexagonix abrir      ;; Abre o dispositivo
    
    mov eax, BRANCO_ANDROMEDA 
    mov ebx, PRETO

    Hexagonix definirCor

    Hexagonix limparTela ;; Limpa seu conteúdo
    
    mov esi, vd0         ;; Reabre o console padrão
    
    Hexagonix abrir      ;; Abre o dispositivo

    mov eax, BRANCO_ANDROMEDA 
    mov ebx, PRETO

    Hexagonix definirCor

    Hexagonix limparTela ;; Limpa seu conteúdo

.nomeTemaInvalido:

    pop es
    
    popa
    
    ret
    
.arquivoUsuarioAusente:

    pop es
    
    popa
    
    mov esi, logind.semArquivoUnix
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

exibirLogoSistema:

    mov esi, logind.sobreSistema

    imprimirString

match =Andromeda, TIPOLOGIN 
{
    
    mov esi, logind.versaoSistema

    imprimirString

    call obterVersaoDistribuicao

    jc .erro 

    mov esi, versaoObtida

    imprimirString

    mov esi, logind.colcheteEsquerdo

    imprimirString

    mov esi, codigoObtido

    imprimirString

    mov esi, logind.colcheteDireito

    imprimirString

    jmp .continuar 

.erro:

    mov esi, logind.semVersao

    imprimirString

    jmp .continuar

} 

.continuar:

    novaLinha

    ret

;;************************************************************************************

verificarConsistencia:

    call verificarTema             ;; Caso algum processo seja finalizado após alterar
                                   ;; o plano de fundo padrão

    Hexagonix limparTela

    ret

;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

checarBaseDados: 

    clc

    mov esi, arquivo

    Hexagonix arquivoExiste

    ret

;;************************************************************************************

enderecoCarregamento:

bufferArquivo:                ;; Local onde o arquivo de configuração será aberto
