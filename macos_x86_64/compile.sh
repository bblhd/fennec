#!/bin/bash
FILE_SRC=$1
FILE_ASM=${1%.*}.s
FILE_DST=${1%.*}

if lua fennec.lua 'macos_x86_64' $FILE_SRC $FILE_ASM; then
	if nasm -f macho64 $FILE_ASM; then
		nasm -f macho64 macos_x86_64/stdlib.s -o stdlib.o
		ld -macosx_version_min 10.6 -dead_strip_dylibs -o $FILE_DST *.o
		chmod +x $FILE_DST
		rm *.o
	fi
	# rm $FILE_ASM
fi
