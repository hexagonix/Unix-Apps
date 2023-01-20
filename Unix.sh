#!/bin/bash
# Esse script deve ficar na raiz do projeto
#
#;;************************************************************************************
#;;
#;;    
#;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
#;; ││ ││
#;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2023 Felipe Miguel Nery Lunkes
#;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
#;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
#;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
#;;              ┌─┘│                 Licenciado sob licença BSD-3-Clause
#;;              └──┘          
#;;                                                Versão 1.0
#;;
#;;************************************************************************************
#;;
#;; Este arquivo é licenciado sob licença BSD-3-Clause. Observe o arquivo de licença 
#;; disponível no repositório para mais informações sobre seus direitos e deveres ao 
#;; utilizar qualquer trecho deste arquivo.
#;;
#;; BSD 3-Clause License
#;;
#;; Copyright (c) 2015-2023, Felipe Miguel Nery Lunkes
#;; All rights reserved.
#;; 
#;; Redistribution and use in source and binary forms, with or without
#;; modification, are permitted provided that the following conditions are met:
#;; 
#;; 1. Redistributions of source code must retain the above copyright notice, this
#;;    list of conditions and the following disclaimer.
#;;
#;; 2. Redistributions in binary form must reproduce the above copyright notice,
#;;    this list of conditions and the following disclaimer in the documentation
#;;    and/or other materials provided with the distribution.
#;;
#;; 3. Neither the name of the copyright holder nor the names of its
#;;    contributors may be used to endorse or promote products derived from
#;;    this software without specific prior written permission.
#;; 
#;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#;;
#;; $HexagonixOS$

gerarBaseUnix(){

echo
echo -e "\e[1;94mBuilding Hexagonix® Unix applications...\e[0m {"
echo

echo "Building Hexagonix® Unix based applications... {" >> $LOG
echo >> $LOG
    
# Vamos agora automatizar a construção dos aplicativos base Unix

for i in */
do

    cd $i

    for h in *.asm
    do

    echo -en "Building Hexagonix® Unix utility \e[1;94m$(basename $h .asm)\e[0m..."
    
    echo Building Hexagonix® Unix Utility $(basename $h .asm)... >> $LOG
    
    echo >> $LOG
    
    fasm $h ../../../Andromeda/bin/`basename $h .asm` -d $BANDEIRAS >> $LOG || desmontar
    
    echo -e " [\e[32mOk\e[0m]"
    
    echo >> $LOG

# Aqui vão aplicações específicas dentro dos pacotes que contêm arquivos auxiliares que devem
# ser copiados, como os arquivos da ferramenta cowsay. Devem ser adicionados loops if para
# identificar a presença de diretórios com arquivos auxiliares, um para cada pacote que dependa
# de arquivos auxiliares. A mensagem deve ser padrão. Apenas o que está dentro dos '[ ]' do loop
# for e o comando de cópia devem variar.

    if [ -e cows ] ; then

    echo -n " > Copying additional package files for" $i 

    cp cows/*.cow ../$DESTINO >> /dev/null

    echo -e " [\e[32mOk\e[0m]"

    fi

# Fim da área de aplicações específicas

    done

cd ..

done

echo
echo -e "} [\e[32mHexagonix utilities built successfully\e[0m]."
echo


}

hexagonix()
{

export DESTINO="../../Hexagonix"
#export BANDEIRAS="UNIX=SIM -d TIPOLOGIN=UNIX -d VERBOSE=SIM"

gerarBaseUnix

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

export LOG="/dev/null"
export DESTINO="../../Andromeda"

case $1 in

hexagonix) hexagonix; exit;;
*) gerarBaseUnix; exit;;

esac 
