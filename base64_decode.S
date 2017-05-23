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

	li s3, 0;	#se usa para controlar los errores

	#salvo los argumentos
	sw a0,52($fp);		#a0 = infd
	sw a1,56($fp);		#a1 = outfd

	#guardo la informacion de control
	sw zero,32($fp)	#primer caracter decodificado
	sw zero,28($fp)	#segundo caracter decodificado
	sw zero,24($fp)	#tercer caracter decodificado
       
read_fd:
	li s6, 0;				#referencia para saber que caracter lei del buffer
	li s7, 0;				#referencia para saber que caracter decodificar

	lw a0, 52($fp);			#cargo el fd en a0
	sw zero, buffer;		#inicializo el buffer en 0
	la a1, buffer;			#a1 = direccion donde se quiere guardar lo que se lee
	lw a2, lenght;			#cantidad de caracteres a leer 
	li v0, SYS_read;		#llamada al sistema (leer)
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
			
	#si no, es un error
	j error;

error:
	#cargo el numero de posicion en el array de errores a devolver
	move v0, s3;	#s3 lo uso para informacion de debug
	j end;

decode:
	li t0, 4;
	beq s6, t0, read_fd;	#si ya procese los 4 caracteres, continuo con la lectura de otros 4

	lbu s1, buffer(s6);		#cargo el primer caracter leido en s1
	li s2, 0;				#cargo s2 en 0 para usarlo de referencia en la tabla de tradcucion				
	j search_character;		

search_character:
	#busca el caracter de la posicion s2 la tabla de traduccion
	lbu t1, base64(s2);				#guardo el caracter de la posicion s2 en t1
	beq t1, s1, decode_characters;	#comparo el caracter leido del buffer con el de la posicion de la tabla
		
	addiu s2, s2, 1;				#s2=s2+1, lo uso para avanzar una posicion
	
	#t3=66, lo uso para conocer si llegue a la ultima posicion del array de trauccion
	li t3, 66;
	
	li s3, 1;
	bgeu s2, t3, error 				#s2>=t3 (66) entonces es un error, el caracter no existe en la tabla de traduccion		
	beq s2, t3, error;				#si al sumar 1 a s2 me paso del tamaño del array de traduccion, es un error y el caracter no existe
	li s3, 0;

	j search_character;				#contiuno con la busqueda del caracter
		
decode_characters:
	addiu s6, s6, 1;	#sumo una posicion a s6

	#segun el caracter a traducir, elijo que hacer
	li t0, 0;
	beq t0, s7, first_character;
	li t0, 1;
	beq t0, s7, second_character;
	li t0, 2;
	beq t0, s7, third_character;
	li t0, 3;
	beq t0, s7, fourth_character;
	li t0, 4;
	beq t0, s7, write_fd;	#por ultimo escribo en el fd
	j error;				#si llega aca, algo salio mal

write_fd:
	lbu t0, 32($fp);				#cargo el primer caracter	
	sb t0, buffer_traduccion;
	lw a0, 56($fp);					#imprimo en el fd
	la a1, buffer_traduccion;		#cargo la direccion de la direccion de memoria
	li a2, 1;						#el syscall tiene que leer un byte
	li v0,SYS_write
	syscall

	#repito para los otros dos caracteres
	lbu t0, 28($fp); 				#cargo el segundo caracter	
	sb t0, buffer_traduccion;
	la a1, buffer_traduccion;		#cargo la direccion de la direccion de memoria
	li a2, 1;						#el syscall tiene que leer un byte
	li v0,SYS_write
	syscall;

	lbu t0, 24($fp);				#cargo el tercer caracter	
	sb t0, buffer_traduccion;
	la a1, buffer_traduccion;		#cargo la direccion de la direccion de memoria
	li a2, 1;						#el syscall tiene que leer un byte
	li v0,SYS_write
	syscall;

	j decode;

