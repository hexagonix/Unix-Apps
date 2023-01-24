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

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametros], edi
    
    call obterParametros
    
    jc  usoAplicativo
    
    push esi
    push edi
    
    mov edi, cp.parametroAjuda
    mov esi, [parametros]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, cp.parametroAjuda2
    mov esi, [parametros]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    pop edi
    pop esi
    
    mov esi, [arquivoEntrada]
    
    hx.syscall arquivoExiste
    
    jc fonteNaoEncontrado
    
    mov esi, [arquivoSaida]
    
    hx.syscall arquivoExiste
    
    jnc destinoPresente
 
;; Agora vamos abrir o arquivo fonte para cópia
    
    mov esi, [arquivoEntrada]
    mov edi, bufferArquivo
    
    hx.syscall hx.open
    
    jc erroAoAbrir
    
    mov esi, [arquivoEntrada]
    
    hx.syscall arquivoExiste

;; Salvar arquivo no disco

    mov esi, [arquivoSaida]
    mov edi, bufferArquivo
    
    hx.syscall salvarArquivo
    
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

    hx.syscall encerrarProcesso

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

    mov esi, [parametros]
    mov [arquivoEntrada], esi
        
    cmp byte[esi], 0
    je usoAplicativo
    
    mov al, ' '
    
    hx.syscall encontrarCaractere
    
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

versaoCP equ "2.1.1"  

cp:
    
.naoEncontrado:     db 10, "File not found. Please check file name and try again.", 10, 0
.uso:               db 10, "Usage: cp [input file] [output file]", 10, 10
                    db "Performs a copy of a given file into another. Two file names are required, one being", 10
                    db "for input and another for output.", 10, 10
                    db "cp version ", versaoCP, 10, 10
                    db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                    db "All rights reserved.", 0
.fonteIndisponivel: db 10, "The provided source file cannot be found on this volume.", 10, 0                              
.destinoExistente:  db 10, "A file with the given name already exists for the destination. Please remove the file with the same", 10
                    db "destination name and try again.", 10, 0
.erroAbrindo:       db 10, "An error occurred while trying to open the copy source file.", 10
                    db "Try again. If the error persists, restart your computer.", 10, 0
.erroSalvando:      db 10, "An error occurred while requesting to save the target file to the volume.", 10
                    db "This could be due to write protection, drive removal", 10
                    db "out of storage or because the system is busy. Please try again", 10
                    db "later.", 10, 0
.copiaConcluida:    db 10, "The file has been successfully copied.", 10, 0
.parametroAjuda:    db "?", 0
.parametroAjuda2:   db "--help", 0
               
parametros:     dd 0     
arquivoEntrada: dd ?
arquivoSaida:   dd ?
regES:          dw 0
     
bufferArquivo:
