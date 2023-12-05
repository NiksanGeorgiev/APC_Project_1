;;Reads the whole file
; The file must be less than 24KB

SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_OPEN    equ 2
SYS_CLOSE   equ 3

O_RDONLY    equ 0
O_WRONLY    equ 1
O_RDWR      equ 2

section .data
    path dd "../../input.txt"
    size dw 24000
section .bss
    buffer: resb 24000

section .text
global _start:

_start:
    mov rax, SYS_OPEN
    mov rdi, path
    mov rsi, O_RDONLY
    mov rdx, 0644o ;file permission which doesn't really matter when reading a file
    syscall

    mov rdi, rax
    mov rax, SYS_READ
    mov rsi, buffer
    mov rdx, size
    syscall

    mov rax, SYS_CLOSE
    pop rdi ;pops the file descriptor into rdi
    syscall

    mov rax, 60
    mov rsi, 0
    syscall