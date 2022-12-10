#!/bin/bash
FILE_SRC=$1
FILE_ASM=${1%.*}.s
FILE_DST=${1%.*}

if lua fennec.lua -i $FILE_SRC -o $FILE_OBJ -L 'stdlib=linux_x86_32/stdlib.fen' -l './' -p 'linux_x86_32'; then
	nasm -f elf linux_x86_32/stdlib.s -o stdlib.o
	ld -nostdlib -o $FILE_DST *.o
	chmod +x $FILE_DST
	rm *.o
fi
