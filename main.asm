; declare initialized data here
section .data
    sockaddr_in:
        dw 2 ; sin_family: AF_INET (IPv4)
        dw 0x901F ; sin_port: htons(8080)
        dd 0 ; sin_addr: INADDR_ANY
        dq 0 ; sin_zero: padding
    sockaddr_in_len equ $-sockaddr_in

    listen_backlog db 5

    listen_msg db "Listening on port 8080...", 0x0A, 0x00
    listen_msg_len equ $-listen_msg

    accept_msg db "Client connected!", 0x0A, 0x00
    accept_msg_len equ $-accept_msg

; reserve space for variables here
section .bss
    buffer resb 1024
    pollfds resb 16 ; struct pollfd[2]

; declare functions here
section .text
    global _main

; entry point of the program
_main:
    call socket
    mov r8, rax ; store socket fd in r8

    mov rdi, r8
    mov rsi, sockaddr_in
    mov rdx, sockaddr_in_len
    call bind

    mov rdi, listen_msg
    mov rsi, listen_msg_len
    call print

    mov rdi, r8
    mov rsi, listen_backlog
    call listen

    mov rdi, r8
    call accept
    mov r9, rax ; store client socket fd in r9

    mov rdi, accept_msg
    mov rsi, accept_msg_len
    call print

.add_client:
    mov dword [pollfds], 0 ; stdin
    mov word [pollfds + 4], 0x001 ; POLLIN
    mov word [pollfds + 6], 0 ; revents

    mov dword [pollfds + 8], r9d ; client socket
    mov word [pollfds + 12], 0x001 ; POLLIN
    mov word [pollfds + 14], 0 ; revents

.chat_loop:
    call poll

    mov ax, word [pollfds + 6] ; revents for stdin
    test ax, 0x001 ; check if POLLIN is set
    jz .check_network

    mov rax, 0
    mov rdi, 0
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .exit

    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall

    jmp .chat_loop

.check_network:
    mov ax, word [pollfds + 14]
    test ax, 0x001 ; check if POLLIN is set
    jz .chat_loop

    mov rax, 0
    mov rdi, r9
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle .exit

    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall

    jmp .chat_loop

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; socket(int domain, int type, int protocol)
; returns: socket fd in rax
socket:
    mov rax, 41
    mov rdi, 2 ; AF_INET
    mov rsi, 1 ; SOCK_STREAM
    mov rdx, 0 ; IPPROTO_IP
    syscall
    ret

; bind(int sockfd, const struct sockaddr *addr,socklen_t addrlen)
; returns: 0 on success, -1 on error
bind:
    mov rax, 49
    syscall
    ret

; listen(int sockfd, int backlog)
; returns: 0 on success, -1 on error
listen:
    mov rax, 50
    syscall

; accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
; returns: client socket fd in rax, -1 on error
accept:
    mov rax, 43
    mov rsi, 0
    mov rdx, 0
    syscall
    ret

; poll(struct pollfd *fds, nfds_t nfds, int timeout)
; returns: number of fds with events in rax, -1 on error
poll:
    mov rax, 7
    mov rdi, pollfds
    mov rsi, 2
    mov rdx, -1 ; timeout: infinite
    syscall
    ret

; write(int fd, const void *buf, size_t count)
; returns: number of bytes written in rax, -1 on error
print:
    mov rdx, rsi
    mov rsi, rdi

    mov rax, 1
    mov rdi, 1
    syscall
    ret