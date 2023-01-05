;;************************************************************************************
;;
;;    
;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
;; ││ ││
;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2023 Felipe Miguel Nery Lunkes
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
;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
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

versaoMAN equ "2.2"

versaoCoreUtils equ "H2-RELEASE-5.1" 
versaoUnixUtils equ "H2-RELEASE-5.1"

align 32

man:

.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--help",0
.man:             db "Hexagonix(R) manual", 0
.uso:             db 10, "Usage: man [utility]", 10, 10
                  db "Display detailed help for installed Unix utilities.", 10, 10
                  db "CoreUtils version: ", versaoCoreUtils, 10
                  db "UnixUtils Version: ", versaoUnixUtils, 10, 10
                  db "man version ", versaoMAN, 10, 10
                  db "Copyright (C) 2018-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 10
                  db "Hexagonix is distributed under the BSD-3-Clause license.", 0
.aguardar:        db "Press <q> to exit.", 0
.naoEncontrado:   db ": manual not found for this utility.", 10, 0
.separador:       db 10, "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++", 10, 0
.extensaoManual:  db ".man", 0

;;************************************************************************************

inicioAPP:

    mov [utilitario], edi

    cmp byte[edi], 0
    je usoAplicativo

    mov edi, man.parametroAjuda
    mov esi, [utilitario]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, man.parametroAjuda2
    mov esi, [utilitario]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov esi, [utilitario]

    Hexagonix tamanhoString

    mov ebx, eax

    mov al, byte[man.extensaoManual+0]
    
    mov byte[esi+ebx+0], al
    
    mov al, byte[man.extensaoManual+1]
    
    mov byte[esi+ebx+1], al
    
    mov al, byte[man.extensaoManual+2]
    
    mov byte[esi+ebx+2], al
    
    mov al, byte[man.extensaoManual+3]
    
    mov byte[esi+ebx+3], al
    
    mov byte[esi+ebx+4], 0      ;; Fim da string

    push esi

    Hexagonix arquivoExiste

    jc manualNaoEncontrado

    mov edi, bufferArquivo

    pop esi
    
    Hexagonix abrir
    
    jc manualNaoEncontrado

;; Preparação do ambiente

    Hexagonix limparTela

    call montarInterface
    
    mov esi, bufferArquivo
    
    imprimirString

    jmp terminar

;;************************************************************************************

montarInterface:
    
    mov esi, man.man

    imprimirString

    mov ecx, 22

.loopEspaco:

    mov al, ' '
    
    Hexagonix imprimirCaractere
    
    dec ecx
    
    cmp ecx, 0
    je .terminado
    
    jmp .loopEspaco

.terminado:

    mov esi, [utilitario]

    imprimirString

    novaLinha
    novaLinha

    ret

;;************************************************************************************

manualNaoEncontrado:

    novaLinha

    mov esi, [utilitario]

    imprimirString

    mov esi, man.naoEncontrado

    imprimirString

   jmp terminar

;;************************************************************************************

usoAplicativo:

    mov esi, man.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

terminar:   

    Hexagonix encerrarProcesso
    
;;*****************************************************************************

utilitario: dd ?

bufferArquivo:
