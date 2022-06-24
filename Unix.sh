#!/bin/bash
# Esse script deve ficar na raiz do projeto
#
#;;************************************************************************************
#;;
#;;    
#;; ┌┐ ┌┐                                 Sistema Operacional Hexagonix®
#;; ││ ││
#;; │└─┘├──┬┐┌┬──┬──┬──┬─┐┌┬┐┌┐    Copyright © 2016-2022 Felipe Miguel Nery Lunkes
#;; │┌─┐││─┼┼┼┤┌┐│┌┐│┌┐│┌┐┼┼┼┼┘          Todos os direitos reservados
#;; ││ │││─┼┼┼┤┌┐│└┘│└┘││││├┼┼┐
#;; └┘ └┴──┴┘└┴┘└┴─┐├──┴┘└┴┴┘└┘
#;;              ┌─┘│          
#;;              └──┘                             Versão 1.0
#;;
#;;
#;;************************************************************************************

gerarBaseUnix(){

echo
echo -e "\e[1;94mConstruindo aplicativos base Unix do Hexagonix®...\e[0m {"
echo

echo "Construindo aplicativos base Unix do Hexagonix®... {" >> $LOG
echo >> $LOG
	
# Vamos agora automatizar a construção dos aplicativos base Unix

for i in */
do

	cd $i

	for h in *.asm
	do

	echo -en "Construindo aplicativo base Unix do Hexagonix® \e[1;94m$(basename $h .asm).app\e[0m..."
	
	echo Construindo aplicativo base Unix do Hexagonix® $(basename $h .asm).app... >> $LOG
	
	echo >> $LOG
	
	fasm $h ../../`basename $h .asm`.app -d $BANDEIRAS >> $LOG || desmontar
	
	echo -e " [\e[32mOk\e[0m]"
	
	echo >> $LOG

# Aqui vão aplicações específicas dentro dos pacotes que contêm arquivos auxiliares que devem
# ser copiados, como os arquivos da ferramenta cowsay. Devem ser adicionados loops if para
# identificar a presença de diretórios com arquivos auxiliares, um para cada pacote que dependa
# de arquivos auxiliares. A mensagem deve ser padrão. Apenas o que está dentro dos '[ ]' do loop
# for e o comando de cópia devem variar.

	if [ -e cows ] ; then

	echo -n "Copiando arquivos adicionais do pacote" $i 

	cp cows/*.cow ../$DESTINO >> /dev/null

	echo -e " [\e[32mOk\e[0m]"

	fi

# Fim da área de aplicações específicas

	done

cd ..

done

echo
echo -e "} [\e[32mUtilitários Hexagonix construídos com sucesso\e[0m]."
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

rm -r *.app

cd ..

umount Sistema || exit

# Desmontar tudo"

umount -a

echo "Um erro ocorreu durante a construção de algum componente do sistema."
echo
echo "Verifique o status dos componentes e utilize as saídas de erro acima para verificar o problema."
echo
echo "Visualize o arquivo de log 'log.log', para mais informações sobre o(s) erro(s)."
echo 

exit	
	
}

export LOG="/dev/null"
export DESTINO="../../Andromeda"

case $1 in

hexagonix) hexagonix; exit;;
*) gerarBaseUnix; exit;;

esac 
