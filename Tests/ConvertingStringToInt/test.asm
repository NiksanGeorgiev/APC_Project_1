section .data
    num dw "12345",0
    len db 5
    multiplier db 10

section .text
global _start
_start:
    mov rbx, num ;store pointer to num
    mov rax, 0 ; will store the number representation of the string
    mov r9, 0 ;counter

loop:
    

    mov cl, [rbx] ; dl holds the character of the string
    cmp cl, 0 ; make sure tht the string has not ended
    je end l ; if end of string - go to the tend of the program
    sub cl, '0' ; subtract that ascii value of 0 from the char to get the actual number
    cmp r9 , 1 ; after the first digit start mnultiplying by 10 so that 1 becomes 10 and 2 can be added to it to become 12
    jge multiply ; if it's the second or greater digit - multiply
    jmp addition ; else - go straight to addition
multiply:
    mov r8, 10 ; multiplier
    mul r8 ; multiplying the value of rax by 10
addition:
    add rax, rcx ; adding the value of the current character to rax
    inc rbx ; incrementing the pointer so it points to the next char
    inc r9 ; incrementing the counter
    cmp r9, [len]
    jne loop ; do again if the end of the string is not reached

end:
    mov rsi, rax ; rsi will store the integer value of the string
    mov rax, 60 
    syscall