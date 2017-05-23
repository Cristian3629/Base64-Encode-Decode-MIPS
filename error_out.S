#include <mips/regdef.h>
#include <sys/syscall.h>




.rdata
.global errmsg
.align 2

errmsg:  .word no_error,error_0, error_1, error_2, error_3,error_4
no_error: .asciiz "    "
error_0: .asciiz "Caracter no valido de base 64"
error_1: .asciiz "Error en archivo"
error_2: .asciiz "Caracter fuera de rango"
error_3: .asciiz "Error de lectura"
error_4: .asciiz "Error de escritura"
