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
;;                    Sistema Operacional Hexagonix® - Hexagonix® Operating System
;;
;;                          Copyright © 2015-2023 Felipe Miguel Nery Lunkes
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
    
    mov [parametro], edi
    
    mov esi, [parametro]
    
    mov edi, date.parametroAjuda
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo

    mov edi, date.parametroAjuda2
    mov esi, [parametro]
    
    hx.syscall compararPalavrasString
    
    jc usoAplicativo
    
    novaLinha

    call processarBCD ;; Fazer a conversão de BCD para caractere imrprimível

    fputs date.dia

    fputs date.espaco 

    fputs date.mes

    fputs date.espaco 

    fputs date.hora

    fputs date.sepHora

    fputs date.minuto

    fputs date.sepHora

    fputs date.segundo

    fputs date.espaco 

    fputs date.fuso

    fputs date.espaco 

    fputs date.seculo 

    fputs date.ano 

match =SIM, DIASEMANA
{
    
;; Vamos verificar agora o dia da semana

    mov eax, date.diaSemana

    cmp byte[eax], '1'
    je .domingo

    cmp byte[eax], '2'
    je .segunda

    cmp byte[eax], '3'
    je .terca

    cmp byte[eax], '4'
    je .quarta

    cmp byte[eax], '5'
    je .quinta

    cmp byte[eax], '6'
    je .sexta

    cmp byte[eax], '7'
    je .sabado

    jmp .desconhecido

.domingo:

    fputs date.domingo

    jmp .continuar

.segunda:

    fputs date.segunda

    jmp .continuar

.terca:

    fputs date.terca

    jmp .continuar

.quarta:

    fputs date.quarta

    jmp .continuar

.quinta:

    fputs date.quinta

    jmp .continuar

.sexta:

    fputs date.sexta

    jmp .continuar

.sabado:

    fputs date.sabado

    jmp .continuar

.desconhecido:

}

.continuar:

    jmp terminar

;;************************************************************************************

processarBCD:

;; Primeiro, vamos solicitar informações do relógio em tempo real

;; Vamos processar o dia
    
    hx.syscall hx.date

    call BCDParaASCII

    mov word[date.dia], ax
    mov byte[date.dia+15], 0

;; Vamos processar o mês

    hx.syscall hx.date

    mov eax, ebx 

    call BCDParaASCII

    mov word[date.mes], ax
    mov byte[date.mes+15], 0

;; Vamos processar o século (primeiros dois dígitos do ano)

    hx.syscall hx.date

    mov eax, ecx 

    call BCDParaASCII

    mov word[date.seculo], ax
    mov byte[date.seculo+15], 0

;; Vamos processar o ano

    hx.syscall hx.date

    mov eax, edx 

    call BCDParaASCII

    mov word[date.ano], ax
    mov byte[date.ano+15], 0

;; Vamos processar o dia da semana

    hx.syscall hx.date

    mov eax, esi 

    call BCDParaASCII

    mov word[date.diaSemana], ax
    mov byte[date.diaSemana+15], 0

;; Vamos processar a hora

    hx.syscall hx.time

    mov eax, eax 

    call BCDParaASCII

    mov word[date.hora], ax
    mov byte[date.hora+15], 0

;; Vamos processar os minutos

    hx.syscall hx.time

    mov eax, ebx

    call BCDParaASCII

    mov word[date.minuto], ax
    mov byte[date.minuto+15], 0

;; Vamos processar os segundos

    hx.syscall hx.time

    mov eax, ecx

    call BCDParaASCII

    mov word[date.segundo], ax
    mov byte[date.segundo+15], 0

    ret

;;************************************************************************************

;; Realiza a conversão de um número BCD para um caractere ASCII que pode ser
;; imprimível 

BCDParaASCII:
    
    mov ah, al
    and ax, 0xF00F ;; Mascarar bits
    shr ah, 4      ;; Deslocar para direita AH para obter BCD desempacotado
    or ax, 0x3030  ;; Combinar com 30 para obter ASCII
    xchg ah, al    ;; Trocar por convenção ASCII
    
    ret

;;************************************************************************************

usoAplicativo:
    
    fputs date.uso
    
    jmp terminar

;;************************************************************************************

terminar:   

    hx.syscall encerrarProcesso

;;************************************************************************************

versaoDATE equ "1.2.3"

date:
        
.uso:             db 10, "Usage: date", 10, 10
                  db "Display system date and time.", 10, 10
                  db "date version ", versaoDATE, 10, 10
                  db "Copyright (C) 2020-", __stringano, " Felipe Miguel Nery Lunkes", 10
                  db "All rights reserved.", 0
.domingo:         db " (domingo)", 0
.segunda:         db " (segunda-feira)", 0
.terca:           db " (terca-feira)", 0
.quarta:          db " (quarta-feira)", 0
.quinta:          db " (quinta-feira)", 0
.sexta:           db " (sexta-feira)", 0
.sabado:          db " (sabado)", 0
.parametroAjuda:  db "?", 0
.parametroAjuda2: db "--help", 0
.sepData:         db "/", 0
.sepHora:         db ":", 0
.espacamento:     db " of ", 0
.espaco:          db " ", 0
.fuso:            db "GMT", 0
.dia:             dd 0
.mes:             dd 0
.seculo:          dd 0
.ano:             dd 0
.hora:            dd 0
.minuto:          dd 0
.segundo:         dd 0
.diaSemana:       dd 0

parametro:        dd ?