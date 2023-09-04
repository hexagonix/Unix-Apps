;;*************************************************************************************************
;;
;; 88                                                                                88              
;; 88                                                                                ""              
;; 88                                                                                                
;; 88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8  
;; 88P'    "88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88 88  `P8, ,8P'   
;; 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(     
;; 88       88 "8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88 88  ,d8" "8b,   
;; 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88 88 8P'     `P8  
;;                                               aa,    ,88                                         
;;                                                "P8bbdP"       
;;
;;                     Sistema Operacional Hexagonix - Hexagonix Operating System
;;
;;                         Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
;;                        Todos os direitos reservados - All rights reserved.
;;
;;*************************************************************************************************
;;
;; Português:
;; 
;; O Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause. Leia abaixo
;; a licença que governa este arquivo e verifique a licença de cada repositório para
;; obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
;; o código deste ou de outros arquivos.
;;
;; English:
;;
;; Hexagonix and its components are licensed under a BSD-3-Clause license. Read below
;; the license that governs this file and check each repository's license for
;; obtain more information about your rights and obligations when using and reusing
;; the code of this or other files.
;;
;;*************************************************************************************************
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

;; Agora vamos criar um cabeçalho para a imagem HAPP final do aplicativo.

include "HAPP.s" ;; Aqui está uma estrutura para o cabeçalho HAPP

;; Instância | Estrutura | Arquitetura | Versão | Subversão | Entrada | Tipo  
cabecalhoAPP cabecalhoHAPP HAPP.Arquiteturas.i386, 1, 00, inicioAPP, 01h

;;************************************************************************************

include "hexagon.s"
include "console.s"
include "macros.s"

;;************************************************************************************

inicioAPP:
    
    push ds
    pop es          
    
    mov [parametro], edi
    
    call obterParametros

    mov edi, cowsay.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, cowsay.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    novaLinha

    mov esi, [mensagemUsuario]

    hx.syscall tamanhoString

    mov dword[tamanhoMensagem], eax

    mov ecx, eax
    add ecx, 4

.loopBalaoSuperior:

    fputs cowsay.linhaSuperior

    loop .loopBalaoSuperior

.lateralEsquerda:

    novaLinha

    fputs cowsay.barra

    mov ecx, dword[tamanhoMensagem]
    add ecx, 2

.loopEspacoSuperior:

    fputs cowsay.espaco

    loop .loopEspacoSuperior

    fputs cowsay.barra

    novaLinha

.mensagem:

    fputs cowsay.barra

    fputs cowsay.espaco

    fputs [mensagemUsuario]

    fputs cowsay.espaco

    fputs cowsay.barra

    novaLinha

    fputs cowsay.barra

    mov ecx, dword[tamanhoMensagem]
    add ecx, 2

.loopEspacoInferior:

    fputs cowsay.espaco

    loop .loopEspacoInferior

    fputs cowsay.barra

    novaLinha

    mov ecx, dword[tamanhoMensagem]

    add ecx, 4

.loopBalaoInferior:

    fputs cowsay.linhaInferior

    loop .loopBalaoInferior

    novaLinha

    cmp byte[arquivoExterno], 0
    je .vaquinhaInterna

    mov esi, [perfilVaquinha]

    hx.syscall tamanhoString
    
    mov ebx, eax

    mov al, byte[cowsay.extensaoCOW+0]
    
    mov byte[esi+ebx+0], al
    
    mov al, byte[cowsay.extensaoCOW+1]
    
    mov byte[esi+ebx+1], al
    
    mov al, byte[cowsay.extensaoCOW+2]
    
    mov byte[esi+ebx+2], al
    
    mov al, byte[cowsay.extensaoCOW+3]
    
    mov byte[esi+ebx+3], al
    
    mov byte[esi+ebx+4], 0      ;; Fim da string, será cortada aqui e nada após será relevante

    push esi

    hx.syscall arquivoExiste
    jc .vaquinhaInterna

    pop esi

    mov edi, bufferArquivo

    hx.syscall hx.open

    jc .vaquinhaInterna
    
    fputs bufferArquivo

    jmp .finalizar

.vaquinhaInterna:

    fputs cowsay.vaquinha

.finalizar:

    jmp terminar

;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

obterParametros:

    mov esi, [parametro]
    mov [perfilVaquinha], esi
        
    cmp byte[esi], 0
    je usoAplicativo

;; Então vamos lá. Algumas coisas serão feitas aqui para verificar parâmetros, como alteração
;; do personagem a ser exibido e os parâmetros a serem impressos na saída padrão

;; Primeiro, vamos procurar por '"'. Isso indica que se trata de uma frase e que se deve pular a 
;; busca por um parâmetro de alteração de personagem, que é o primeiro parâmetro. Deve-se usar
;; esse caractere para pular o carregamento de outro personagem em caso de frase. Senão, será
;; interpretado que a primeira palavra é o personagem a ser carregado do disco e a mensagem sairá
;; picada, mesmo se não existir o personagem em um arquivo .COW no disco. Então, isso tudo será
;; validado agora.

;; Primeiro, vamos validar se temos uma frase aqui

    mov al, '"' ;; Vamos pesquisar pelo marcador de frase

    clc ;; Limpar o Carry

    hx.syscall encontrarCaractere ;; Solicitar o serviço de busca de caractere

    jnc .semArquivoExterno ;; Foi identificado um marcador de frase. Pular carregamento de personagem

;; Tudo bem, não temos uma frase. Temos mais de um parâmetro, o que poderia identificar uma única
;; palavra após o parâmetro de personagem? Se o usuário não inseriu o '"', assim será interpretado.

    mov al, ' ' ;; Vamos pesquisar se existe um espaço, que seria a indicação de duas ou mais palavras
    
    hx.syscall encontrarCaractere ;; Solicitar o serviço de busca de caractere
    
    jc .adicionarMensagem ;; Não temos mais de uma palavra, o que indica que não há troca de personagem

;; Até agora já validamos frases e palavras individuais, sem a necessidade de carregamento de um
;; personagem diretamente do disco. Se chegamos até aqui, isso quer dizer que existe mais de uma
;; palavra e o usuário não especificou se tratar de uma frase, com o caractere '"'. Dessa forma,
;; deve-se separar o primeiro parâmetro, que corresponde ao personagem, do restante da string, que
;; é o que será exibido ao usuário

    mov al, ' ' ;; Vamos procurar a posição em que ocorre a separação dos parâmetros
    
    call encontrarCaractereCowsay ;; Essa função é do aplicativo, não da API do Sistema
    
    mov [mensagemUsuario], esi ;; A string devidamente cortada e separada. O corte de nome de arquivo
                               ;; será feito mais adiante.
    jmp .pronto                 

;; Um personagem externo deve ser carregado e após existe um palavra ou frase

.pronto:

    mov byte[arquivoExterno], 01h ;; Marcar que um personagem externo deve ser carregado

    clc
    
    ret

;; Bom, temos uma frase. Temos que remover os caracteres '"' da string a ser impressa.
;; Vamos lá!

.semArquivoExterno:

    clc ;; Limpar Carry

    mov esi, [perfilVaquinha] ;; Vamos pegar a string de parâmetro fornecida pelo Sistema

    hx.syscall cortarString ;; Cortar ela (trimming), para ter certeza das posições de caracteres

;; Agora vamos fazer a remoção dos caracteres '"', lembrando que só serão removidos o primeiro e 
;; último caracteres '"'. Qualquer um no interior da cadeia permanecerá, por enquanto.

    mov eax, 00h ;; Posição zero da cadeia cortada, primeiro '"'

    hx.syscall removerCaractereString ;; Sistema, remova, por favor

    hx.syscall tamanhoString ;; Agora, qual o tamanho da cadeia residual?

    dec eax ;; O último caractere é sempre o terminador, então recue um. Este é o último '"'

    hx.syscall removerCaractereString ;; Sistema, remova, por favor

    mov [mensagemUsuario], esi ;; A mensagem está pronta para ser exibida

    mov byte[arquivoExterno], 00h ;; Marcar como utilização do personagem interno

    ret

;; Agora, o caso de uma palavra ter sido passada como parâmetro. Isso quer dizer que, mesmo que
;; faça referência a um personagem externo, ignorar. Nesse caso, pelo menos dois termos devem
;; ser passados. O que adiante carregar um personagem se não existe uma mensagem? Então, ignorar
;; o personagem e interpretar como uma única palavra a ser exibida. Basicamente, o parâmetro inicial
;; será transportado para o espaço de memória destinado à mensagem devidamente pronta para a exibição

.adicionarMensagem:

    clc

    mov esi, [perfilVaquinha]

    mov [mensagemUsuario], esi ;; A mensagem está pronta para ser exibida

    mov byte[arquivoExterno], 00h ;; Marcar como utilização do personagem interno

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

encontrarCaractereCowsay:

    lodsb
    
    cmp al, ' '
    je .pronto
    
    jmp encontrarCaractereCowsay
    
.pronto:

    mov byte[esi-1], 0
    
    ret

;;************************************************************************************  

usoAplicativo:

    fputs cowsay.uso
    
    jmp terminar

;;************************************************************************************

terminar:   

    hx.syscall encerrarProcesso

;;************************************************************************************

versaoCOWSAY equ "2.1.6"

cowsay:

.uso:
db 10, "Usage: cowsay [profile] [message]", 10, 10
db "Display a message to the user.", 10, 10
db "You can change the animal or entity profile that displays the message.", 10
db "This change must be requested BEFORE the message.", 10
db 'In the case of a sentence, the character " must appear before and after the sentence.', 10, 10
db "cowsay version ", versaoCOWSAY, 10, 10
db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
db "All rights reserved.", 0
.parametroAjuda:
db "?", 0
.parametroAjuda2:
db "--help", 0
.espaco:
db " ", 0
.barra:
db "|", 0
.linhaSuperior:
db "_", 0
.linhaInferior:
db "-", 0
.vaquinha:
db "   \", 10
db "    \   ^__^", 10
db "     \  (oo)\_______", 10
db "        (__)\       )\/\", 10
db "             ||----w |", 10
db "             ||     ||", 0
.extensaoCOW:
db ".cow", 0

parametro:        dd ?
perfilVaquinha:   dd ?
mensagemUsuario:  dd ?
arquivoExterno:   db 0
tamanhoMensagem:  dd 0
regES:            dw 0
     
bufferArquivo: