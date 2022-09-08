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
;; Copyright (C) 2016-2022 Felipe Miguel Nery Lunkes
;; Todos os direitos reservados.

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

align 4

include "hexagon.s"
include "macros.s"
include "Estelar/estelar.s"

;;************************************************************************************

inicioAPP:

    push ds
    pop es          
    
    mov [parametro], edi ;; Salvar os parâmetros da linha de comando para uso futuro

;;************************************************************************************

    Hexagonix obterCor

    mov dword[ls.corFonte], eax
    mov dword[ls.corFundo], ebx

;; A resolução em uso será verificada, para que o aplicativo se adapte ao tamanho da saída e à quantidade de informações 
;; que podem ser exibidas por linha. Desta forma, ele pode exibir um número menor de arquivos com menor resolução e um 
;; número maior por linha caso a resolução permita.

verificarResolucao:

    Hexagonix obterResolucao
    
    cmp eax, 1
    je .modoGrafico1

    cmp eax, 2
    je .modoGrafico2

;; Podem ser exibidos (n+1) arquivos, visto que o contador inicia a contagem de zero. Utilizar essa informação
;; para implementações futuras no aplicativo.
 
.modoGrafico1:

    mov dword[limiteExibicao], 5h ;; Podem ser exibidos 6 arquivos por linha (n+1)
    
    jmp verificarParametros
    
.modoGrafico2:

    mov dword[limiteExibicao], 7h ;; Podem ser exibidos 8 arquivos por linha (n+1)
    
    jmp verificarParametros

;;************************************************************************************

;; Agora os parâmetros serão verificados e as ações necessárias serão tomadas

verificarParametros:    
    
    mov esi, [parametro]
    
    mov edi, ls.parametroAjuda
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, ls.parametroAjuda2
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc usoAplicativo

    mov edi, ls.parametroTudo
    mov esi, [parametro]
    
    Hexagonix compararPalavrasString
    
    jc configurarExibicao
    
    cmp byte[esi], 0
    je listar

    jmp verificarArquivo

;;************************************************************************************

configurarExibicao:

    mov byte[ls.exibirTudo], 01h

    jmp listar

;;************************************************************************************

listar:
    
    novaLinha
    novaLinha
    
    Hexagonix listarArquivos    ;; Obter arquivos em ESI
    
    jc .erroLista
    
    mov [listaRemanescente], esi
    
    push eax

    pop ebx

    xor ecx, ecx
    xor edx, edx

.loopArquivos:
    
    push ds
    pop es
    
    push ebx
    push ecx
    
    call lerListaArquivos
    
    push esi
    
    sub esi, 5
    
    mov edi, ls.extensaoAPP
    
    Hexagonix compararPalavrasString  ;; Checar por extensão .APP
    
    jc .aplicativo
    
    mov edi, ls.extensaoSIS
    
    Hexagonix compararPalavrasString
    
    jc .sistema
    
    mov edi, ls.extensaoASM
    
    Hexagonix compararPalavrasString
    
    jc .fonteASM
    
    mov edi, ls.extensaoBIN
    
    Hexagonix compararPalavrasString
    
    jc .arquivoBIN
    
    mov edi, ls.extensaoUNX
    
    Hexagonix compararPalavrasString
    
    jc .arquivoUNX
    
    mov edi, ls.extensaoFNT
    
    Hexagonix compararPalavrasString
    
    jc .arquivoFNT
    
    mov edi, ls.extensaoOCL

    Hexagonix compararPalavrasString
    
    jc .arquivoOCL

    mov edi, ls.extensaoMOD

    Hexagonix compararPalavrasString
    
    jc .arquivoMOD

    mov edi, ls.extensaoCOW

    Hexagonix compararPalavrasString
    
    jc .arquivoCOW

    mov edi, ls.extensaoMAN

    Hexagonix compararPalavrasString
    
    jc .arquivoMAN

    jmp .arquivoComum

.aplicativo:

    pop esi
    
    mov eax, VERDE_FLORESTA
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao
    
    jmp .continuar
    
.sistema:

    pop esi
    
    mov eax, AZUL_MEDIO
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao
    
    jmp .continuar

.fonteASM:

    pop esi
    
    mov eax, VERMELHO
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao
    
    jmp .continuar
    
.arquivoBIN:

    pop esi
    
    mov eax, VIOLETA_ESCURO
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao
    
    jmp .continuar
    
.arquivoUNX:

    pop esi
    
    mov eax, MARROM_PERU
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao
    
    jmp .continuar

.arquivoOCL: ;; Obrigatoriamente, não deve ser exibido

    pop esi

    jmp .pularExibicao

.arquivoMOD: 

    pop esi
    
    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, LAVANDA_SURPRESA
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao

    jmp .continuar

.arquivoCOW: ;; Obrigatoriamente, não deve ser exibido

    pop esi
    
    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, VERDE_PASTEL
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao

    jmp .continuar

.arquivoMAN:

    pop esi
    
    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, TOMATE
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao

    jmp .continuar

.arquivoFNT:

    pop esi
    
    cmp byte[ls.exibirTudo], 01h
    jne .pularExibicao

    mov eax, TURQUESA_ESCURO
    
    call definirCorArquivo

    mov esi, [arquivoAtual]
    
    imprimirString
    
    call definirCorPadrao

    jmp .continuar

