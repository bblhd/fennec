section .text

extern main

global _start
_start:
	mov ebp, esp
	call main
	mov ebx, eax
	mov eax, 1
	int 80h
