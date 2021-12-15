;;************************************************************************************
;;
;;    
;;        %#@$%&@$%&@$%$             Sistema Operacional Hexagonix®
;;        #$@$@$@#@#@#@$
;;        @#@$%    %#$#%
;;        @#$@$    #@#$@
;;        #@#$$    !@#@#     Copyright © 2016-2021 Felipe Miguel Nery Lunkes
;;        @#@%!$&%$&$#@#             Todos os direitos reservados
;;        !@$%#%&#&@&$%#
;;        @$#!%&@&@#&*@&
;;        $#$#%    &%$#@
;;        @#!$$    !#@#@
;;
;;
;;************************************************************************************

.naoEncontrado:     db 10, 10, "File not found. Check the filename and try again.", 10, 0
.uso:               db 10, 10, "Use: cp [source] [destination]", 10, 10
                    db "Copy a given file into another. Two filenames are required, one input and output.", 10
                    db "", 10, 10
                    db "cp version ", versaoCP, 10, 10
                    db "Copyright (C) 2017-2021 Felipe Miguel Nery Lunkes", 10
                    db "All rights reserved.", 10, 0
.fonteIndisponivel: db 10, 10, "The source file provided cannot be found on this disc.", 10, 0                              
.destinoExistente:  db 10, 10, "A file with the given name for the destination already exists. Please remove the file with the same", 10
                    db "destination name and try again.", 10, 0
.erroAbrindo:       db 10, 10, "An error occurred when trying to open the source file.", 10
                    db "Try again. If the error persists, restart your computer.", 10, 0
.erroSalvando:      db 10, 10, "An error occurred when requesting to save the target file to disk.", 10
                    db "This could be due to write protection, drive removal", 10
                    db "or because the System is busy. Try again", 10
                    db "", 10, 0
.copiaConcluida:    db 10, 10, "The file was successfully copied.", 10, 0
 .parametroAjuda:   db "?", 0
 .parametroAjuda2:  db "--help", 0