section .data
    hello db 'Hello, World!', 0x0A, 0
    hello_len equ $ - hello

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel hello]
    mov rdx, hello_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall