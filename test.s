section .text
extern add
extern sub
extern mul
extern div
extern mod
extern lt
extern deref
extern set_byte
extern get_byte
extern printc
extern printn
extern exit
mov esp, ebp
pop ebp
ret
mov esp, ebp
pop ebp
ret
mov esp, ebp
pop ebp
ret
global main
main:
push ebp
mov ebp, esp
sub esp, 8
mov eax, 1
mov [esp], eax
mov eax, [ebp+8]
mov [esp+4], eax
call lt
add esp, 8
cmp eax, 0
je _jump0
sub esp, 4
section .data
_string0: db 72, 101, 108, 108, 111, 32, 0
section .text
lea eax, [_string0]
mov [esp], eax
call print
add esp, 4
sub esp, 4
sub esp, 4
sub esp, 8
mov eax, [ebp+12]
mov [esp], eax
mov eax, 4
mov [esp+4], eax
call add
add esp, 8
mov [esp], eax
call deref
add esp, 4
mov [esp], eax
call print
add esp, 4
sub esp, 4
section .data
_string1: db 33, 10, 0
section .text
lea eax, [_string1]
mov [esp], eax
call print
add esp, 4
jmp _jump1
_jump0:
sub esp, 4
section .data
_string2: db 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33, 10, 0
section .text
lea eax, [_string2]
mov [esp], eax
call print
add esp, 4
_jump1:
mov eax, 0
mov esp, ebp
pop ebp
ret
mov esp, ebp
pop ebp
ret
strlen:
push ebp
mov ebp, esp
sub esp, 4
mov eax, 0
mov [ebp-4], eax
_jump2:
sub esp, 4
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, [ebp-4]
mov [esp+4], eax
call add
add esp, 8
mov [esp], eax
call get_byte
add esp, 4
cmp eax, 0
je _jump3
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call add
add esp, 8
mov [ebp-4], eax
jmp _jump2
_jump3:
mov eax, [ebp-4]
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
call printn
add esp, 8
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
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 0
mov [esp+4], eax
call set_byte
add esp, 8
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call add
add esp, 8
mov [ebp-4], eax
_jump4:
sub esp, 8
sub esp, 8
mov eax, [ebp+12]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call sub
add esp, 8
mov [esp], eax
mov eax, [ebp+8]
mov [esp+4], eax
call lt
add esp, 8
cmp eax, 0
je _jump5
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, [ebp+12]
mov [esp+4], eax
call mod
add esp, 8
mov [ebp-8], eax
sub esp, 8
mov eax, [ebp-8]
mov [esp], eax
mov eax, 10
mov [esp+4], eax
call lt
add esp, 8
cmp eax, 0
je _jump6
sub esp, 8
mov eax, [ebp-8]
mov [esp], eax
mov eax, 48
mov [esp+4], eax
call add
add esp, 8
mov [ebp-8], eax
jmp _jump7
_jump6:
sub esp, 8
mov eax, [ebp-8]
mov [esp], eax
mov eax, 55
mov [esp+4], eax
call add
add esp, 8
mov [ebp-8], eax
_jump7:
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, [ebp-8]
mov [esp+4], eax
call set_byte
add esp, 8
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call add
add esp, 8
mov [ebp-4], eax
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, [ebp+12]
mov [esp+4], eax
call div
add esp, 8
mov [ebp+8], eax
jmp _jump4
_jump5:
_jump8:
sub esp, 4
mov eax, [ebp-4]
mov [esp], eax
call get_byte
add esp, 4
cmp eax, 0
je _jump9
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call sub
add esp, 8
mov [ebp-4], eax
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, 1
mov [esp+4], eax
call printn
add esp, 8
jmp _jump8
_jump9:
mov esp, ebp
pop ebp
ret
