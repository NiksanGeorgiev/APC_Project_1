; source: https://www.youtube.com/watch?v=XuUD0WQ9kaE
section .bss
    digitSpace resb 100 
    digitSpacePos resb 8 ; enough to store a value of a register

section .text
    global _start
 
_start:
 
    mov rax, 69420 ; move to rax the number to be printed
    call _printRAX
 
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
