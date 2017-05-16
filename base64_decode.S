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
              	lw a2,lenght        	# leo de a 1 caracter
              	li v0,SYS_read      	# se guarda en v0 el codigo del system call
              	syscall

              	#guardo la cantidad de bytes que lei del archivo
              	sw v0,16($fp)
              	li t0,1

		addu t2, zero, zero	#t2 = 0 = puntero
		li t6, 0		#t6 = posicion 
		lw t7, buffer		#t7 = caracter leido
ciclo:
		#Lo uso para recorrer el array
		sll t3, t2, 2		#t3 = t2*4 = puntero * 4

		la t4, base64		#t4 = base64
		addu t4, t4, t3		#t4 = base64 + puntero * 4
		lw t4, 0(t4)		#t4 = *t4

		beq t4, t7, decode 	#si el caracter ingresado coincide con el leido en la tabla base64, lo decodifico

		addu t6,t6,1		#t6 = t6 + 1
		
		#beq t6, 64, error	

		j ciclo			#si no repito
 		
decode:
              #guardo la posicion de la tabla en el buf_posicion
              sb  t6,buf_posicion

              #imprimo por fd el caracter en base64
              lw a0, 56($fp)		#Cargo en a0 el valor del fd de salida
              la a1,buf_posicion		#cargo la direccion de la direccion de memoria
              li a2,1             #el syscall tiene que leer un byte
              li v0,SYS_write
              syscall

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

lenght:       .word 4 #Leo de a 1 caracteres
              .align 0
              #reservo un espacio para guardar lo leido del archivo
buffer:       .space 1
              # reservo un espacio para guardar el caracter de base64
buf_posicion:    .space 1

              .rdata
              .align 2


base64:       .ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
endLine:      .asciiz "\n"
