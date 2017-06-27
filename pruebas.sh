    echo PRUEBAS POSITIVAS
    while read line
    do 
       echo -n $line > entrada_encode
       ./tp -i entrada_encode > salida_encode
       ./tp -a decode -i salida_encode > salida_decode
       if diff entrada_encode salida_decode
       then 
          echo OK:$line
       else
          echo ERROR:$line
       fi
    done < pruebas.txt

    echo PRUEBAS NEGATIVAS
    echo 'Caracter no valido de base 64' > error_base_64
    echo ---- > caracteres_no_validos
    ./tp -a decode -i caracteres_no_validos > salida
    if diff error_base_64 salida
    then
       echo Insertar caracter no valido:OK
    else
       echo Inserter caracter no valido:ERROR
    fi