#!/bin/sh
#;;************************************************************************************
#;;
#;;    
#;;        %#@@%&@@%&@@%@             Sistema Operacional Andromeda®
#;;        #@@@@@@#@#@#@@
#;;        @#@@%    %#@#%
#;;        @#@@@    #@#@@
#;;        #@#@@    !@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
#;;        @#@%!@&%@&@#@#             Todos os direitos reservados
#;;        !@@%#%&#&@&@%#
#;;        @@#!%&@&@#&*@&
#;;        @#@#%    &%@#@
#;;        @#!@@    !#@#@                    Script versão 0.8
#;;
#;;
#;;************************************************************************************

gerarBaseUnix(){

echo
echo "Gerando aplicativos base Unix do Hexagonix®... {"
echo

echo "Gerando aplicativos base Unix do Hexagonix®... {" $LOG
echo >> $LOG
	
# Vamos agora automatizar a construção dos aplicativos base Unix

for i in */
do

	cd $i

	for h in *.asm
	do

	echo -n Gerando aplicativo base Unix do Hexagonix® $(basename $h .asm).app...
	
	echo Gerando aplicativo base Unix do Hexagonix® $(basename $h .asm).app... >> $LOG
	
	echo >> $LOG
	
	fasm $h ../../`basename $h .asm`.app -d $BANDEIRAS >> $LOG || desmontar
	
	echo " [Ok]"
	
	echo >> $LOG

# Aqui vão aplicações específicas dentro dos pacotes que contêm arquivos auxiliares que devem
# ser copiados, como os arquivos da ferramenta cowsay. Devem ser adicionados loops if para
# identificar a presença de diretórios com arquivos auxiliares, um para cada pacote que dependa
# de arquivos auxiliares. A mensagem deve ser padrão. Apenas o que está dentro dos '[ ]' do loop
# for e o comando de cópia devem variar.

	if [ -e cows ] ; then

	echo -n "Copiando arquivos adicionais do pacote" $i 

	cp cows/*.cow ../$DESTINO >> /dev/null

	echo " [Ok]"

	fi

# Fim da área de aplicações específicas

	done

cd ..

done

echo
echo "} Aplicativos base Unix gerados com sucesso."
echo

echo "} Aplicativos base Unix gerados com sucesso." >> $LOG
echo >> $LOG
echo "----------------------------------------------------------------------" >> $LOG
echo >> $LOG

}

hexagonix()
{

export DESTINO="../../Hexagonix"
export BANDEIRAS="UNIX=SIM -d TIPOLOGIN=UNIX -d VERBOSE=SIM"

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
