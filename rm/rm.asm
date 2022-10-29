;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2022 Felipe Miguel Nery Lunkes
;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
;;              ┌─┘│                 Licenciado sob licença BSD-3-Clause
;;              └──┘          
;;
;;
;;************************************************************************************
;;
;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
;; utilizar qualquer trecho deste arquivo.
;;
;; BSD 3-Clause License
;;
;; Copyright (c) 2015-2022, Felipe Miguel Nery Lunkes
;; All rights reserved.
;; 
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;; 
;; 1. Redistributions of source code must retain the above copyright notice, this
;;    list of conditions and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice,
;;    this list of conditions and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its
;;    contributors may be used to endorse or promote products derived from
;;    this software without specific prior written permission.
;; 
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;; $HexagonixOS$

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
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioAPP, 01h

;;************************************************************************************

include "hexagon.s"
include "macros.s"
include "erros.s"

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    mov esi, [parametro]
        
    cmp byte[esi], 0
    je semParametro
    
    mov edi, rm.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, rm.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    mov esi, [parametro]
    
    Hexagonix arquivoExiste
    
    jc .arquivoNaoEncontrado
    
    novaLinha
    novaLinha
    
    mov esi, rm.confirmacao
    
    imprimirString
    
.obterTeclas:

    Hexagonix aguardarTeclado
    
    cmp al, 's'
    je .deletar
    
    cmp al, 'S'
    je .deletar
    
    cmp al, 'n'
    je .abortar
    
    cmp al, 'N'
    je .abortar

    jmp .obterTeclas        
    
    
.arquivoNaoEncontrado:

    mov esi, rm.naoEncontrado
    
    imprimirString
    
    jmp terminar

.deletar:

    Hexagonix imprimirCaractere
    
    mov esi, [parametro]
    
    Hexagonix deletarArquivo
    
    jc .erroDeletando
    
    mov esi, rm.deletado
    
    imprimirString
    
    jmp terminar

.abortar:

    Hexagonix imprimirCaractere
    
    mov esi, rm.abortar
    
    imprimirString
    
    jmp terminar
    
.erroDeletando:

    push eax

    mov esi, rm.erroDeletando
    
    imprimirString  
    
    pop eax
    
    cmp eax, IO.operacaoNegada
    je .permissaoNegada
    
    jmp terminar

.permissaoNegada:

    mov esi, rm.permissaoNegada
    
    imprimirString
    
    jmp terminar
    
;;************************************************************************************

usoAplicativo:

    mov esi, rm.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

semParametro:

    mov esi, rm.semParametro
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoRM equ "1.0"

rm:

.naoEncontrado:   db 10, 10, "Arquivo nao encontrado. Verifique a ortografia e tente novamente.", 10, 0
.uso:             db 10, 10, "Uso: rm [arquivo]", 10, 10
                  db "Solicita a exclusao de um arquivo no disco atual.", 10, 10
                  db "rm versao ", versaoRM, 10, 10
                  db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "Todos os direitos reservados.", 10, 0
.confirmacao:     db "Voce tem certeza que deseja excluir este arquivo (s/N)? ", 0
.deletado:        db 10, 10, "O arquivo solicitado foi deletado com sucesso.", 10, 0
.erroDeletando:   db 10, 10, "Um erro ocorreu durante a solicitacao. Nenhum arquivo foi deletado.", 10, 10, 0  
.abortar:         db 10, 10, "A operacao foi abortada pelo usuario.", 10, 0  
.parametroAjuda:  db "?", 0  
.parametroAjuda2: db "--ajuda", 0    
.semParametro:    db 10, 10, "Um nome de arquivo necessario esta ausente.", 10
                  db "Utilize 'rm ?' para ajuda com este utilitario.", 10, 0  
.permissaoNegada: db "Apenas um usuario administrativo pode concluir essa acao.", 10
                  db "Para tanto, realize o login em um destes usuarios com poderes administrativos.", 10, 0                 
    
parametro: dd ?

regES:  dw 0
     
bufferArquivo:
