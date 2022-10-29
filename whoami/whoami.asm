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

;;************************************************************************************          

inicioAPP: ;; Ponto de entrada do Gerenciador de Login do Andromeda®

    mov [linhaComando], edi
    
    mov edi, whoami.parametroAjuda
    mov esi, [linhaComando]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, whoami.parametroAjuda2
    mov esi, [linhaComando]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
        
    mov edi, whoami.parametroTudo
    mov esi, [linhaComando]
    
    Hexagonix compararPalavrasString
    
    jc usuarioEGrupo
    
    mov edi, whoami.parametroUsuario
    mov esi, [linhaComando]
    
    Hexagonix compararPalavrasString
    
    jc exibirUsuario

    jmp exibirUsuario
    
;;************************************************************************************          
    
exibirUsuario:
  
    novaLinha
    novaLinha
    
    Hexagonix obterUsuario
    
    imprimirString
    
    novaLinha
    
    jmp terminar

;;************************************************************************************

usuarioEGrupo:

    novaLinha
    novaLinha
    
    Hexagonix obterUsuario
    
    push eax
    
    imprimirString
    
    mov esi, whoami.grupo
    
    imprimirString
    
    pop eax
    
    imprimirInteiro
    
    novaLinha
    
    jmp terminar
    
;;************************************************************************************      

usoAplicativo:

    mov esi, whoami.uso
    
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
    
linhaComando: dd 0

versaoWHOAMI equ "1.0"

whoami:

.uso:              db 10, 10, "Uso: whoami", 10, 10
                   db "Exibe o nome do usuario atualmente logado no Sistema.", 10, 10     
                   db "Parametros possiveis (em caso de falta de parametros, a opcao '-u' sera selecionada):", 10, 10
                   db "-t - Exibe todas as informacoes possiveis do usuario atualmente logado", 10
                   db "-u - Exibe apenas o nome do usuario logado", 10, 10             
                   db "whoami versao ", versaoWHOAMI, 10, 10
                   db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                   db "Todos os direitos reservados.", 10, 0
.parametroAjuda:   db "?", 0  
.parametroAjuda2:  db "--ajuda", 0 
.parametroTudo:    db "-t", 0
.parametroUsuario: db "-u", 0
.grupo:            db ", do grupo ", 0              
