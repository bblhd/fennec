
_start:
push ebp
mov ebp, rsp
mov eax, 0
mov esp, ebp
pop ebp
ret

example.I:
push ebp
mov ebp, rsp
mov eax, [ebp+8]
mov esp, ebp
pop ebp
ret

.globl example.factorial_recur
example.factorial_recur:
push ebp
mov ebp, rsp
sub esp, 8
mov eax, 0
mov [esp], eax
mov eax, [ebp+8]
mov [esp], eax
call slt
add esp, 8
cmp eax, 0
jne .j1
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
sub esp, 4
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, 1
mov [esp], eax
call sub
add esp, 8
mov [esp], eax
call example.factorial_recur
add esp, 4
mov [esp], eax
call mul
add esp, 8
mov esp, ebp
pop ebp
ret
.j1:
mov eax, 1
mov esp, ebp
pop ebp
ret

.globl example.factorial_iter
example.factorial_iter:
push ebp
mov ebp, rsp
sub rsp, rsp, 4
mov eax, 1
mov [ebp-4], eax
sub esp, 8
mov eax, 0
mov [esp], eax
mov eax, [ebp+8]
mov [esp], eax
call slt
add esp, 8
.j1:
cmp eax, 0
jne .j2
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, [ebp+8]
mov [esp], eax
call mul
add esp, 8
mov [ebp-4], eax
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, 1
mov [esp], eax
call sub
add esp, 8
mov [ebp+8], eax
jmp .j1
.j2:
mov eax, [ebp-4]
mov esp, ebp
pop ebp
ret

.globl example.fibonacci
example.fibonacci:
push ebp
mov ebp, rsp
sub rsp, rsp, 12
mov eax, 0
mov [ebp-4], eax
mov eax, 1
mov [ebp-8], eax
sub esp, 8
mov eax, 0
mov [esp], eax
mov eax, [ebp+8]
mov [esp], eax
call slt
add esp, 8
.j1:
cmp eax, 0
jne .j2
sub esp, 8
mov eax, [ebp-4]
mov [esp], eax
mov eax, [ebp-8]
mov [esp], eax
call add
add esp, 8
mov [ebp-12], eax
mov eax, [ebp-8]
mov [ebp-4], eax
mov eax, [ebp-12]
mov [ebp-8], eax
sub esp, 8
mov eax, [ebp+8]
mov [esp], eax
mov eax, 1
mov [esp], eax
call sub
add esp, 8
mov [ebp+8], eax
jmp .j1
.j2:
mov eax, [ebp-4]
mov esp, ebp
pop ebp
ret

add:
push ebp
mov ebp, rsp
mov eax, [ebp+8]
add eax, [ebp+12]
mov esp, ebp
pop ebp
ret

sub:
push ebp
mov ebp, rsp
x86
