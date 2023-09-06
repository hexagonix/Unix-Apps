#!/bin/bash
#
#*************************************************************************************************
#
# 88                                                                                88
# 88                                                                                ""
# 88
# 88,dPPPba,   ,adPPPba, 8b,     ,d8 ,adPPPPba,  ,adPPPb,d8  ,adPPPba,  8b,dPPPba,  88 8b,     ,d8
# 88P'    "88 a8P     88  `P8, ,8P'  ""     `P8 a8"    `P88 a8"     "8a 88P'   `"88 88  `P8, ,8P'
# 88       88 8PP"""""""    )888(    ,adPPPPP88 8b       88 8b       d8 88       88 88    )888(
# 88       88 "8b,   ,aa  ,d8" "8b,  88,    ,88 "8a,   ,d88 "8a,   ,a8" 88       88 88  ,d8" "8b,
# 88       88  `"Pbbd8"' 8P'     `P8 `"8bbdP"P8  `"PbbdP"P8  `"PbbdP"'  88       88 88 8P'     `P8
#                                               aa,    ,88
#                                                "P8bbdP"
#
#                    Sistema Operacional Hexagonix - Hexagonix Operating System
#
#                         Copyright (c) 2015-2023 Felipe Miguel Nery Lunkes
#                        Todos os direitos reservados - All rights reserved.
#
#*************************************************************************************************
#
# Português:
#
# O Hexagonix e seus componentes são licenciados sob licença BSD-3-Clause. Leia abaixo
# a licença que governa este arquivo e verifique a licença de cada repositório para
# obter mais informações sobre seus direitos e obrigações ao utilizar e reutilizar
# o código deste ou de outros arquivos.
#
# English:
#
# Hexagonix and its components are licensed under a BSD-3-Clause license. Read below
# the license that governs this file and check each repository's license for
# obtain more information about your rights and obligations when using and reusing
# the code of this or other files.
#
#*************************************************************************************************
#
# BSD 3-Clause License
#
# Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $HexagonixOS$

# Versão 2.2

gerarBaseUnix(){

echo
echo -e "\e[1;94mBuilding Hexagonix Unix applications...\e[0m {"
echo

echo "Building Hexagonix Unix based applications... {" >> $LOG
echo >> $LOG

# Vamos agora automatizar a construção dos aplicativos base Unix

for i in */
do

    cd $i

    for h in *.asm
    do

    echo -en "Building Hexagonix Unix utility \e[1;94m$(basename $h .asm)\e[0m..."

    echo " > Building Hexagonix Unix utility $(basename $h .asm)..." >> ../$LOG

    fasm $h ../$DIRETORIO/bin/`basename $h .asm` -d $FLAGS_COMUM >> ../$LOG || desmontar

    echo -e " [\e[32mOk\e[0m]"

    echo >> ../$LOG

# Aqui vão aplicações específicas dentro dos pacotes que contêm arquivos auxiliares que devem
# ser copiados, como os arquivos da ferramenta cowsay. Devem ser adicionados loops if para
# identificar a presença de diretórios com arquivos auxiliares, um para cada pacote que dependa
# de arquivos auxiliares. A mensagem deve ser padrão. Apenas o que está dentro dos '[ ]' do loop
# for e o comando de cópia devem variar.

    if [ -e cows ] ; then

    echo -n " > Copying additional package files for" $i

    cp cows/*.cow ../$DIRETORIO >> /dev/null

    echo -e " [\e[32mOk\e[0m]"

    fi

# Fim da área de aplicações específicas

    done

cd ..

done

echo
echo -e "} [\e[32mHexagonix utilities built successfully\e[0m]."
echo

echo >> $LOG
echo -e "} Hexagonix utilities built successfully." >> $LOG
echo >> $LOG
echo "----------------------------------------------------------------------" >> $LOG
echo >> $LOG

}

desmontar()
{

cd ..

cd ..

umount Sistema || exit

# Desmontar tudo"

umount -a

echo "An error occurred while building some system component."
echo
echo "Check the status of the components and use the above error outputs to verify the problem."
echo
echo "View the log file 'log.log', for more information about the error(s)."
echo

exit

}

export LOG="../../log.log"
export DIRETORIO="../../$1"

case $1 in

*) gerarBaseUnix; exit;;

esac
