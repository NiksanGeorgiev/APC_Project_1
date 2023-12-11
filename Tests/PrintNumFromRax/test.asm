; source: https://www.youtube.com/watch?v=XuUD0WQ9kaE
; syscalls
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_OPEN    equ 2
SYS_CLOSE   equ 3
SYS_EXIT    equ 60

; File Descriptors
STDIN   equ 0
STDOUT  equ 1

; Open modes
O_RDONLY    equ 0
O_WRONLY    equ 1
O_RDWR      equ 2

NEW_LINE    equ 10              ; '\n'
CAR_RET     equ 13              ; '\r'
ASCII0      equ 48              ; 0 in ASCII
section .bss
    digitSpace resb 100 
    digitSpacePos resb 8 ; enough to store a value of a register
    num1 resb 8
    num2 resb 8
    num3 resb 8

    line resb 60
    buffer resb 2400

section .data
    number dw 0
    num db 10, "12345",0
    ipath db "input.txt",0
    path db "output.txt",0
    text db "Some text",0
    
section .text
    global _start
 
_start:
    ; mov rbx, 6
    ; mov [num1], rbx
    ; mov rbx, 70
    ; mov [num2], rbx
    ; mov rbx, 1
    ; mov [num3], rbx

    ; ; ; mov rbx, rax
    ; ; ; mov rax, [rbx]

    ; ; mov rbx, 69420
    ; ; mov [num1], rbx  ; stores value into a variable
    ; ; mov rax, num1    ; sores the address of the variable
    ; ; ; mov rbx, [rax]      ; practically dereference the address of the variable
    ; ; ; mov rax, rbx
    ; ; mov rbx, 10
    ; ; mov [rax], rbx
    ; ; mov rax, [num1]   
    ; ;call _sum_top_three

    ; mov rax, [number]
    ; call _printRAX
 
    ; mov rbx, 2
    ; mov [number], rbx
    mov rdx, 0
    mov [number], rdx
    ; call _read_line
    call _read_line
    ;call _printRAX
    call _write_to_file

    mov rax, 60
    mov rdi, 0 
    syscall
 
_printRAX:
    mov rcx, digitSpace
    mov rbx, 10 ; new line character
    mov [rcx], rbx
    inc rcx
    mov [digitSpacePos], rcx ; keeps track of how far we are into the string
 
 ;Continuously divides the number stored in rax by 10 to get the reamainder
 ;Stores the remainder digitSpace so that it can be then printed
_printRAXLoop:
    mov rdx, 0 ; rdx stores the remainder of division so we want to make sure it's zero before we divide
    mov rbx, 10
    div rbx ; divide rax by 10 to get the remainder
    add rdx, 48 ; add 48 to get the digit value in ASCII
 
    mov rcx, [digitSpacePos]
    mov [rcx], dl ; moving the remainder that we just got to rcx
    inc rcx
    mov [digitSpacePos], rcx
    
    cmp rax, 0 ;continue until all the digits have been added to the string
    jne _printRAXLoop
 
 ;Prints the string that was formed by the number
_printRAXLoop2:

    ;resembles the postion of the string that needs to be printed
    mov rcx, [digitSpacePos]
    
    ; setup for printing characters
    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, 1
    syscall
 
    ;decrement the position
    mov rcx, [digitSpacePos]
    dec rcx
    mov [digitSpacePos], rcx
 
    ;checks to see if the position of the string has exceeded the starting addrtess of the buffer
    cmp rcx, digitSpace
    jge _printRAXLoop2
 
    ret

_min:
    ; Move numbers into registers so that they can be compared
    mov rbx, [num1]
    mov rcx, [num2]
    mov rdx, [num3]
    xor rax, rax                ; Reset rax

    cmp rbx, rcx
    jle rbx_min
    jmp rcx_min

rbx_min:
    cmp rbx, rdx
    jle rbx_store
    jmp rdx_store

rcx_min:
    cmp rcx, rdx
    jle rcx_store
    jmp rdx_store
rbx_store:
    mov rax, num1
    jmp return
rcx_store:
    mov rax, num2
    jmp return
rdx_store:
    mov rax, num3
    jmp return

return:
    ret

_sum_top_three:
xor rax, rax
mov rbx, [num1]
add rax, rbx
mov rbx, [num2]
add rax, rbx
mov rbx, [num3]
add rax, rbx
ret

_read_line:
        
    ;read a line
    mov rax, 0               ; Mode for reading
    mov rdi, 0               ; File descriptor of the console
    mov rsi, line            ; Buffer to store the input   
    mov rdx, 60              ; Number of bytes to be read
    syscall

    call _validate_line
    cmp rax, 0
    je _read_line
;count the length of the line (\n inclusive) 
    xor rax,rax
    mov rdi, line
    mov rbx, buffer
    mov rcx, [number]
    
add_char:
    movzx rsi, byte [rdi]
    
    cmp rsi, 'n'
    je retur

    cmp rsi, 0
    je end_line
    mov [buffer + rcx + rax], rsi
    inc rax
    inc rdi
    cmp rsi , 10
    je end_line
    jmp add_char

end_line:
    add rcx, rax
    mov [number], rcx
    jmp _read_line


; add_buffer:
;     mov rdi, line
;     mov rdx, [number]
;     add rdx, rax
;     mov [number], rdx

; add_char:
;     movzx rsi, byte [rdi]
;     cmp rsi, 0
;     je _read_line
;     mov [buffer + rdx], rsi
;     dec rdx
;     inc rdi
;     jmp add_char

retur:

    mov rax, [number]
    mov rbx, 0
    mov [buffer + rax], rbx
    ret
    

; _fill_buffer:

;     mov rdi, text
;     xor rax,rax
; char:
;     movzx rsi, byte [rdi]
;     cmp rsi, 0
;     je r
;     inc rdi
;     mov [buffer + rax], rsi
;     inc rax
;     jmp char

; r:
;     ret

_write_to_file:

    mov rax, 2
    mov rdi, path
    mov rsi, 64+1
    mov rdx, 0644o
    syscall

    push rax
    mov rdi, rax
    mov rax, 1
    mov rsi, buffer
    mov rdx, [number]
    syscall

    mov rax, 3
    pop rdi
    syscall

    ret

_validate_line:
    mov rdi, line               ; Load the address of the line to check in rdi

validation_loop:
    movzx rsi, byte [rdi]       ; Get current character
    
    cmp rsi, 0                  ; End of line - successful
    je valid

    cmp rsi, 10
    je valid

    cmp rsi, 'n'
    je valid

    cmp rsi, ASCII0             ; Smaller than the ascii value of 0
    jl invalid
    
    cmp rsi, ASCII0 + 9         ; Bigger than the ascii value of 9
    jg invalid

    inc rdi                     ; Get to the next character
    jmp validation_loop

invalid:
    xor rax, rax
    jmp end_validation
valid:
    mov rax, 1
end_validation:
    ret 

_print_backwards:
    mov rax, 6 ; starting position
    


    mov rax, SYS_WRITE          ; Type of operation (syscall number) 
    mov rdi, STDOUT             ; Where to write to (file descriptor)
    mov rsi, rcx                ; The address of the buffer to be printed
    mov rdx, 1                  ; Number of bytes to be printed
    syscall
    mov