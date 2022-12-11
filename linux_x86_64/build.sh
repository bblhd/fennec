#!/bin/bash

if [ ! -f $1 ]; then
	echo "Did not provide build script a file, exiting"
	exit
fi

FILE_SRC=$1
FILE_OBJ=${1%.*}.o
FILE_DST=${1%.*}

if lua compile.lua -i $FILE_SRC -o $FILE_OBJ -L 'stdlib=linux_x86_64/stdlib.fen' -l './' -p 'linux_x86_64'; then
	mkdir -p bin
	nasm -f elf64 linux_x86_64/stdlib.s -o stdlib.o
	ld -nostdlib -o bin/$FILE_DST *.o
	chmod +x bin/$FILE_DST
	rm *.o
fi