.pularExibicao:

    dec edx

    jmp .semEspaco
        
.arquivoComum:
    
    pop esi
    
    mov esi, [arquivoAtual]
    
    imprimirString

.continuar:
    
    call colocarEspaco

.semEspaco:
    
    pop ecx
    pop ebx
    
    cmp ecx, ebx
    je .terminado

    cmp edx, [limiteExibicao]
    je .criarNovaLinha
    
    inc ecx
    inc edx
    
    jmp .loopArquivos

.criarNovaLinha:

    xor edx, edx

;; Correção para não adicionar linhas a mais

    add ecx, 1

;; Continuar

    novaLinha
    
    jmp .loopArquivos
    
.terminado:

    cmp edx, 0h  ;; Verifica se existe algum arquivo solitário em uma linha
    jl terminar

    novaLinha
    
    jmp terminar

.erroLista:
  
    mov esi, ls.erroLista
    
    jmp terminar
    
;;************************************************************************************

usoAplicativo:

    mov esi, ls.uso
    
    imprimirString
    
    jmp terminar

;;************************************************************************************

terminar:   
    
    Hexagonix encerrarProcesso
    
;;************************************************************************************

;; Função única para definir a cor de representação de determinado arquivo
;;
;; Entrada:
;;
;; EAX - Cor do texto

definirCorArquivo:

    mov ebx, dword[ls.corFundo]
    
    Hexagonix definirCor
    
    ret

;;************************************************************************************

definirCorPadrao:

    mov eax, dword[ls.corFonte]
    mov ebx, dword[ls.corFundo]
    
    Hexagonix definirCor
    
    ret

;;************************************************************************************
    
colocarEspaco:

    push ecx
    push ebx
    push eax
    
    push ds
    pop es
    
    mov esi, [arquivoAtual]
    
    Hexagonix tamanhoString
    
    mov ebx, 15
    
    sub ebx, eax
    
    mov ecx, ebx

.loopEspaco:

    mov al, ' '
    
    Hexagonix imprimirCaractere
    
    dec ecx
    
    cmp ecx, 0
    je .terminado
    
    jmp .loopEspaco
    
.terminado:

    pop eax
    pop ebx
    pop ecx
    
    ret
    
;;************************************************************************************

;; Obtem os parâmetros necessários para o funcionamento do programa, diretamente da linha
;; de comando fornecida pelo Sistema

lerListaArquivos:

    push ds
    pop es
    
    mov esi, [listaRemanescente]
    mov [arquivoAtual], esi
    
    mov al, ' '
    
    Hexagonix encontrarCaractere
    
    jc .pronto

    mov al, ' '
    
    call encontrarCaractereListaArquivos
    
    mov [listaRemanescente], esi
    
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

encontrarCaractereListaArquivos:

    lodsb
    
    cmp al, ' '
    je .pronto
    
    jmp encontrarCaractereListaArquivos
    
.pronto:

    mov byte[esi-1], 0
    
    ret

;;************************************************************************************  

verificarArquivo:

    mov esi, [parametro]

    Hexagonix arquivoExiste

    jc terminar

    novaLinha
    novaLinha

    mov esi, [parametro]

    Hexagonix stringParaMaiusculo

    mov [parametro], esi

    imprimirString

    novaLinha

    jmp terminar

;;************************************************************************************

;;************************************************************************************
;;
;;                    Área de dados e variáveis do aplicativo
;;
;;************************************************************************************

versaoLS equ "2.1"

ls:

.extensaoAPP:      db ".APP", 0
.extensaoSIS:      db ".SIS", 0
.extensaoASM:      db ".ASM", 0
.extensaoBIN:      db ".BIN", 0
.extensaoUNX:      db ".UNX", 0
.extensaoFNT:      db ".FNT", 0
.extensaoOCL:      db ".OCL", 0
.extensaoCOW:      db ".COW", 0
.extensaoMAN:      db ".MAN", 0
.extensaoMOD:      db ".MOD", 0
.erroLista:        db 10, 10, "Erro ao listar os arquivos presentes no volume.", 10, 0
.uso:              db 10, 10, "Uso: ls", 10, 10
                   db "Lista e exibe os arquivos presentes no volume atual, classificando-os por tipo.", 10, 10
                   db "Parametros disponiveis:", 10, 10
                   db "-a - Lista todos os arquivos disponiveis no volume.", 10, 10
                   db "ls versao ", versaoLS, 10, 10
                   db "Copyright (C) 2017-", __stringano, " Felipe Miguel Nery Lunkes", 10
                   db "Todos os direitos reservados.", 10, 0
.parametroAjuda:   db "?", 0    
.parametroAjuda2:  db "--ajuda", 0
.parametroTudo:    db "-a" ,0         
.exibirTudo:       db 0
.corFonte:         dd 0
.corFundo:         dd 0
.corAPP:           dd 0
.corSIS:           dd 0
.corASM:           dd 0
.corBIN:           dd 0
.corUNX:           dd 0
.corFNT:           dd 0
.corOCL:           dd 0
.corCOW:           dd 0
.corMAN:           dd 0
parametro:         dd ?
listaRemanescente: dd ?
limiteExibicao:    dd 0
arquivoAtual:      dd ' '
