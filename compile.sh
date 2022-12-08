#!/bin/bash

if [ ! -e stdlib.o -o stdlib.s -nt stdlib.o ]; then
	nasm -f elf stdlib.s -o stdlib.o
fi

FILE_SRC=$1
FILE_ASM=${1%.*}.s
FILE_DST=${1%.*}

lua fennec.lua $FILE_SRC > $FILE_ASM
nasm -f elf $FILE_ASM
ld -nostdlib -o $FILE_DST *.o
#rm $FILE_ASM *.o
chmod +x $FILE_DST
