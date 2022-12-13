section .text

global storeByte
storeByte:
	mov ebx, [esp+8]
	mov eax, [esp+4]
	mov byte [eax], bl
ret

global loadByte
loadByte:
	mov ebx, [esp+4]
	mov eax, 0
	mov al, byte [ebx]
ret

global storeWord
storeWord:
	mov ebx, [esp+8]
	mov eax, [esp+4]
	mov [eax], ebx
ret

global loadWord
loadWord:
	mov ebx, [esp+4]
	mov eax, [ebx]
ret

extern main

global _start
_start:
	mov ebp, esp
	call main
	mov ebx, eax
	mov eax, 1
	int 80h
