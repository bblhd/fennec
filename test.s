
example.I:
push edi
mov edi, esp
mov eax, [edi+8]
mov edi, [edi]
ret

global example.factorial_recur
example.factorial_recur:
push edi
mov edi, esp
mov eax, 0
mov [esp+4], eax
mov eax, [edi+8]
mov [esp+0], eax
call slt
cmp eax, 0
jne .j0
mov eax, [edi+8]
mov [esp+4], eax
mov esp, ebp
pop ebp
mov esp, ebp
pop ebp
mov eax, [edi+8]
mov [esp+4], eax
mov eax, 1
mov [esp+0], eax
call sub
mov [esp+0], eax
call example.factorial_recur
mov [esp+0], eax
call mul
mov edi, [edi]
ret
.j0:
mov eax, 1
mov edi, [edi]
ret

global example.factorial_iter
example.factorial_iter:
push edi
mov edi, esp
sub esp, 4
mov eax, 1
mov [edi-4], eax
.j0:
mov eax, 0
mov [esp+4], eax
mov eax, [edi+8]
mov [esp+0], eax
call slt
cmp eax, 0
jne .j1
mov eax, [edi-4]
mov [esp+4], eax
mov eax, [edi+8]
mov [esp+0], eax
call mul
mov [edi-4], eax
mov eax, [edi+8]
mov [esp+4], eax
mov eax, 1
mov [esp+0], eax
call sub
mov [edi+8], eax
jmp .j0
.j1:
mov eax, [edi-4]
mov edi, [edi]
ret

global example.fibonacci
example.fibonacci:
push edi
mov edi, esp
sub esp, 12
mov eax, 0
mov [edi-4], eax
mov eax, 1
mov [edi-8], eax
.j0:
mov eax, 0
mov [esp+4], eax
mov eax, [edi+8]
mov [esp+0], eax
call slt
cmp eax, 0
jne .j1
mov eax, [edi-4]
mov [esp+4], eax
mov eax, [edi-8]
mov [esp+0], eax
call add
mov [edi-12], eax
mov eax, [edi-8]
mov [edi-4], eax
mov eax, [edi-12]
mov [edi-8], eax
mov eax, [edi+8]
mov [esp+4], eax
mov eax, 1
mov [esp+0], eax
call sub
mov [edi+8], eax
jmp .j0
.j1:
mov eax, 0
mov edi, [edi]
ret

add:
push edi
mov edi, esp
mov eax, [edi+8]
add eax, [edi+12]
mov edi, [edi]
ret

sub:
push edi
mov edi, esp
mov eax, [edi+8]
sub eax, [edi+12]
mov edi, [edi]
ret

mul:
push edi
mov edi, esp
mov eax, [edi+8]
mul DWORD [edi+12]
mov edi, [edi]
ret

slt:
push edi
mov edi, esp
mov eax, [edi+8]
sub eax, [edi+12]
shr eax, 31
mov edi, [edi]
ret
