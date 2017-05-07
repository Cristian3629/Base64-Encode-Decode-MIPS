#include <mips/regdef.h>
#include <sys/syscall.h>

.text
.abicalls
.align 2
.global base64_encode
.ent base64_encode

#la llamada a esta funcion va a ser readFile(int fd, int bytes);
#a0 es el file descriptor del archivo
#a1 es la cantidad de bytes que voy a leer del archivo
base64_encode:
              .frame $fp, 40, ra
              .set noreorder
              .cpload t9
              .set reorder

              subu sp,sp,40       #El 40 lo tengo que cambiar luego.
              .cprestore 24       #No se que hace
              sw gp,36(sp)        #guardo el global pointer
              sw ra,32(sp)        #guardo el ra
              sw $fp,28(sp)       #guardo el frama pointer
              move $fp,sp         #inserto el valor del stack pointer en el frame pointer
              sw a0,40(sp)        #guardo a0 en el stack del caller
              sw a1,44(sp)        #guardo a1 en el stak de caller



              #lw a0,40(sp)        # fd = infd
              #la a1,buffer        # buf = es el direccion donde quiere que la funcion guarde lo que leyo
              #lw a2,lenght        # count = 4
              #li v0,SYS_read      # se guarda en v0 el codigo del system call
              #syscall

              #lw t9,buffer       #test
              li a0,1             # fd = 1
              la a1,_buffer       # el syscall lee del buffer
              li a2,12            # cantidad de bytes a escribir = 4
              li v0,SYS_write     # hago una llamada a syscall
              syscall
              j fin               # salto a fin, para liberar el stack

fin:
              lw gp, 36(sp)
              lw ra,32(sp)
              lw $fp,28(sp)
              addu sp,sp,40
              jr ra
              .end base64_encode

              .data      # segmento read-only data
              .align 2

_buffer:       .asciiz "Hello word\n"
lenght:       .word 4
              .align 0
buffer: .space 5
