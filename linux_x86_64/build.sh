#!/bin/bash

if [ ! -f $1 ]; then
	echo "Did not provide build script a file, exiting"
	exit
fi

NAME=$1
NAME=${NAME##*/}
NAME=${NAME%.*}

FILE_SRC="$1"
FILE_OBJ="$NAME.o"
FILE_DST="bin/$NAME"

if lua compile.lua -i $FILE_SRC -o $FILE_OBJ -l './linux_x86_64' -l './examples' -p 'linux_x86_64'; then
	mkdir -p bin
	nasm -f elf64 linux_x86_64/entry.s -o entry.o
	ld -nostdlib -o $FILE_DST *.o
	chmod +x $FILE_DST
	rm *.o
fi
