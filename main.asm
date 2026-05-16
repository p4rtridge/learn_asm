; declare initialized data here
section .data
    sockaddr_in:
        dw 2 ; sin_family: AF_INET (IPv4)
        dw 0x901F ; sin_port: htons(8080)
        dd 0 ; sin_addr: INADDR_ANY
        dq 0 ; sin_zero: padding
    sockaddr_in_len equ $-sockaddr_in

    listen_backlog db 5
    max_clients equ 10
    max_fds equ max_clients + 1 ; +1 for server socket

    listen_msg db "Listening on port 8080...", 0x0A, 0x00
    listen_msg_len equ $-listen_msg

    accept_msg db "Client connected!", 0x0A, 0x00
    accept_msg_len equ $-accept_msg

; reserve space for variables here
section .bss
    buffer resb 1024
    pollfds resb 8 * max_fds

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

    ; add server socket to pollfds
    mov dword [pollfds], r8d
    mov word [pollfds + 4], 0x001 ; POLLIN

; main loop to handle incoming connections and client messages
.main_loop:
    call poll

    mov ax, word [pollfds + 6] ; revents for server socket
    test ax, 0x001 ; check if POLLIN is set
    jz .handle_clients ; if not, check client sockets

    mov rdi, r8
    call accept
    mov r9, rax ; store client socket fd in r9

    mov rdi, accept_msg
    mov rsi, accept_msg_len
    call print

    ; add new client socket to pollfds
    mov r12, 1
    jmp .find_empty_slot

; loop to handle client messages
.handle_clients:
    mov r12, 1
    jmp .client_loop

.next_client:
    inc r12
    jmp .client_loop

.client_loop:
    cmp r12, max_fds
    jge .main_loop ; if we exceed max_fds, go back to main loop

    mov rbx, r12
    shl rbx, 3 ; offset for pollfd struct

    mov r14d, dword [pollfds + rbx] ; fd for this client
    cmp r14d, 0 ; check if slot is empty
    jle .next_client ; if empty, check next client

    mov ax, word [pollfds + rbx + 6] ; revents for client socket
    test ax, 0x001 ; check if POLLIN is set
    jz .next_client ; if not, check next client

    mov rax, 0
    mov rdi, r14
    mov rsi, buffer
    mov rdx, 1024
    syscall ; read from client

    cmp rax, 0
    jle .close_client

    mov r15, rax
    mov word [pollfds + rbx + 6], 0 ; clear revents for this client
    mov r13, 1
    jmp .broadcast

.close_client:
    mov rax, 3
    mov rdi, r14
    syscall ; close client socket

    mov rbx, r12
    shl rbx, 3
    mov dword [pollfds + rbx], 0 ; clear fd
    mov word [pollfds + rbx + 4], 0 ; clear events
    mov word [pollfds + rbx + 6], 0 ; clear revents
    jmp .next_client

; loop to broadcast message to all clients except the sender
.next_broadcast:
    inc r13
    jmp .broadcast
    
.broadcast:
    cmp r13, max_fds
    jge .next_client

    mov rbx, r13
    shl rbx, 3

    mov edi, dword [pollfds + rbx] ; fd for this client
    cmp edi, 0
    jle .next_broadcast

    mov rax, 1
    mov rsi, buffer
    mov rdx, r15
    syscall ; write to client
    jmp .next_broadcast

; find an empty slot in pollfds to add the new client socket
.next_slot:
    inc r12
    jmp .find_empty_slot

.find_empty_slot:
    cmp r12, max_fds
    jge .handle_clients ; if we exceed max_fds, just check clients without adding

    mov rbx, r12
    shl rbx, 3 ; offset for pollfd struct

    cmp dword [pollfds + rbx], 0 ; check if fd is 0 (empty slot)
    jne .next_slot ; if not empty, check next slot

    mov dword [pollfds + rbx], r9d ; store client fd
    mov word [pollfds + rbx + 4], 0x001 ; POLLIN (events)
    jmp .handle_clients

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
    mov rsi, max_fds
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