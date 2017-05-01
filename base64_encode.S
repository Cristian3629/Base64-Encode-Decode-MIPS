#Para poder poner nombres a los registros
#include <mips/regdef.h>
#Para poder hacer system calls
#include <sys/syscall.h>

.tex
.abicalls
.align 2
.global base64_encode
.ent base64_encode

base64_encode:
              .frame $fp, 40, ra
              .set nororder
              .cpload t9
              .set reorder

              subu sp,sp,40 #El 40 lo tengo que cambiar luego.
              .cprestore 24 #No se que hace
              sw $fp,28(sp)
              sw ra,32(sp)
              move $fp,sp
              
