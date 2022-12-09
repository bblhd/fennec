section .text

global add
global sub
global mul
global imul
global div
global idiv
global mod
global imod

add:
	mov eax, [esp+4]
	add eax, [esp+8]
ret

sub:
	mov eax, [esp+4]
	sub eax, [esp+8]
ret

mul:
	mov eax, [esp+4]
	mul dword [esp+8]
ret

imul:
	mov eax, [esp+4]
	imul dword [esp+8]
ret

div:
	mov edx, 0
	mov eax, [esp+4]
	div dword [esp+8]
ret

idiv:
	mov edx, 0
	mov eax, [esp+4]
	idiv dword [esp+8]
ret

mod:
	mov edx, 0
	mov eax, [esp+4]
	div dword [esp+8]
	mov eax, edx
ret

imod:
	mov edx, 0
	mov eax, [esp+4]
	idiv dword [esp+8]
	mov eax, edx
ret

global bitwiseAnd
bitwiseAnd:
	mov eax, [esp+4]
	and eax, [esp+8]
ret

global bitwiseOr
bitwiseOr:
	mov eax, [esp+4]
	or eax, [esp+8]
ret

global and
and:
	cmp dword [esp+4], 0
	setz al
	dec eax
	and eax, [esp+8]
ret

global or
or:
	mov eax, [esp+4]
	or eax, [esp+8]
ret

global not
not:
	mov eax, [esp+4]
	setz al
	dec eax
ret

global eq
eq:
	mov ebx, [esp+4]
	cmp ebx, [esp+8]
	setz al
ret

global ne
ne:
	mov ebx, [esp+4]
	cmp ebx, [esp+8]
	setz al
	dec eax
ret

global lt
lt:
	mov eax, [esp+4]
	sub eax, [esp+8]
	shr eax, 31
ret

global lte
lte:
	mov eax, [esp+4]
	sub eax, [esp+8]
	dec eax
	shr eax, 31
ret

global gt
gt:
	mov eax, [esp+8]
	sub eax, [esp+4]
	shr eax, 31
ret

global gte
gte:
	mov eax, [esp+8]
	sub eax, [esp+4]
	dec eax
	shr eax, 31
ret

global storeByte
storeByte:
	mov ebx, [esp+8]
	mov eax, [esp+4]
	mov byte [eax], bl
ret

global loadByte
loadByte:
	mov ebx, [esp+4]
	mov eax, 0
	mov al, byte [ebx]
ret

global storeWord
storeWord:
	mov ebx, [esp+8]
	mov eax, [esp+4]
	mov [eax], ebx
ret

global loadWord
loadWord:
	mov ebx, [esp+4]
	mov eax, [ebx]
ret

global open
open:
	mov eax, 5
	mov ebx, dword [esp+4]
	mov ecx, dword [esp+8]
	mov edx, 0
	int 80h
ret

global close
close:
	mov eax, 6
	mov ebx, dword [esp+4]
	int 80h
ret

global read
read:
	mov eax, 3
	mov ebx, dword [esp+4]
	mov ecx, dword [esp+8]
	mov edx, dword [esp+12]
	int 80h
ret

global write
write:
	mov eax, 4
	mov ebx, dword [esp+4]
	mov ecx, dword [esp+8]
	mov edx, dword [esp+12]
	int 80h
ret


global putn
putn:
	mov eax, 4
	mov ebx, 1
	mov ecx, dword [esp+4]
	mov edx, dword [esp+8]
	int 80h
ret

global putc
putc:
	mov eax, 4
	mov ebx, 1
	lea ecx, [esp+4]
	mov edx, 1
	int 80h
ret

global getc
getc:
	push 0
	mov eax, 3
	mov ebx, 0
	lea ecx, [esp]
	mov edx, 1
	int 80h
	mov eax, 0
	pop eax
ret

global exit
exit:
	mov ebx, [esp+4]
	mov eax, 1
	int 80h

extern main

global _start
_start:
	mov ebp, esp
	call main
	mov ebx, eax
	mov eax, 1
	int 80h
