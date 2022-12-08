section .text
extern add
extern sub
extern mul
extern div
extern mod
extern lt
extern lte
extern gt
extern gte
extern or
extern and
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
sub esp, 12
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call gt
add esp, 8
cmp eax, 0
je _jump0
sub esp, 8
sub esp, 4
sub esp, 8
mov eax, [ebp+12]
mov [esp], eax
mov eax, 4
mov [esp+4], eax
call add
add esp, 8
mov [esp], eax
call loadWord
add esp, 4
mov [esp], eax
mov eax, 0
mov [esp+4], eax
call open
add esp, 8
mov [ebp-4], eax
mov eax, 64
sub esp, eax
mov [ebp-8], esp
mov eax, 1
mov [ebp-12], eax
_jump1:
mov eax, [ebp-12]
cmp eax, 0
je _jump2
sub esp, 12
mov eax, [ebp-4]
mov [esp], eax
mov eax, [ebp-8]
mov [esp+4], eax
mov eax, 64
mov [esp+8], eax
call read
add esp, 12
mov [ebp-12], eax
sub esp, 8
mov eax, [ebp-8]
mov [esp], eax
mov eax, [ebp-12]
mov [esp+4], eax
call putn
add esp, 8
jmp _jump1
_jump2:
sub esp, 4
mov eax, [ebp-4]
mov [esp], eax
call close
add esp, 4
mov eax, 0
mov esp, ebp
pop ebp
ret
_jump0:
mov eax, 1
mov esp, ebp
pop ebp
ret
mov esp, ebp
pop ebp
ret
print:
push ebp
mov ebp, esp
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
sub esp, 4
mov eax, [ebp+8]
mov [esp], eax
call strlen
add esp, 4
mov [esp+4], eax
call putn
add esp, 8
mov esp, ebp
pop ebp
ret
strlen:
push ebp
mov ebp, esp
sub esp, 4
mov eax, 0
mov [ebp-4], eax
_jump3:
sub esp, 4
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, [ebp-4]
mov [esp+4], eax
call add
add esp, 8
mov [esp], eax
call loadByte
add esp, 4
cmp eax, 0
je _jump4
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call add
add esp, 8
mov [ebp-4], eax
jmp _jump3
_jump4:
mov eax, [ebp-4]
mov esp, ebp
pop ebp
ret
mov esp, ebp
pop ebp
ret
scan:
push ebp
mov ebp, esp
sub esp, 4
sub esp, 0
call getc
add esp, 0
mov [ebp-4], eax
_jump5:
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 10
mov [esp+4], eax
call sub
add esp, 8
cmp eax, 0
je _jump6
sub esp, 8
mov eax, [ebp+12]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call sub
add esp, 8
mov [ebp+12], eax
sub esp, 8
mov eax, 0
mov [esp], eax
mov eax, [ebp+12]
mov [esp+4], eax
call lt
add esp, 8
cmp eax, 0
je _jump7
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, [ebp-4]
mov [esp+4], eax
call storeByte
add esp, 8
_jump7:
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call add
add esp, 8
mov [ebp+8], eax
sub esp, 0
call getc
add esp, 0
mov [ebp-4], eax
jmp _jump5
_jump6:
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, 0
mov [esp+4], eax
call storeByte
add esp, 8
mov esp, ebp
pop ebp
ret
