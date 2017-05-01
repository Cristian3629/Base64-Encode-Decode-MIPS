# Base64-Encode-Decode-MIPS

Trábajo Practico De Organización de Computadoras de la Facultad de Ingenieria de la UBA. 2017 1° Cuatrimestre

## Introducción 

Se debe codificar el algoritmo de decodificación y encodificación base64 en Assembly Arquitectura MIPS.

## Archivos 

* tp0.c
* base64_encode.S
* base64_decode.S
* getBytesFromFile.S

## Funciones

* main() : Se encarga de abrir los archivos correspondientes.
* base64_encode(int infd,int outfd): Se encarga de encodificar el archivo input y escribir el resultado en el archivo output.
* base64_decode(int infd,int outfd): Se encarga de decodificar el archivo input y escribir el resultado en el archivo output.
* getBytesFromFile(int fd, int bytes): Dado un fd y bytes, te devuelve N bytes del archivo.
