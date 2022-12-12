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
	mov rax, [rsp+8]
	add rax, [rsp+16]
ret

sub:
	mov rax, [rsp+8]
	sub rax, [rsp+16]
ret

mul:
	mov rax, [rsp+8]
	mul dword [rsp+16]
ret

imul:
	mov rax, [rsp+8]
	imul dword [rsp+16]
ret

div:
	mov rdx, 0
	mov rax, [rsp+8]
	div dword [rsp+16]
ret

idiv:
	mov rdx, 0
	mov rax, [rsp+8]
	idiv dword [rsp+16]
ret

mod:
	mov rdx, 0
	mov rax, [rsp+8]
	div dword [rsp+16]
	mov rax, rdx
ret

imod:
	mov rdx, 0
	mov rax, [rsp+8]
	idiv dword [rsp+16]
	mov rax, rdx
ret

global lsr
lsr:
	mov rax, [rsp+8]
	mov cl, [rsp+16]
	shr rax, cl
ret

global lsl
lsl:
	mov rax, [rsp+8]
	mov cl, [rsp+16]
	shl rax, cl
ret

global bitwiseAnd
bitwiseAnd:
	mov rax, [rsp+8]
	and rax, [rsp+16]
ret

global bitwiseOr
bitwiseOr:
	mov rax, [rsp+8]
	or rax, [rsp+16]
ret

global and
and:
	cmp dword [rsp+8], 0
	mov rax, 0
	setz al
	dec rax
	and rax, [rsp+16]
ret

global or
or:
	mov rax, [rsp+8]
	or rax, [rsp+16]
ret

global not
not:
	cmp dword [rsp+8], 0
	mov rax, 0
	setz al
ret

global eq
eq:
	mov rax, [rsp+8]
	cmp rax, [rsp+16]
	mov rax, 0
	setz al
ret

global ne
ne:
	mov rax, [rsp+8]
	cmp rax, [rsp+16]
	mov rax, 0
	setz al
	dec rax
ret

global lt
lt:
	mov rax, [rsp+8]
	sub rax, [rsp+16]
	shr rax, 63
ret

global lte
lte:
	mov rax, [rsp+8]
	sub rax, [rsp+16]
	dec rax
	shr rax, 63
ret

global gt
gt:
	mov rax, [rsp+16]
	sub rax, [rsp+8]
	shr rax, 63
ret

global gte
gte:
	mov rax, [rsp+16]
	sub rax, [rsp+8]
	dec rax
	shr rax, 63
ret

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

global open
open:
	mov rax, 2
	mov rdi, [rsp+8]
	mov rsi, [rsp+16]
	mov rdx, 0
	syscall
ret

global close
close:
	mov rax, 3
	mov rdi, [rsp+8]
	syscall
ret

global read
read:
	mov rax, 0
	mov rdi, [rsp+8]
	mov rsi, [rsp+16]
	mov rdx, [rsp+24]
	syscall
ret

global write
write:
	mov rax, 1
	mov rdi, [rsp+8]
	mov rsi, [rsp+16]
	mov rdx, [rsp+24]
	syscall
ret

global getc
getc:
	push 0
	mov rax, 0
	mov rdi, 0
	lea rsi, [rsp]
	mov rdx, 1
	syscall
	pop rax
ret

global putc
putc:
	mov rax, 1
	mov rdi, 1
	lea rsi, [rsp+8]
	mov rdx, 1
	syscall
ret

global putn
putn:
	mov rax, 1
	mov rdi, 1
	mov rsi, [rsp+8]
	mov rdx, [rsp+16]
	syscall
ret

global exit
exit:
	mov rax, 60
	mov rdi, [rsp+8]
	syscall

extern main

global _start
_start:
	mov rbp, rsp
	call main
	mov rdi, rax
	mov rax, 60
	syscall
