section .data
    prompt db "Enter filename: ", 0x00
    prompt_len equ $-prompt

section .bss
    buffer resb 1024

section .text
    global _start

_start:
    jmp .get_filename

.get_filename:
    ; print prompt to user
    mov rdi, prompt
    mov rsi, prompt_len
    call print

    ; read user input into buffer
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 1024
    call read
    ; add null terminator to the end of the input
    mov byte [buffer + rax - 1], 0x00

    ; open the file specified by the user
    mov rdi, buffer
    call open
    cmp rax, 0
    jl .exit

    ; read file contents into buffer
    mov rdi, rax
    mov rsi, buffer
    mov rdx, 1024
    call read

    ; print file contents to stdout
    mov rdi, buffer
    mov rsi, rax ; number of bytes read
    call print

    jmp .exit

.exit:
    ; exit code 0
    mov rax, 60
    xor rdi, rdi
    syscall

open:
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    ret

read:
    ; read from fd in rdi into buffer at rsi with size rdx
    mov rax, 0
    syscall
    ret

print:
    ; write to stdout (fd 1) from buffer
    mov rdx, rsi
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall
    ret