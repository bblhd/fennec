FILE_SRC=$1
FILE_ASM=${FILE_SRC%.*}.s
FILE_OBJ=${FILE_ASM%.*}.o
FILE_DST=${FILE_OBJ%.*}
if [ ! -e stdlib.s ] || [ stdlib.s -nt stdlib.o ]; then
	#echo nasm -f elf stdlib.s
	nasm -f elf stdlib.s
fi
#echo "lua fennec.lua $FILE_SRC > $FILE_ASM"
lua fennec.lua $FILE_SRC > $FILE_ASM
#echo nasm -f elf $FILE_ASM
nasm -f elf $FILE_ASM
#echo ld -nostdlib -o $FILE_DST $FILE_OBJ stdlib.o
ld -nostdlib -o $FILE_DST $FILE_OBJ stdlib.o
#cat $FILE_ASM
rm $FILE_ASM $FILE_OBJ
chmod +x $FILE_DST