first_character:
	#en s2 tengo la posicion del caracter, lo uso para traducirlo
	move t0, s2;		#guardo el valor en t0 para trabajar tranquilo

	li t1, 2;			#guardo la cantidad de lugares a desplazar
	sll t2, t0, t1;		#shifteo a izquierda dos posiciones, guardo el resultado en t2

	sb t2, 32($fp);		#guardo los primeros 6 bits que me interesan del primer caracter en el SRA
		
	addiu s7, s7, 1;	#decodificado el primer caracter(parcialmente), seteo para que codifique el segundo
	j decode;

second_character:
	#en s2 tengo la posicion del caracter, lo uso para traducirlo
	move t0, s2;	#guardo el valor en t0 para trabajar tranquilo
	li t1, 2;		#guardo la cantidad de lugares a desplazar
	sll t0, t0, t1;	#shifteo a izquierda dos posiciones, guardo el resultado en t0

	li t1, 6;
	srl t0, t0, t1;	#shifteo a derecha 6 posiciones para quedarme con los dos bits que me faltan del primer caracter 

	lbu t2, 32($fp);	#carga en t2 el primer caracter sin los 2 bits finales 
	or t0, t0, t2;	#or logico entre los 6 bits del primer caracter y los primeros 2 bits del segundo
	#ahora en t0 tengo el primer caracter real
	sb t0, 32($fp);	#guardo los 8 bits completos del primer caracter

	move t0, s2;	#recupero el valor original leido a t0
        
	li t1, 4;
	sll t2, t0, t1;	#shifteo 4 posiciones a izquierda para quedarme con los 4 bits que me interesan para el segundo caracter
	sb t2, 28($fp);	#guardo los primeros 4 bits que me interesan del segundo caracter en el SRA

	addiu s7, s7, 1; #decodificado el primer caracter y el segundo parcialmente, seteo para que codifique el tercero
	j decode;

third_character:
	#en s2 tengo la posicion del caracter, lo uso para traducirlo
	move t0, s2;	#guardo el valor en t0 para trabajar tranquilo
	li t1, 2;		#guardo la cantidad de lugares a desplazar
	sll t0, t0, t1;	#shifteo a izquierda dos posiciones, guardo el resultado en t0
		
	li t1, 4;
	srl t0, t0, t1;	#shifteo a derecha 4 posiciones para quedarme con los 4 bits que me faltan del segundo caracter 

	lbu t2, 28($fp);	#carga en t2 el segundo caracter sin los 4 bits finales 
	or t0, t0, t2;		#or logico entre los 4 bits del segundo caracter y los 4 bits del tercero
	#ahora en t0 tengo el segundo caracter real
	sb t0, 28($fp);		#guardo los 8 bits completos del segundo caracter

	move t0, s2;		#recupero el valor original leido a t0
	li t1, 6;
	sll t0, t0, t1;		#shifteo 6 posiciones a izquierda para quedarme con los 2 bits finales que me interesan para el tercer caracter
	sb t2, 24($fp);		#guardo los primeros 2 bits que me interesan del tercer caracter en el SRA

	addiu s7, s7, 1;	#decodificado el primer caracter y el segundo parcialmente, seteo para que codifique el tercero
	j decode;

fourth_character:
	#en s2 tengo la posicion del caracter, lo uso para traducirlo
	move t0, s2;		#guardo el valor en t0 para trabajar tranquilo

	lbu t2, 24($fp);	#carga en t2 el tercer caracter sin los 6 bits finales 
	or t0, t0, t2;		#or logico entre los 2 bits del segundo caracter y los 6 bits del tercero
	
	#ahora en t0 tengo el tercer caracter real
	sb t0, 24($fp);	#guardo los 8 bits completos del segundo caracter

	addiu s7, s7, 1; #decodificado el primer caracter y el segundo parcialmente, seteo para que codifique el tercero
	j write_fd;

end:
	move v0, s3;
	#recupero el stack a su estado anterior y los registros que utilice
	lw gp, 44(sp)
	lw ra, 40(sp)
	lw $fp, 36(sp)
	lw s0, 32(sp)
	lw s1, 28(sp)
	lw s2, 24(sp)
	addu sp, sp, 48
	jr ra

.end base64_decode

.data	#segmento read-only data
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
