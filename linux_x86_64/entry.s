section .text

extern main

global _start
_start:
	mov rbp, rsp
	call main
	mov rdi, rax
	mov rax, 60
	syscall
