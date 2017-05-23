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
              .frame $fp, 56, ra
              .set noreorder
              .cpload t9
              .set reorder

              subu sp,sp,56
              .cprestore 56       #No se que hace
              sw gp, 52(sp)        #guardo el global pointer
              sw $fp,48(sp)       #guardo el frama pointer
              sw ra, 44(sp)        #guardo el ra
              # muevo el sp en el fp y lo utilizo
              move $fp,sp

              sw a0,60($fp)        #guardo a0 en el stack del caller
              sw a1,64($fp)        #guardo a1 en el stak de caller

              # voy a utilizar los registros s0,s1,s2 asi que los guardo

              sw s0,40($fp)
              sw s1,36($fp)
              sw s2,32($fp)
              sw s3,28($fp) 
              # implicitamente no hubo error asi que cargo en s3
              li s3,0
              #cargo los parametros para hacer la syscall
              #leo del archivo que me pasaron por parametro

_read_file:     lw a0,60($fp)        # fd = infd
              sw zero,buffer
              la a1,buffer        # buf = es el direccion donde quiere que la funcion guarde lo que leyo
              lw a2,lenght        # count = 3
              li v0,SYS_read      # se guarda en v0 el codigo del system call
              syscall

              #guardo la cantidad de bytes que lei del archivo
              sw v0,20($fp)
              lw t0,20($fp)
              beqz t0,_fin
              j _check_end_line

_check_zero:  lw t0,20($fp)
              beqz t0,_fin

              #Dada la arquitectura little endian, y para poder encodear a
              #base 64, si tengo en el archivo abc, en el buffer me quedaria
              #cba, para eso realizo un swap entre el primer e ultimo termino.

_encode:
              # cargo la direccion del buffer en t1
              li t1,2

              # t3 = c
              lbu t3,buffer(zero)

              # t4 = a
              lbu t4,buffer(t1)

              # buffer[2] = t3 = c
              sb t3,buffer(t1)

              # buffer[0] = t4 = a
              sb t4,buffer(zero)

              # i = 0
              li s0,0             # t0 = 0
              # j = 3
              li s1,3             # t1 = 3
              # cantidad bits de byte base 64
              li s2,6             # t2 = 6


              # t4 es cantidad de bits que shifteo a la izquierda
_shifteo:      mul t4,s0,s2        # t4 = t0*t2 = i*6

              addiu t4,8
              # t5 es la cantidad de bits que shifteo a la derecha
              mul t5,s1,s2        # t5 = t1*t2 = j*6
              li t6,0
              lw t6,buffer        # cargo en t6 los 3 bytes leidos

              # obtengo los 6 bits que me interesa

              sll t6,t6,t4        # shift left logical t4 bits
              srl t6,t6,t4

              srl t6,t6,t5        # shift right logical t4 bits

              #si cantidad de bytes leido es menor a 3
              lw t0,20($fp)
              li t1,3
              blt t0,t1, _check_padding

              # en t6 tengo los bits que me interesa, en los bits mas bajos

_get_character:
              lbu t3,base64(t6)
              #cargo en un buffer de 1 byte el caracter en  base 64
              sb  t3,character

              #imprimo por pantalla el caracter en base64
              lw a0,64($fp)             #el fd = 1 es porque imprimo por STDIN
              la a1,character     #cargo la direccion de la direccion de memoria
              li a2,1             #el syscall tiene que leer un byte
              li v0,SYS_write
              syscall
              bltz a3,_error_syscall

              # j--, t1--
              sub s1,s1,1
              # i++,t0++
              addiu s0,s0,1
              #si t1 es negativo, termino el loop
              bltz s1,_verific_status
              j _shifteo


_verific_status:
              #obtengo la cantidad de bytes que lei del archivo
              lw t0,20($fp)
              li t1,3

              #si la cantidad de bytes es menor a 3, termino el programa
              blt t0,t1,_fin
              j _read_file


_check_end_line:
             #verifico si algun salto de linea y lo saco
             lw t0,20($fp)
             subu t0,t0,1
             lbu t1,buffer(t0)
             li t2,10
             bne t1,t2,_encode
             sb zero,buffer(t0)
             sw t0,20($fp)
             j _check_zero

_check_padding:
              #chequeo si los bits leidos corresponden a un paddig
             #si la posicion es mayor a cero,no hago nada
             bgtz t6,_get_character
             #si es cero, lo seteo en 64
             li t6,64
             j _get_character


_error_syscall:
             #si llego aca hubo un error
              li s3,4
              j _fin

              #imprimo por pantalla el fin de linea
_fin:
              li a0,1
              la a1,endLine
              li a2,1
              li v0,SYS_write
              syscall

              #recupero el stack a su estado anterior y los registros que utilice
              lw gp, 52($fp)
              lw ra,44($fp)
              lw s0,40($fp)
              lw s1,36($fp)
              lw s2,32($fp)
              lw $fp,48($fp)
              addu sp,sp,56
              move v0,s3
              lw s3,28($fp)
              jr ra
              .end base64_encode

              .data      # segmento read-only data
              .align 2

lenght:       .word 3
              .align 0
              #reservo un espacio para guardar lo leido del archivo
buffer:       .space 4
              # reservo un espacio para guardar el caracter de base64
character:    .space 1

              .rdata
              .align 2


base64:       .ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
endLine:      .asciiz "\n"
