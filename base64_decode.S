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
		sw a0,48(sp);		#a0 = infd
		sw a1,56(sp);		#a1 = outfd

		#guardo la informacion de control
		sw zero,32(sp)	#primer caracter decodificado
        sw zero,28(sp)	#segundo caracter decodificado
        sw zero,24(sp)	#tercer caracter decodificado

        li s6, 0;			#referencia para saber que caracter lei del buffer
        li s7, 0;			#referencia para saber que caracter decodificar

read_fd:
		#leo del fd que me pasaron por parametro
		li a0, 0;			#cargo el fd en a0 (0 = stdin)
		sw zero, buffer;	#inicializo el buffer en 0
		la a1, buffer;		#a1 = direccion donde se quiere guardar lo que se lee
		lw a2, lenght;		#cantidad de caracteres a leer 
		li v0, SYS_read;	#llamada al sistema (leer)
		syscall;

		move s0, v0;			#v0 -> s0, guardo el codigo de salida en t0
		
		li t1, 4;				#t1=4, lo uso para comparar con lo leido
		beq s0, t1, decode;		#si t1=s0 (cantidad leida) entonces traduce, si no, es un error o un EOF	
		blt s0, t1, condicion;	#si la cantidad leida es menor a 4 (s0<t1), puede ser un error o EOF

condicion:
		#en s0 tengo el valor actualizado de retorno de la syscall
		li t1, 1;				#t1=1, lo uso para comparar con lo leido (1 caracter puede ser EOF)
		beq s0, t1, check_eof;	#si s0=t1, se leyo un unico caracter, veo si es el eof
		j error;				#si leyo menos de cinco caracteres, es un error

check_eof:
		#aca verifico si lo que lei fue un salto de linea
		lw t0, buffer;
        #el codigo ASCII del salto de linea /n es 10
        li t1, 10;
        #si recibi un salto de linea, salgo del programa
        beq t0,t1, end;
		#el codigo ASCII del salto de linea /n es 10
		
		#si no, es un error
		j error;

error:
		#tengo los caracteres en el buffer, printeo lo que lei
        li a0, 1;			#cargo el fd en a0 (1 = stdout)
        la a1, base64;		#cargo en a1 la direccion de memoria de donde leo
        li a2, 3;			#cantidad de caracteres a escribir
        li v0, SYS_write;
        syscall;

        j end;

decode:
		lbu s1, buffer(s6);		#cargo el primer caracter leido en s1
		li s2, 0; 				#cargo s2 en 0 para usarlo de referencia en la tabla de tradcucion
		li s3, 0;				
		j search_character;		
		#repito la operacion hasta que se terminen los caracteres
		
		li t0, 12;
		beq s6, t0, read_fd;	#si ya procese los 4 caracteres, continuo con la lectura de otros 4
		addiu s6, s6, 4;		#cargo la nueva posicion a leer del buffer
		j decode;				#repito el proceso

search_character:
		#busca el caracter de la posicion s2 la tabla de traduccion
		lbu t1, base64(s2);				#guardo el caracter de la posicion s2 en t1
		beq t1, s1, decode_characters;	#comparo el caracter leido del buffer con el de la posicion de la tabla
		
		addiu s2, s2, 1;				#s2=s2+1, lo uso para avanzar una posicion
		li t3, 66;						#t3=66, lo uso para conocer si llegue a la ultima posicion del array de trauccion
		bgeu s2, t3, error 				#s2>=t3 (66) entonces es un error, el caracter no existe en la tabla de traduccion
		
		beq s2, t3, error;				#si al sumar 4 a s2 me paso del tamaño del array de traduccion, es un error y el caracter no existe
		j search_character;				#contiuno con la busqueda del caracter
		
decode_characters:
		#segun el caracter a traducir, elijo que hacer
		li t0, 0;
		beq t0, s7, first_character;
		li t0, 1;
		beq t0, s7, second_character;
		li t0, 2;
		beq t0, s7, third_character;
		j end;


