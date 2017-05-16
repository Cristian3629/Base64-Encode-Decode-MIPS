#include <mips/regdef.h>
#include <sys/syscall.h>

.text
.abicalls
.align 2
.global base64_decode
.ent base64_decode

#La funcion que llama es base64_decode(infd,outfd)
#a0 es el file descriptor del archivo de entrada
#a1 es el file descriptor del archivo de salida
base64_decode:
		#debugging info
              	.frame $fp, 48, ra
		#bloque para codigo PIC
              	.set noreorder
              	.cpload t9
              	.set reorder

		#creo el stack frame
              	subu sp,sp,48
		#directiva para codigo PIC
              	.cprestore 48
		
		#salvo los callee-saved regs en SRA
              	sw gp, 44(sp)
             	sw ra, 40(sp)
              	sw $fp,36(sp)

		#uso el $fp para moverme por el stack
		move $fp,sp

		#salvo los argumentos
              	sw a0,48(sp)		#a0 = infd
              	sw a1,56(sp)		#a1 = outfd

        # voy a utilizar los registros s0,s1,s2 asi que los guardo

        sw s0,32(sp)
        sw s1,28(sp)
        sw s2,24(sp)

		#cargo los parametros para hacer la syscall
		#leo del fd que me pasaron por parametro
leer:
		lw a0,48($fp)		# a0 = infd
              	sw zero,buffer
              	la a1,buffer		# buffer es la direccion donde se guarda lo que se leyo
              	lw a2,lenght        	# leo de a 4 caracteres
              	li v0,SYS_read      	# se guarda en v0 el codigo del system call
              	syscall

              	#guardo la cantidad de bytes que lei del archivo
              	sw v0,16($fp)
              	li t0,1
              	#si solo lei un byte salto a ver si es un salto de linea
              	beq v0,t0,_check_end_line

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
              lw t0,16($fp)
              li t1,3
              blt t0,t1, _check_padding

              # en t6 tengo los bits que me interesa, en los bits mas bajos

_get_character:
              #cargo en t3 el caracter que corresponde en base64
              lbu t3,base64(t6)
              #cargo en un buffer de 1 byte el caracter en  base 64
              sb  t3,character

              #imprimo por fd el caracter en base64
              lw a0, 56($fp)		#Cargo en a0 el valor del fd de salida
              la a1,character		#cargo la direccion de la direccion de memoria
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
              j leer


_check_end_line:
              #aca verifico si lo que lei fue un salto de linea
              lw t0,buffer
              #el codigo ASCII del salto de linea /n es 10
              li t1,10
              #si recibi un salto de linea, no encodeo y salgo del programa
              beq t0,t1,_fin


_check_padding:
              #chequeo si los bits leidos corresponden a un paddig
             #si la posicion es mayor a cero,no hago nada
             bgtz t6,_get_character
             #si es cero, lo seteo en 64
             li t6,64
             j _get_character

              #imprimo por pantalla el fin de linea
_fin:         lw a0, 56($fp)	#Cargo en a0 el valor del fd de salida
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
              .end base64_decode

              .data      # segmento read-only data
              .align 2

lenght:       .word 4 #Leo de a 4 caracteres
              .align 0
              #reservo un espacio para guardar lo leido del archivo
buffer:       .space 4
              # reservo un espacio para guardar el caracter de base64
character:    .space 1

              .rdata
              .align 2


base64:       .ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
endLine:      .asciiz "\n"
