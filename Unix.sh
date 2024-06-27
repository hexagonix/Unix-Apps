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
#                         Copyright (c) 2015-2024 Felipe Miguel Nery Lunkes
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
# Copyright (c) 2015-2024, Felipe Miguel Nery Lunkes
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

function main() {

case $1 in

--version) showVersion; exit;;
*) buildUnixUtilities; exit;;

esac

}

function buildUnixUtilities() {

echo
echo -e "\e[1;94mBuilding Hexagonix Unix applications...\e[0m {"
echo

echo "Building Hexagonix Unix based applications... {" >> $LOG
echo >> $LOG

# Let's now automate the construction of Unix base applications

for i in */
do

    cd $i

    for h in *.asm
    do

    echo -en "Building Hexagonix Unix utility \e[1;94m$(basename $h .asm)\e[0m..."

    echo " > Building Hexagonix Unix utility $(basename $h .asm)..." >> $LOG

    fasm $h $BUILD_DIRECTORY/bin/`basename $h .asm` -d $COMMON_FLAGS >> $LOG || unmount

    echo -e " [\e[32mOk\e[0m]"

    echo >> $LOG

# Here are specific applications within the packages that contain auxiliary files that must be copied,
# such as the cowsay tool files.
# If loops must be added to identify the presence of directories with auxiliary files, one for each
# package that depends on auxiliary files.
# The message must be standard. Only what is inside the '[ ]' of the for loop and the copy 
# command should vary.

    if [ -e cows ] ; then

    echo -n " > Copying additional package files for" $i

    cp cows/*.cow $BUILD_DIRECTORY >> /dev/null

    echo -e " [\e[32mOk\e[0m]"

    fi

# End of specific applications area

    done

cd ..

done

echo -e "\n} [\e[32mHexagonix utilities built successfully\e[0m]."

echo >> $LOG
echo -e "} Hexagonix utilities built successfully." >> $LOG
echo >> $LOG
echo "----------------------------------------------------------------------" >> $LOG
echo >> $LOG

}

function unmount() {

cd ..
cd ..

umount $MOUNT_POINT_DIRECTORY || exit

umount -a

echo "An error occurred while building some system component."
echo
echo "Check the status of the components and use the above error outputs to verify the problem."
echo
echo "View the log file 'log.log', for more information about the error(s)."
echo

exit

}

function showVersion() {

echo "hx build module for Unix utilities, version $UNIX_MOD_VERSION"
echo
echo -e "\e[0mCopyright (c) 2015-2024 Felipe Miguel Nery Lunkes\e[0m"
echo -e "hx and hx modules are licensed under BSD-3-Clause and comes with no warranty."

}

export UNIX_MOD_VERSION="4.0.1"

main $1
