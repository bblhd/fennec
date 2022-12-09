default rel
section .text
extern add
extern sub
extern mul
extern div
extern mod
extern eq
extern ne
extern lt
extern lte
extern gt
extern gte
extern or
extern and
extern not
extern bitwiseOr
extern bitwiseAnd
extern storeWord
extern loadWord
extern storeByte
extern loadByte
extern putc
extern putn
extern getc
extern exit
extern open
extern close
extern read
extern write
global main
main:
push rbp
mov rbp, rsp
sub rsp, 8
lea rax, [rsp+32]
mov [rbp-8], rax
mov rax, 67
push rax
section .data
_s1: db 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 0
section .text
lea rax, qword [_s1]
push rax
mov rax, 13
push rax
section .data
_s0: db 84, 101, 115, 116, 32, 105, 110, 116, 58, 32, 37, 105, 10, 84, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 58, 32, 34, 37, 115, 34, 10, 84, 101, 115, 116, 32, 99, 104, 97, 114, 58, 32, 39, 37, 99, 39, 10, 0
section .text
lea rax, qword [_s0]
push rax
call printf
add rsp, 32
mov rax, 0
mov rsp, rbp
pop rbp
ret
print:
push rbp
mov rbp, rsp
mov rax, [rbp+16]
push rax
call strlen
add rsp, 8
push rax
mov rax, [rbp+16]
push rax
call putn
add rsp, 16
mov rax, 0
mov rsp, rbp
pop rbp
ret
strlen:
push rbp
mov rbp, rsp
sub rsp, 8
mov rax, 0
mov [rbp-8], rax
_j0:
mov rax, [rbp-8]
push rax
mov rax, [rbp+16]
push rax
call add
add rsp, 16
push rax
call loadByte
add rsp, 8
cmp rax, 0
je _j1
mov rax, 1
push rax
mov rax, [rbp-8]
push rax
call add
add rsp, 16
mov [rbp-8], rax
jmp _j0
_j1:
mov rax, [rbp-8]
mov rsp, rbp
pop rbp
ret
mov rax, 0
mov rsp, rbp
pop rbp
ret
scan:
push rbp
mov rbp, rsp
sub rsp, 8
call getc
mov [rbp-8], rax
_j2:
mov rax, 10
push rax
mov rax, [rbp-8]
push rax
call sub
add rsp, 16
cmp rax, 0
je _j3
mov rax, 1
push rax
mov rax, [rbp+24]
push rax
call sub
add rsp, 16
mov [rbp+24], rax
mov rax, [rbp+24]
push rax
mov rax, 0
push rax
call lt
add rsp, 16
cmp rax, 0
je _j4
mov rax, [rbp-8]
push rax
mov rax, [rbp+16]
push rax
call storeByte
add rsp, 16
_j4:
mov rax, 1
push rax
mov rax, [rbp+16]
push rax
call add
add rsp, 16
mov [rbp+16], rax
call getc
mov [rbp-8], rax
jmp _j2
_j3:
mov rax, 0
push rax
mov rax, [rbp+16]
push rax
call storeByte
add rsp, 16
mov rax, 0
mov rsp, rbp
pop rbp
ret
printf:
push rbp
mov rbp, rsp
sub rsp, 8
lea rax, [rsp+32]
mov [rbp-8], rax
_j5:
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
cmp rax, 0
je _j6
mov rax, 37
push rax
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
push rax
call eq
add rsp, 16
cmp rax, 0
je _j7
mov rax, 1
push rax
mov rax, [rbp+16]
push rax
call add
add rsp, 16
mov [rbp+16], rax
mov rax, 115
push rax
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
push rax
call eq
add rsp, 16
cmp rax, 0
je _j8
mov rax, [rbp-8]
push rax
call loadWord
add rsp, 8
push rax
call print
add rsp, 8
mov rax, 8
push rax
mov rax, [rbp-8]
push rax
call add
add rsp, 16
mov [rbp-8], rax
jmp _j9
_j8:
mov rax, 105
push rax
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
push rax
call eq
add rsp, 16
cmp rax, 0
je _j10
mov rax, 10
push rax
mov rax, [rbp-8]
push rax
call loadWord
add rsp, 8
push rax
call printi
add rsp, 16
mov rax, 8
push rax
mov rax, [rbp-8]
push rax
call add
add rsp, 16
mov [rbp-8], rax
jmp _j11
_j10:
mov rax, 99
push rax
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
push rax
call eq
add rsp, 16
cmp rax, 0
je _j12
mov rax, [rbp-8]
push rax
call loadWord
add rsp, 8
push rax
call putc
add rsp, 8
mov rax, 8
push rax
mov rax, [rbp-8]
push rax
call add
add rsp, 16
mov [rbp-8], rax
jmp _j13
_j12:
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
push rax
call putc
add rsp, 8
_j13:
_j11:
_j9:
jmp _j14
_j7:
mov rax, [rbp+16]
push rax
call loadByte
add rsp, 8
push rax
call putc
add rsp, 8
_j14:
mov rax, 1
push rax
mov rax, [rbp+16]
push rax
call add
add rsp, 16
mov [rbp+16], rax
jmp _j5
_j6:
mov rax, 0
mov rsp, rbp
pop rbp
ret
section .bss
printi_buffer: resb 64
section .text
printi:
push rbp
mov rbp, rsp
sub rsp, 16
lea rax, [printi_buffer]
mov [rbp-8], rax
mov rax, 0
push rax
mov rax, [rbp-8]
push rax
call storeByte
add rsp, 16
mov rax, 1
push rax
mov rax, [rbp-8]
push rax
call add
add rsp, 16
mov [rbp-8], rax
_j15:
mov rax, [rbp+24]
push rax
mov rax, [rbp+16]
push rax
call gte
add rsp, 16
cmp rax, 0
je _j16
mov rax, [rbp+24]
push rax
mov rax, [rbp+16]
push rax
call mod
add rsp, 16
mov [rbp-16], rax
mov rax, 10
push rax
mov rax, [rbp-16]
push rax
call lt
add rsp, 16
cmp rax, 0
je _j17
mov rax, 48
push rax
mov rax, [rbp-16]
push rax
call add
add rsp, 16
mov [rbp-16], rax
jmp _j18
_j17:
mov rax, 55
push rax
mov rax, [rbp-16]
push rax
call add
add rsp, 16
mov [rbp-16], rax
_j18:
mov rax, [rbp-16]
push rax
mov rax, [rbp-8]
push rax
call storeByte
add rsp, 16
mov rax, 1
push rax
mov rax, [rbp-8]
push rax
call add
add rsp, 16
mov [rbp-8], rax
mov rax, [rbp+24]
push rax
mov rax, [rbp+16]
push rax
call div
add rsp, 16
mov [rbp+16], rax
jmp _j15
_j16:
mov rax, [rbp+24]
push rax
mov rax, [rbp+16]
push rax
call mod
add rsp, 16
mov [rbp-16], rax
mov rax, 10
push rax
mov rax, [rbp-16]
push rax
call lt
add rsp, 16
cmp rax, 0
je _j19
mov rax, 48
push rax
mov rax, [rbp-16]
push rax
call add
add rsp, 16
mov [rbp-16], rax
jmp _j20
_j19:
mov rax, 55
push rax
mov rax, [rbp-16]
push rax
call add
add rsp, 16
mov [rbp-16], rax
_j20:
mov rax, [rbp-16]
push rax
mov rax, [rbp-8]
push rax
call storeByte
add rsp, 16
_j21:
mov rax, [rbp-8]
push rax
call loadByte
add rsp, 8
cmp rax, 0
je _j22
mov rax, [rbp-8]
push rax
call loadByte
add rsp, 8
push rax
call putc
add rsp, 8
mov rax, 1
push rax
mov rax, [rbp-8]
push rax
call sub
add rsp, 16
mov [rbp-8], rax
jmp _j21
_j22:
mov rax, 0
mov rsp, rbp
pop rbp
ret
