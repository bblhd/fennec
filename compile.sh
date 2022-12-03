FILE_SRC=$1
FILE_ASM=${FILE_SRC%.*}.s
FILE_OBJ=${FILE_ASM%.*}.o
FILE_DST=${FILE_OBJ%.*}
if [ ! -e stdlib.s ] || [ stdlib.s -nt stdlib.o ]; then
	nasm -f elf stdlib.s
fi
lua fennec.lua $FILE_SRC > $FILE_ASM
nasm -f elf $FILE_ASM
ld -nostdlib -o $FILE_DST $FILE_OBJ stdlib.o
#rm $FILE_ASM $FILE_OBJ
chmod +x $FILE_DST
