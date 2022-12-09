#!/bin/bash
FILE_SRC=$1
FILE_ASM=${1%.*}.s
FILE_DST=${1%.*}

if lua fennec.lua linux_x86_32/target $FILE_SRC $FILE_ASM; then
	if nasm -f elf $FILE_ASM; then
		nasm -f elf linux_x86_32/stdlib.s -o stdlib.o
		ld -nostdlib -o $FILE_DST *.o
		chmod +x $FILE_DST
		rm *.o
	fi
	rm $FILE_ASM
fi
