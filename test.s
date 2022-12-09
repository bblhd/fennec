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
push ebp
mov ebp, esp
sub esp, 4
lea eax, [ebp+12]
mov [ebp-4], eax
mov eax, 67
push eax
section .data
_string1: db 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 0
section .text
lea eax, [_string1]
push eax
mov eax, 13
push eax
section .data
_string0: db 84, 101, 115, 116, 32, 105, 110, 116, 58, 32, 37, 105, 10, 84, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 58, 32, 34, 37, 115, 34, 10, 84, 101, 115, 116, 32, 99, 104, 97, 114, 58, 32, 39, 37, 99, 39, 10, 0
section .text
lea eax, [_string0]
push eax
call printf
add esp, 16
mov eax, 0
push eax
call exit
add esp, 4
mov eax, 0
mov esp, ebp
pop ebp
ret
print:
push ebp
mov ebp, esp
mov eax, [ebp+8]
push eax
call strlen
add esp, 4
push eax
mov eax, [ebp+8]
push eax
call putn
add esp, 8
mov eax, 0
mov esp, ebp
pop ebp
ret
strlen:
push ebp
mov ebp, esp
sub esp, 4
mov eax, 0
mov [ebp-4], eax
_jump0:
mov eax, [ebp-4]
push eax
mov eax, [ebp+8]
push eax
call add
add esp, 8
push eax
call loadByte
add esp, 4
cmp eax, 0
je _jump1
mov eax, 1
push eax
mov eax, [ebp-4]
push eax
call add
add esp, 8
mov [ebp-4], eax
jmp _jump0
_jump1:
mov eax, [ebp-4]
mov esp, ebp
pop ebp
ret
mov eax, 0
mov esp, ebp
pop ebp
ret
scan:
push ebp
mov ebp, esp
sub esp, 4
call getc
mov [ebp-4], eax
_jump2:
mov eax, 10
push eax
mov eax, [ebp-4]
push eax
call sub
add esp, 8
cmp eax, 0
je _jump3
mov eax, 1
push eax
mov eax, [ebp+12]
push eax
call sub
add esp, 8
mov [ebp+12], eax
mov eax, [ebp+12]
push eax
mov eax, 0
push eax
call lt
add esp, 8
cmp eax, 0
je _jump4
mov eax, [ebp-4]
push eax
mov eax, [ebp+8]
push eax
call storeByte
add esp, 8
_jump4:
mov eax, 1
push eax
mov eax, [ebp+8]
push eax
call add
add esp, 8
mov [ebp+8], eax
call getc
mov [ebp-4], eax
jmp _jump2
_jump3:
mov eax, 0
push eax
mov eax, [ebp+8]
push eax
call storeByte
add esp, 8
mov eax, 0
mov esp, ebp
pop ebp
ret
printf:
push ebp
mov ebp, esp
sub esp, 4
lea eax, [ebp+12]
mov [ebp-4], eax
_jump5:
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
cmp eax, 0
je _jump6
mov eax, 37
push eax
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
push eax
call eq
add esp, 8
cmp eax, 0
je _jump7
mov eax, 1
push eax
mov eax, [ebp+8]
push eax
call add
add esp, 8
mov [ebp+8], eax
mov eax, 115
push eax
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
push eax
call eq
add esp, 8
cmp eax, 0
je _jump8
mov eax, [ebp-4]
push eax
call loadWord
add esp, 4
push eax
call print
add esp, 4
mov eax, 4
push eax
mov eax, [ebp-4]
push eax
call add
add esp, 8
mov [ebp-4], eax
jmp _jump9
_jump8:
mov eax, 105
push eax
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
push eax
call eq
add esp, 8
cmp eax, 0
je _jump10
mov eax, 10
push eax
mov eax, [ebp-4]
push eax
call loadWord
add esp, 4
push eax
call printi
add esp, 8
mov eax, 4
push eax
mov eax, [ebp-4]
push eax
call add
add esp, 8
mov [ebp-4], eax
jmp _jump11
_jump10:
mov eax, 99
push eax
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
push eax
call eq
add esp, 8
cmp eax, 0
je _jump12
mov eax, [ebp-4]
push eax
call loadWord
add esp, 4
push eax
call putc
add esp, 4
mov eax, 4
push eax
mov eax, [ebp-4]
push eax
call add
add esp, 8
mov [ebp-4], eax
jmp _jump13
_jump12:
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
push eax
call putc
add esp, 4
_jump13:
_jump11:
_jump9:
jmp _jump14
_jump7:
mov eax, [ebp+8]
push eax
call loadByte
add esp, 4
push eax
call putc
add esp, 4
_jump14:
mov eax, 1
push eax
mov eax, [ebp+8]
push eax
call add
add esp, 8
mov [ebp+8], eax
jmp _jump5
_jump6:
mov eax, 0
mov esp, ebp
pop ebp
ret
printi:
push ebp
mov ebp, esp
sub esp, 8
mov eax, 16
sub esp, eax
mov [ebp-4], esp
mov eax, 0
push eax
mov eax, [ebp-4]
push eax
call storeByte
add esp, 8
mov eax, 1
push eax
mov eax, [ebp-4]
push eax
call add
add esp, 8
mov [ebp-4], eax
_jump15:
mov eax, [ebp+12]
push eax
mov eax, [ebp+8]
push eax
call gte
add esp, 8
cmp eax, 0
je _jump16
mov eax, [ebp+12]
push eax
mov eax, [ebp+8]
push eax
call mod
add esp, 8
mov [ebp-8], eax
mov eax, 10
push eax
mov eax, [ebp-8]
push eax
call lt
add esp, 8
cmp eax, 0
je _jump17
mov eax, 48
push eax
mov eax, [ebp-8]
push eax
call add
add esp, 8
mov [ebp-8], eax
jmp _jump18
_jump17:
mov eax, 55
push eax
mov eax, [ebp-8]
push eax
call add
add esp, 8
mov [ebp-8], eax
_jump18:
mov eax, [ebp-8]
push eax
mov eax, [ebp-4]
push eax
call storeByte
add esp, 8
mov eax, 1
push eax
mov eax, [ebp-4]
push eax
call add
add esp, 8
mov [ebp-4], eax
mov eax, [ebp+12]
push eax
mov eax, [ebp+8]
push eax
call div
add esp, 8
mov [ebp+8], eax
jmp _jump15
_jump16:
mov eax, [ebp+12]
push eax
mov eax, [ebp+8]
push eax
call mod
add esp, 8
mov [ebp-8], eax
mov eax, 10
push eax
mov eax, [ebp-8]
push eax
call lt
add esp, 8
cmp eax, 0
je _jump19
mov eax, 48
push eax
mov eax, [ebp-8]
push eax
call add
add esp, 8
mov [ebp-8], eax
jmp _jump20
_jump19:
mov eax, 55
push eax
mov eax, [ebp-8]
push eax
call add
add esp, 8
mov [ebp-8], eax
_jump20:
mov eax, [ebp-8]
push eax
mov eax, [ebp-4]
push eax
call storeByte
add esp, 8
_jump21:
mov eax, [ebp-4]
push eax
call loadByte
add esp, 4
cmp eax, 0
je _jump22
mov eax, [ebp-4]
push eax
call loadByte
add esp, 4
push eax
call putc
add esp, 4
mov eax, 1
push eax
mov eax, [ebp-4]
push eax
call sub
add esp, 8
mov [ebp-4], eax
jmp _jump21
_jump22:
mov eax, 0
mov esp, ebp
pop ebp
ret
