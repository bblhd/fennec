#!/bin/bash
FILE_SRC=$1
FILE_OBJ=${1%.*}.o
FILE_DST=${1%.*}

if lua fennec.lua -i $FILE_SRC -o $FILE_OBJ -L 'stdlib=linux_x86_32/stdlib.fen' -l './' -p 'linux_x86_32'; then
	mkdir -p bin
	nasm -f elf linux_x86_32/stdlib.s -o stdlib.o
	ld -nostdlib -o bin/$FILE_DST *.o
	chmod +x bin/$FILE_DST
	rm *.o
fi
