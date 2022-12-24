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
;;
;; Dados do aplicativo
;;
;;************************************************************************************

versaoFNT equ "0.1"

fnt:

.uso:             db 10, 10, "Usage: fnt [graphic font file]", 10, 10   
                  db "Asks to change the system graphics font.", 10, 10
                  db "fnt version ", versaoFNT, 10, 10
                  db "Copyright (C) 2022-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 10, 0
.nomeArquivo:     db 10, 10, "Font filename: ", 0    
.nomeFonte:       db "Filename: ", 0
.sucesso:         db 10, 10, "Font changed successfully.", 10, 10
                  db "Press any key to continue...", 10, 10, 0
.falha:           db 10, 10, "The file cannot be found.", 10, 10
                  db 10, 10, "Press any key to continue...", 10, 10, 0
.falhaFormato:    db 10, 10, "The provided file does not contain a font in Hexagon(R) format.", 10, 10
                  db "Press any key to continue...", 10, 10, 0
.falhaFormatoT:   db 10, 10, "The file provided does not contain a font in Hexagon(R) format.", 10, 0
.sucessoTexto:    db 10, 10, "Font changed successfully.", 10, 0
.falhaTexto:      db 10, 10, "The file cannot be located.", 10, 0
.introducaoTeste: db 10, "Font and characters preview: ", 0
.testeFonte:      db 10, 10, "Hexagonix(R) Operating System", 10, 10
                  db "1234567890-=", 10
                  db "!@#$%^&*()_+", 10
                  db "QWERTYUIOP{}", 10
                  db "qwertyuiop[]", 10
                  db 'ASDFGHJKL:"|', 10
                  db "asdfghjkl;'\", 10
                  db "ZXCVBNM<>?", 10
                  db "zxcvbnm,./", 10, 10
                  db "Hexagonix(R) Operating System", 10, 0
.tamanhoSuperior: db 10, 10, "This font file exceeds the maximum size of 2 Kb.", 10, 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--help", 0

parametro:        dd 0
arquivoFonte:     dd ?
regES:            dw 0

;;************************************************************************************

inicioAPP:

    mov [regES], es
    
    push ds
    pop es          
    
    mov [parametro], edi

    mov esi, [parametro]

    cmp byte[esi], 0
    je usoAplicativo
    
    mov edi, fnt.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, fnt.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo
    
    mov esi, fnt.nomeArquivo
    
    imprimirString
    
    mov esi, [parametro]
    
    imprimirString
    
    mov esi, [parametro]
    
    Hexagonix cortarString          ;; Remover espaços em branco extras
    
    call validarFonte

    jc .erroFormato

    Hexagonix alterarFonte
    
    jc .erroTexto
    
    mov esi, fnt.sucessoTexto
    
    imprimirString

    mov esi, fnt.introducaoTeste

    imprimirString

    mov esi, fnt.testeFonte

    imprimirString
    
    mov ebx, 00h
    
    Hexagonix encerrarProcesso
    
.erroTexto:

    mov esi, fnt.falhaTexto
    
    imprimirString

    jmp .erroFim

.erroFormato:
    
    mov esi, fnt.falhaFormatoT
    
    imprimirString

    jmp .erroFim

.erroFim:
    
    mov ebx, 00h
    
    jmp terminar
    
;;************************************************************************************

terminar:

    mov ebx, 00h

    Hexagonix encerrarProcesso
    
;;************************************************************************************

usoAplicativo:

    mov esi, fnt.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

validarFonte:

    mov esi, [parametro]
    mov edi, bufferArquivo

    Hexagonix abrir

    jc .erroSemFonte

    mov edi, bufferArquivo

    cmp byte[edi+0], "H"
    jne .naoHFNT

    cmp byte[edi+1], "F"
    jne .naoHFNT

    cmp byte[edi+2], "N"
    jne .naoHFNT

    cmp byte[edi+3], "T"
    jne .naoHFNT

.verificarTamanho:

    Hexagonix arquivoExiste

;; Em EAX, o tamanho do arquivo. Ele não deve ser maior que 2000 bytes, o que poderia
;; sobrescrever dados na memória do Hexagon

    mov ebx, 2000

    cmp eax, ebx
    jng .continuar

    jmp .tamanhoSuperior

.continuar:

    clc 
    
    ret

.erroSemFonte:
    
    mov esi, fnt.falhaTexto
    
    imprimirString

    jmp terminar

.naoHFNT:

    stc

    ret

.tamanhoSuperior:

    mov esi, fnt.tamanhoSuperior
    
    imprimirString

    jmp terminar

;;************************************************************************************

bufferArquivo:
