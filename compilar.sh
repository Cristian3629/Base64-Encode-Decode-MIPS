gcc -c -ggdb -Wall tp1.c
gcc -c -ggdb -Wall base64_encode.S
gcc -c -ggdb -Wall base64_decode.S
gcc -c -ggdb -Wall error_out.S

gcc tp1.o base64_decode.o base64_encode.o error_out.o -o tp