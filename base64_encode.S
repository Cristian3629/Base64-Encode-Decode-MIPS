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

              subu sp,sp,48       #El 40 lo tengo que cambiar luego.
              .cprestore 48       #No se que hace
              sw gp, 44(sp)        #guardo el global pointer
              sw ra, 40(sp)        #guardo el ra
              sw $fp,36(sp)       #guardo el frama pointer

              sw a0,48(sp)        #guardo a0 en el stack del caller
              sw a1,56(sp)        #guardo a1 en el stak de caller

              # voy a utilizar los registros s0,s1,s2 asi que los guardo

              sw s0,32(sp)
              sw s1,28(sp)
              sw s2,24(sp)

              # muevo el sp en el fp y lo utilizo

              move $fp,sp

              #cargo los parametros para hacer la syscall
              #leo del archivo que me pasaron por parametro

_read_file:   lw a0,48($fp)        # fd = infd
              sw zero,buffer
              la a1,buffer        # buf = es el direccion donde quiere que la funcion guarde lo que leyo
              lw a2,lenght        # count = 3
              li v0,SYS_read      # se guarda en v0 el codigo del system call
              syscall

             #guardo la cantidad de bytes que lei del archivo
              sw v0,16($fp)

             # llamo al modulo que verificar si hay algun salto de linea
             # en el buffer

              j _check_jump_line

_check_number_bytes_read:
              # si la cantidad de bytes leidos es cero, termino el programa
              lw t0,16($fp)
              beq zero,t0,_fin

_encode:
             # Dada la arquitectura little endian y para poder encodear
             # base64, si tengo en el archivo abc, en el buffer me
             # queda cba, para eso realizo el swap entre el primer byte
             # y el ultimo



              #cargo en t0 la primera posicion del buffer
              li t0,1
              # cargo la ultima posicion en t1
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
              lw t0,16($fp)
              li t1,3
              blt t0,t1, _check_padding

              # en t6 tengo los bits que me interesa, en los bits mas bajos
              jal _check_position

_get_character:
              #cargo en t3 el caracter que corresponde en base64
              lbu t3,base64(t6)
              #cargo en un buffer de 1 byte el caracter en  base 64
              sb  t3,character

              #imprimo por pantalla el caracter en base64
              li a0,1             #el fd = 1 es porque imprimo por STDIN
              la a1,character     #cargo la direccion de la direccion de memoria
              li a2,1             #el syscall tiene que leer un byte
              li v0,SYS_write
              syscall

              # j--, t1--
              sub s1,s1,1
              # i++,t0++
              addiu s0,s0,1
              #si t1 es negativo, termino el loop
              bltz s1,_verific_status
              j _shifteo


_verific_status:
              #obtengo la cantidad de bytes que lei del archivo
              lw t0,16($fp)
              li t1,3

              #si la cantidad de bytes es menor a 3, termino el programa
              blt t0,t1,_fin
              j _read_file



_reduce_of_bytes_read:
             #aca descuento en uno la cantidad de bytes leidos
             lw t0,16($fp)        # obtengo del stack la cantidad de bytes leidos
             subu t0,t0,1         # descuento en uno
             sw t0,16($fp)        # lo cargo devuelta en memoria
             j _check_number_bytes_read

_delete_jump_line:
             # en esta funcion elimino el salto de linea de mi buffer
             # dado que se que hay un salto de linea y esta al final
             # con la cantidad de bytes puedo saber donde esta
             lw t0, 16($fp)
             subu t0,t0,1
             sb zero, buffer(t0)
             j _reduce_of_bytes_read

_check_jump_line:
              # aca verifico que si tengo salto de linea, en caso de que
              # si haya, lo elimino del buffer y descuento en 1 la cantidad
              # de bytes leidos
              lw t0,16($fp)       # obtengo la cantidad de bytes leidos
              subu t0,t0,1        # decremento en 1, para obtener la posicion del /n
              lbu t1,buffer(t0)   # cargo el byte que seria el salto de linea
              li t2,10            # cargo en t2 el codigo ASCII de /n
              beq t2,t1,_delete_jump_line
              j _check_number_bytes_read

_check_padding:
              #chequeo si los bits leidos corresponden a un paddig
             #si la posicion es mayor a cero,no hago nada
             bgtz t6,_get_character
             #si es cero, lo seteo en 64
             li t6,64
             j _get_character
_check_position:
              #chequeo si la posicion obtenida para la base64
              #es una posicion valida
              li t0,0          # menor posicion posible
              li t1,64        # maxima posicion posible
              #si la posicion es mayor a 64
              bgt t6,t1,_error_position
              # si la posicion es menor a 0
              blt t6,t0,_error_position
              j ra

_error_position:
              li v0,1
              j _fin


              #imprimo por pantalla el fin de linea
_fin:          li a0,1
              la a1,endLine
              li a2,1
              li v0,SYS_write
              syscall

              #recupero el stack a su estado anterior y los registros que utilice
              lw gp, 44(sp)
              lw ra,40(sp)
              lw $fp,36(sp)
              lw s0,32(sp)
              lw s1,28(sp)
              lw s2,24(sp)
              addu sp,sp,48
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

              .rdata
              .global errmsg
              .align 2
errmsg:  .word error_0, error_1, error_2
error_0: .asciiz "Err1r"
error_1: .asciiz "Err2r"
error_2: .asciiz "Err3r"
