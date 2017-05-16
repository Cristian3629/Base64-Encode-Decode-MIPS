#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <stdbool.h>
#include <unistd.h>
//#include "base64_encode.S"
//#include "base64_decode.S"

extern int base64_encode(int infd,int outfd);
extern int base64_decode(int infd,int outfd);

void help() {
        printf( "Usage:\n"
                        " tp0 -h\n"
                        " tp0 -V\n"
                        " tp0 [options]\n"
                        "Options:\n"
                        " -V, --version         Print version and quit.\n"
                        " -h, --help            Print this information.\n"
                        " -i, --input           Location of the input file.\n"
                        " -o, --output          Location of the output file.\n"
                        " -a, --action          Program action: encode (default) or decode.\n"
                        "Examples:\n"
                        " tp0 -a encode -i ~/input -o ~/output\n"
                        " tp0 -a decode\n");
}

void version() {
        printf("Encoder/Decoder Base64 | MIPS Version\n"
                "66.20 Organizacion de Computadoras FIUBA\n"
                );
}


FILE* fileOpen(char* nombre){
        FILE* fp = fopen(nombre,"rb");
        if (fp == NULL){
                //Si el archivo no exite lo creo
                fp = fopen(nombre, "wb");
                //fputs("El archivo no existe o no puede ser abierto.\n",stderr);
                //exit(1);
        }
        return fp;
}

//Abro el archivo de nombre fileName y devuelvo el fd.
//El archivo queda ABIERTO.
int getfd(char* fileName){
        FILE* file = fileOpen(fileName);
        return fileno(file);
}

void charCopy(char** ch1,char* ch2){
        *ch1 = malloc(strlen(ch2)+1);
        (*ch1)[strlen(ch2)] = '\0';
        strcat(*ch1,ch2);
}


int main (int argc, char *argv[]) {
        bool encode64 = true; //Por defecto se encodifica
        bool stdinB = true;
        bool stdoutB = true;
        char* outputFileName = NULL;
        char* inputFileName = NULL;
        int c;
        while (1) {
                static struct option long_options[] = {
                                {"version", no_argument, 0, 'V'},
                                {"help", no_argument, 0, 'h'},
                                {"input", required_argument, 0, 'i'},
                                {"output", required_argument, 0, 'o'},
                                {"action", optional_argument, 0, 'a'},
                                {0, 0, 0, 0}
                };

                int option_index = 0;
                c = getopt_long (argc, argv, "Vhi:o:a:",
                long_options, &option_index);
                if (c == -1)
                break;
                                switch (c) {
                        case 'V':
                                version();
                                break;
                        case 'h':
                                help();
                                break;
                        case 'i':
                                stdinB = false;
                                charCopy(&inputFileName,optarg);
                                break;
                        case 'o':
                                stdoutB = false;
                                charCopy(&outputFileName,optarg);
                                break;
                        case 'a':
                                if(strcmp(optarg,"decode") == 0){
                                        encode64 = false;
                                }
                        break;
                        case '?':
                                break;
                        default:
                                abort();
                }
        }

        //fd de STDIN es 0
        int infd = 0;
        //fd de STDOUT es 1
        int outfd = 1;
        //Si no leo de STDIN, obtengo el fd del archivo.
        if(!stdinB){
                infd = getfd(inputFileName);
        }
        if(!stdoutB){
                outfd = getfd(outputFileName);
        }
        if (encode64){
                base64_encode(infd,outfd);
        }else{
                base64_decode(infd, outfd);
        }
        return 0;
}
