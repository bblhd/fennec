#!/bin/bash

if [ ! -f "$1" ]; then
	echo "Did not provide build script a file, exiting"
	exit
fi

FILE_SRC=$1
FILE_OBJ=${1%.*}.o
FILE_DST=${1%.*}

if lua compile.lua -i $FILE_SRC -o $FILE_OBJ -L 'stdlib=macos_x86_64/stdlib.fen' -l './' -p 'macos_x86_64'; then
	mkdir -p bin
	nasm -f macho64 macos_x86_64/stdlib.s -o stdlib.o
	ld -macosx_version_min 10.6 -dead_strip_dylibs -o bin/$FILE_DST *.o
	chmod +x bin/$FILE_DST
	rm *.o
fi