first_character:
		#en s2 tengo la posicion del caracter, lo uso para traducirlo
		move t0, s2;	#guardo el valor en t0 para trabajar tranquilo
		#li t0, 0b00010011;
		li t1, 2;		#guardo la cantidad de lugares a desplazar
		sll t2, t0, t1;	#shifteo a izquierda dos posiciones, guardo el resultado en t2

		sw t2, 32(sp);	#guardo los primeros 6 bits que me interesan del primer caracter en el SRA
		
		#ori t2, t2, 0b00000001;

		#sb t2, buffer_traduccion; #guardo la primer tira de bits XXXXXX00

		#inicializo el buffer de traduccion
		#sw zero, translate_buffer;
		#cargo en un buffer de 1 byte el caracter en  base 64
        #sb  t2, translate_buffer;

        #imprimo por pantalla el caracter en base64
        #li a0,1             #el fd = 1 es porque imprimo por STDIN
        #la a1, buffer_traduccion;     #cargo la direccion de la direccion de memoria
        #li a2,1             #el syscall tiene que leer un byte
        #li v0,SYS_write
        #syscall

		#tengo los caracteres en el buffer, printeo lo que lei
        #li a0, 1;				#cargo el fd en a0 (1 = stdout)
        #la a1, base64(s2);		#cargo en a1 la direccion de memoria de donde leo
        #li a2, 1;				#cantidad de caracteres a escribir
        #li v0, SYS_write;
        #syscall;

        addiu s7, s7, 1;		#decodificado el primer caracter(parcialmente), seteo para que codifique el segundo
        j decode;

second_character:
		#en s2 tengo la posicion del caracter, lo uso para traducirlo
		move t0, s2;	#guardo el valor en t0 para trabajar tranquilo
		li t1, 2;		#guardo la cantidad de lugares a desplazar
		sll t0, t0, t1;	#shifteo a izquierda dos posiciones, guardo el resultado en t0

		li t1, 6;
		srl t0, t0, t1;	#shifteo a derecha 6 posiciones para quedarme con los dos bits que me faltan del primer caracter 

		lbu t2, 32(sp);	#carga en t2 el primer caracter sin los 2 bits finales 
		or t0, t0, t2;	#or logico entre los 6 bits del primer caracter y los primeros 2 bits del segundo
		#ahora en t0 tengo el primer caracter real
		sw t0, 32(sp);	#guardo los 8 bits completos del primer caracter

		#debug
		sb t0, buffer_traduccion; #guardo la primer tira de bits XXXXXX00	
		li a0,1             #el fd = 1 es porque imprimo por STDIN
        la a1, buffer_traduccion;     #cargo la direccion de la direccion de memoria
        li a2,1             #el syscall tiene que leer un byte
        li v0,SYS_write
        syscall
        #debug

        move t0, s2;	#recupero el valor original leido a t0
        li t1, 4;
        sll t0, t0, t1;	#shifteo 4 posiciones a izquierda para quedarme con los 4 bits que me interesan para el segundo caracter
		sw t0, 28(sp);	#guardo los primeros 4 bits que me interesan del segundo caracter en el SRA

        addiu s7, s7, 1; #decodificado el primer caracter y el segundo parcialmente, seteo para que codifique el tercero
        j decode;

third_character:
		#en s2 tengo la posicion del caracter, lo uso para traducirlo
		move t0, s2;	#guardo el valor en t0 para trabajar tranquilo
		li t1, 2;		#guardo la cantidad de lugares a desplazar
		sll t0, t0, t1;	#shifteo a izquierda dos posiciones, guardo el resultado en t0
		
		li t1, 4;
		srl t0, t0, t1;	#shifteo a derecha 4 posiciones para quedarme con los 4 bits que me faltan del segundo caracter 

		lbu t2, 28(sp);	#carga en t2 el segundo caracter sin los 4 bits finales 
		or t0, t0, t2;	#or logico entre los 4 bits del segundo caracter y los 4 bits del tercero
		#ahora en t0 tengo el segundo caracter real
		sw t0, 28(sp);	#guardo los 8 bits completos del segundo caracter

		#debug
		sb t0, buffer_traduccion; #guardo la primer tira de bits XXXXXX00	
		li a0,1             #el fd = 1 es porque imprimo por STDIN
        la a1, buffer_traduccion;     #cargo la direccion de la direccion de memoria
        li a2,1             #el syscall tiene que leer un byte
        li v0,SYS_write
        syscall
        #debug

        move t0, s2;	#recupero el valor original leido a t0
        li t1, 6;
        sll t0, t0, t1;	#shifteo 6 posiciones a izquierda para quedarme con los 2 bits finales que me interesan para el tercer caracter
		sw t2, 24(sp);	#guardo los primeros 2 bits que me interesan del tercer caracter en el SRA

        addiu s7, s7, 1; #decodificado el primer caracter y el segundo parcialmente, seteo para que codifique el tercero
		j end;

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
        .end base64_decode

        .data      # segmento read-only data
        .align 2

lenght:
		#caracteres a leer del fd
		.word 4

.align 0
buffer:
		#reservo un espacio para guardar lo leido del archivo
		.space 5	#buffer de caracteres leidos (son 4 caracteres + 1 requerido por la syscall)

buffer_traduccion:
		.space 1

.rdata
		.align 2
base64:
		.ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

endLine:
		.asciiz "\n"
