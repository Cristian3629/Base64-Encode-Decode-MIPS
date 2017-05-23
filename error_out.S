#include <mips/regdef.h>
#include <sys/syscall.h>

.text
.abicalls
.align 2
.global error_out
.ent error_out

error_out:
	#debugging info
	.frame $fp, 48, ra
	#bloque para codigo PIC
	.set noreorder
	.cpload t9
	.set reorder

	#creo el stack frame
	subu sp, sp, 48;
	#directiva para codigo PIC
	.cprestore 48
		
	#salvo los callee-saved regs en SRA
	sw gp, 44(sp);
	sw ra, 40(sp);
	sw $fp, 36(sp);

	#uso el $fp para moverme por el stack
	move $fp, sp;

	#salvo los argumentos
	sw a0,48($fp);		#a0 = error num

	la a1, error_0;		#cargo la direccion de la direccion de memoria
	li a2, 18;						#el syscall tiene que leer un byte
	li v0,SYS_write
	syscall;

end:
	 #recupero el stack a su estado anterior y los registros que utilice
	lw gp, 44(sp)
	lw ra,40(sp)
	lw $fp,36(sp)
	lw s0,32(sp)
	lw s1,28(sp)
	lw s2,24(sp)
	addu sp,sp,48
	jr ra

.end error_out

.rdata
.global errmsg
.align 2

errmsg:  .word error_0, error_1, error_2
no_error: asciiz ""
error_0: .asciiz "Caracter no valido de base 64"
error_1: .asciiz "Error en archivo"
error_2: .asciiz "Caracter fuera de rango"
error_3: .asciiz "Error de lectura"
error_4: .asciiz "Error de escritura"
