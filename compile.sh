#!/bin/bash

if [ ! -e stdlib.o -o stdlib.s -nt stdlib.o ]; then
	nasm -f elf stdlib.s -o stdlib.o
fi

FILE_SRC=$1
FILE_ASM=${1%.*}.s
FILE_DST=${1%.*}

if lua fennec.lua $FILE_SRC $FILE_ASM; then
	nasm -f elf $FILE_ASM
	rm $FILE_ASM
	ld -nostdlib -o $FILE_DST *.o
	chmod +x $FILE_DST
fi

rm *.o
