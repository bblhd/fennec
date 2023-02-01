section .text

extern main

global start
start:
	mov rbp, rsp
	call main
	mov rdi, rax
	mov rax, 0x2000001
	syscall
