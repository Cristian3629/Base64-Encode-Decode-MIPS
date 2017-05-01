#Para poder poner nombres a los registros
#include <mips/regdef.h>
#Para poder hacer system calls
#include <sys/syscall.h>

.tex
.abicalls
.align 2
.global base64_encode
.ent base64_encode
.extern getBytesFromFile

base64_encode:
              .frame $fp, 40, ra
              .set nororder
              .cpload t9
              .set reorder

              subu sp,sp,40 #El 40 lo tengo que cambiar luego.
              .cprestore 24 #No se que hace
              sw gp,36(sp)
              sw ra,32(sp)
              sw $fp,28(sp)
              move $fp,sp

              sw a0,40(sp)  #guardo a0 en el stack del caller
              sw a1,44(sp)  #guardo a1 en el stak de caller
              lw a0,40(sp)  #paso el fd del archivo de entrada
              li a1,3       #quiero 3 bytes del archivo
loop1:
              jp getBytesFromFile #llamo a la funcion
              beqz v0,fin       #si es cero ya termine de leer el  archivo
              li t0,0       # i = 0
              li t1,3       # j = 3
              li t2,6       #cantidad de bits de un byte en base64
              li t3,8       #offset = 8
loop2:
              mul t4,t0,t2  #t4 = to*6
              addi t5,v0,0  #v0 = t5
              sll t5,t5,t4
              mul t4,t1,t2  #t4 = j*6
              add t4,t4,t3  #t4 = j*6 + 8
              slr t5,t5,t4
              lw a0,40(sp)  # fd = infd
              la a1,base64(t5)  #buf = caracter de base 64
              li a2,1       # count = 1
              li v0,SYS_write
              syscall
              beqz t1,loop1
              addi t0,t0,1 #i++
              subu t3,t3,1 #j--
              jal loop2

fin:
              lw gp, 36(sp)
              lw ra,32(sp)
              lw $fp,28(sp)
              addu sp,sp,40
              jr ra
              .end base64_encode

.rdata      # segmento read-only data
.align 2
base64:
            .word word0,word1,word2,word3,word4,word5,word6,word7,word8,word9,word10,
            word11,word12,word13,word14,word15,word16.

            .size 64
            .align 0 #alineacion 2^0

            word0: .asciiz "ABCD"
            word1: .asciiz "EFHG"
            word2: .asciiz "IJKL"
            word3: .asciiz "MNOP"
            word4: .asciiz "QRST"
            word5: .asciiz "UVWX"
            word6: .asciiz "YZab"
            word7: .asciiz "cdef"
            word8: .asciiz "ghij"
            word9: .asciiz "klmn"
            word10:.asciiz "opqr"
            word11:.asciiz "stuv"
            word12:.asciiz "wxyz"
            word13:.asciiz "0123"
            word14:.asciiz "4567"
            word15:.asciiz "89+/"
            word16:.asciiz "="
