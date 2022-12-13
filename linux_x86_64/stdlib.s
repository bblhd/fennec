section .text

global storeByte
storeByte:
	mov rbx, [rsp+16]
	mov rax, [rsp+8]
	mov byte [rax], bl
ret

global loadByte
loadByte:
	mov rbx, [rsp+8]
	mov rax, 0
	mov al, byte [rbx]
ret

global storeWord
storeWord:
	mov rax, [rsp+16]
	mov rbx, [rsp+8]
	mov [rbx], rax
ret

global loadWord
loadWord:
	mov rbx, [rsp+8]
	mov rax, [rbx]
ret

extern main

global _start
_start:
	mov rbp, rsp
	call main
	mov rdi, rax
	mov rax, 60
	syscall
