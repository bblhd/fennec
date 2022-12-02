
section .text

global add
global sub
global mul
global slt
global printn
global printc

add:
	mov eax, [esp+4]
	add eax, [esp+8]
ret

sub:
	mov eax, [esp+4]
ret

mul:
	mov eax, [esp+4]
	mul dword [esp+8]
ret

slt:
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

printn:
	mov eax, 4
	mov ebx, 1
	mov ecx, dword [esp+4]
	mov edx, dword [esp+8]
	int 80h
ret

printc:
	mov eax, 4
	mov ebx, 1
	lea ecx, [esp+4]
	mov edx, 1
	int 80h
ret

extern main
global _start
_start:
	mov ebp, esp
	call main
	mov ebx, eax
	mov eax, 1
	int 80h
