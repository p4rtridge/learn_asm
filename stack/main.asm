section .data
    msg db "Current RSP: 0x"
    msg_len equ $ - msg
    newline db 10             ; ASCII for newline (\n)

section .bss
    hex_buffer resb 16        ; 64-bit number = 16 hex digits

section .text
    global _start

_start:
    call print_rsp

    ; Exit the program
    mov rax, 60               ; sys_exit
    xor rdi, rdi              ; status 0
    syscall

print_rsp:
    lea rax, [rsp + 8]
    mov rcx, 16               ; Loop 16 times (for 16 hex digits)
    mov rdi, hex_buffer + 15  ; Point rdi to the END of our buffer (we fill right-to-left)

.hex_loop:
    mov rdx, rax
    and rdx, 0xF              ; Mask all but the lowest 4 bits (1 nibble)

    ; Convert the number (0-15) to ASCII character ('0'-'9' or 'A'-'F')
    cmp dl, 9
    jbe .is_digit             ; If it's 0-9, jump to is_digit
    add dl, 55                ; Convert 10-15 to ASCII 'A'-'F' (10 + 55 = 65 = 'A')
    jmp .store

.is_digit:
    add dl, 48                ; Convert 0-9 to ASCII '0'-'9' (0 + 48 = 48 = '0')

.store:
    mov byte [rdi], dl        ; Store the ASCII character in the buffer
    dec rdi                   ; Move pointer one byte to the left
    shr rax, 4                ; Shift our original number right by 4 bits
    loop .hex_loop            ; Decrement rcx, jump to top if not 0

    ; Print "Current RSP: 0x"
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, msg
    mov rdx, msg_len
    syscall

    ; Print the 16-character hex string we just generated
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, hex_buffer
    mov rdx, 16               ; 16 bytes long
    syscall

    ; Print newline
    mov rax, 1                ; sys_write
    mov rdi, 1                ; stdout
    mov rsi, newline
    mov rdx, 1
    syscall

    ret