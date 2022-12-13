#!/bin/bash

if [ ! -f "$1" ]; then
	echo "Did not provide build script a file, exiting"
	exit
fi

NAME=$1
NAME=${NAME##*/}
NAME=${NAME%.*}

FILE_SRC="$1"
FILE_OBJ="$NAME.o"
FILE_DST="bin/$NAME"

if lua compile.lua -i $FILE_SRC -o $FILE_OBJ -L 'system=./src/sys_bsd_x86_64.fen' -l './src' -p 'macos_x86_64'; then
	mkdir -p bin
	nasm -f macho64 macos_x86_64/entry.s -o entry.o
	ld -macosx_version_min 10.6 -dead_strip_dylibs -o $FILE_DST *.o
	chmod +x $FILE_DST
	rm *.o
fi
