
section .text

global add
global sub
global mul
global imul
global div
global idiv
global mod
global imod
global lt

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

lt:
	mov eax, [esp+4]
	sub eax, [esp+8]
	shr eax, 31
ret

global set_byte
set_byte:
	mov ebx, [esp+8]
	mov eax, [esp+4]
	mov byte [eax], bl
ret

global get_byte
get_byte:
	mov ebx, [esp+4]
	mov eax, 0
	mov al, [ebx]
ret

global deref
deref:
	mov ebx, [esp+4]
	mov eax, [ebx]
ret

global printn
printn:
	mov eax, 4
	mov ebx, 1
	mov ecx, dword [esp+4]
	mov edx, dword [esp+8]
	int 80h
ret

global printc
printc:
	mov eax, 4
	mov ebx, 1
	lea ecx, [esp+4]
	mov edx, 1
	int 80h
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
	mov eax, [esp]
	lea ebx, [esp+4]
	mov [esp], ebx
	push eax
	call main
	mov ebx, eax
	mov eax, 1
	int 80h
