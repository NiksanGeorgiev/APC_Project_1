;-----------------CONSTANTS-----------------
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

;-----------------DATA SETUP-----------------
section .data
    path dd "input.txt"         ; Path to the file containing the input
    size dw 24000               ; Size of the bugffer that is going to be used for storing the file

;-----------------MEMORY RESERVATIONS-----------------
section .bss
    buffer: resb 24000          ; Buffer big enough to store the input file
    digitString: resb 100       ; Stores the string representation of a number
    digitIndex: resb 8          ; Enough to store a value of a register
    lineNum: resb 8             ; Will be storing the integer value of the number on the line
    blockSum: resb 8            ; Will be storing the block sum
    highest: resb 8             ; Will be storing the highest num sum
    num1: resb 8                ; Will be used to store one of the three highest numbers
    num2: resb 8                ; Will be used to store one of the three highest numbers
    num3: resb 8                ; Will be used to store one of the three highest numbers

;-----------------MACROS-----------------
; !DISCLAIMER! NASM specific syntax
; @param - number to be printed
%macro print_number 1
    mov rax, %1
    call _print_num
%endmacro    

%macro exit 0
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
%endmacro

;-----------------PROGRAM-----------------
section .text
    global _start               

_start:

    call _read_file

    ; Register initialisation
    mov rdi, buffer             ; Load address of the input string
    xor rax, rax                
    mov [lineNum], rax          ; Will be used for storing the number read on a line
    mov [blockSum], rax         ; Will be used for storing the sum of block of numbers
    mov [highest], rax          ; Will be used for keeping track of the highest sum
    xor r8, r8                  ; Will be used for representing the length of a number
    
    call _find_highest
    ; TODO - print highest
    print_number rax
    call _sum_top_three
    ; TODO - print sum of top 3

    print_number rax            ; Print the highest value
    exit

;-------------------------------------------
;-----------------FUNCTIONS-----------------
;-------------------------------------------
_read_file:
    ; Opening the file to get the file descriptor
    mov rax, SYS_OPEN           ; Type of operation (syscall number) 
    mov rdi, path               ; Path to file
    mov rsi, O_RDONLY           ; Mode of opening
    mov rdx, 0644o              ; file permission which doesn't really matter when reading a file
    syscall

    ; Reading the file and storing it in a buffer
    mov rdi, rax                ; File descriptor (returned automatically in rax)
    mov rax, SYS_READ           ; Type of operation (syscall number) 
    mov rsi, buffer             ; Buffer to store the file
    mov rdx, size               ; Bytes to be read from the file (the size of the buffer)
    syscall

    ret

;-----------------START - PRINT NUMBER-----------------
_print_num:
    mov rcx, digitString        ; Load address of the string that will represent the number
    mov rbx, NEW_LINE           ; New line character (because it will be printed backwards)
    mov [rcx], rbx              ; Adds the new line character
    inc rcx                     ; Moves the position
    mov [digitIndex], rcx       ; Keeps track of how far we are into the string
 
 ; Continuously divides the number stored in rax by 10 to get the reamainder
 ; Stores the remainder digitString so that it can be then printed
string_composition_loop:
    mov rdx, 0                  ; Rdx stores the remainder of division so we want to make sure it's zero before we divide
    mov rbx, 10                 ; Initialising rbx with a divisor
    div rbx                     ; Getting the remainder from the division in rdx
    add rdx, ASCII0             ; Add 48 to get the digit value in ASCII
 
    mov rcx, [digitIndex]       ; Moving the value of the digit index to rcx
    mov [rcx], dl               ; Moving the remainder that we just got to rcx
    inc rcx                     ; Incrementing essentially the index that we need to store the new digit at
    mov [digitIndex], rcx       ; Assigning digitIndex to the incremented value
    
    cmp rax, 0                  ; Continue until all the digits have been added to the string
    jne string_composition_loop
 
 ; Prints the string that was formed by the number
print_num_loop:
    mov rcx, [digitIndex]       ; Resembles the postion of the string that needs to be printed 

    ; Setup for printing characters
    mov rax, SYS_WRITE          ; Type of operation (syscall number) 
    mov rdi, STDOUT             ; Where to write to (file descriptor)
    mov rsi, rcx                ; The address of the buffer to be printed
    mov rdx, 1                  ; Number of bytes to be printed
    syscall
 
    ; Decrement the position
    mov rcx, [digitIndex]   
    dec rcx
    mov [digitIndex], rcx
 
    ; Checks to see if the position of the string has preceded the starting addrtess of the buffer
    ; (because it is printed backwards)
    cmp rcx, digitString
    jge print_num_loop
 
    ret
;-----------------END - PRINT NUMBER-----------------


;-----------------START - FIND MAXIMUM-----------------
_find_highest:
    
    mov rax, [lineNum]          ; Load the value of the line into rax
    movzx rsi, byte [rdi]       ; Read a character from the input
    
    cmp rsi, 0                  ; Check if the character is the null terminator (end of string)
    je end_reading

    cmp rsi, CAR_RET            ; Check for \r (Relevant for Windows files)
    je increment
  
    cmp rsi, NEW_LINE           ; Check if the character is a newline 13, 10 (Windows) or 10 - Linux
    je check_empty_line
    
    cmp r8 , 1                  ; Check whether the number length is greater than 1
    jge multiply                ; If it's the second or greater digit - multiply by 10 before adding the new digit
    jmp addition                ; Else - go straight to addition

multiply:
    mov r9, 10                  ; Multiplier
    mul r9                      ; Multiplying the value of rax by 10
    
addition:
    sub rsi, ASCII0             ; Convert ASCII character to integer
    add rax, rsi                ; Add to the sum

increment:
    inc rdi                     ; Move to the next character in the input string
    inc r8                      ; Increment the number of digits in the number on the current line
    
    mov [lineNum], rax          ; Update the value of the line number
    jmp _find_highest           ; Continue reading characters

check_empty_line:
    ; Actions done at the end of a line
    xor r8, r8                  ; Reset the number of digits
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rax, [lineNum]          ; Load the line number into rax
    add rbx, rax                ; Add the value of the line to the sum of the block
    xor rax, rax                ; Reseting the line sum
    mov [blockSum], rbx         ; Updating the block sum
    mov [lineNum], rax          ; Updating the line number

    ; Mac file formating (without \r)
    movzx rsi, byte [rdi - 1]   ; Get the value value 1 character behind the current
    cmp rsi, NEW_LINE           ; Check if it is \n    
    je update_block_sum         ; If yes, update block sum and reset block sum
    
    ; WIndows line formatting
    cmp rsi, CAR_RET
    je check_windows_line

check_windows_line:
    movzx rsi, byte [rdi - 2]   ; Get the value value 2 characters behind the current
    cmp rsi, NEW_LINE           ; Check if it is \n    
    je update_block_sum         ; If yes, update block sum and reset block sum

    inc rdi                     ; Point to next character
    jmp _find_highest           ; Continue reading characters

update_block_sum:
    call _min                   ; Get address of the samllest out of the three highest numbers
    mov rbx, [rax]              ; Store the value of the number
    mov rcx, [blockSum]         ; Get the block sum so it can be compared
    cmp rbx, rcx                ; If the block sum is greater - update the 3 highest
    jl update_three_highest
    jmp post_three_update       ; Skip update if not needed

update_three_highest:
    mov [rax], rcx              ; Move the block sum into the address
    xor rax, rax                ; Reset rax

post_three_update:
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rcx, [highest]          ; Load the highest num into rcx
    cmp rbx, rcx                ; Compare and update maximum sum
    jg update_maximum_sum

    xor rbx, rbx                ; Reset block sum for the next block
    mov [blockSum], rbx         ; Update block sum
    inc rdi                     ; Move to the next character in the input string
    jmp _find_highest           ; Continue reading characters

update_maximum_sum:
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rcx, [highest]          ; Load the highest num into rcx
    mov rcx, rbx                ; Update block sum
    xor rbx, rbx                ; Reset block sum for the next block
    mov [blockSum], rbx         ; Update vlock sum
    mov [highest], rcx          ; Update highest num
    inc rdi                     ; Move to the next character in the input string
    jmp _find_highest           ; Continue reading characters

end_reading:
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rcx, [highest]          ; Load the highest num into rcx
    cmp rbx, rcx                ; Last comparisson
    jg swap                     ; If last block sum is bigger then swap values
    jmp end                     ; Else go to the end

swap:
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rcx, [highest]          ; Load the highest num into rcx
    mov rcx, rbx                ; Update maximum value     
    xor rbx, rbx                ; Reset rbx
    mov [blockSum], rbx         ; Update vlock sum
    mov [highest], rcx          ; Update highest num

end:
    mov rax, [highest]          ; Common convention for functions to return result in rax
    ret

;-----------------END - FIND MAXIMUM-----------------


;-----------------START - FIND MINIMUM-----------------
; Find the minimum value out of num1, num2 and num3
; @return - the address of the corresponding variable
_min:
    ; Move numbers into registers so that they can be compared
    mov rbx, [num1]
    mov rcx, [num2]
    mov rdx, [num3]
    xor rax, rax                ; Reset rax

    cmp rbx, rcx                ; Check if num1 is smaller than num2
    jle rbx_min                 
    jmp rcx_min

rbx_min:
    cmp rbx, rdx                ; Check if num1 is smaller than num3
    jle rbx_store
    jmp rdx_store

rcx_min:
    cmp rcx, rdx                ; Check if num2 is smaller than num3
    jle rcx_store
    jmp rdx_store

rbx_store:
    mov rax, num1               ; num1 is the min out of the 3
    jmp return
rcx_store:
    mov rax, num2               ; num2 is the min out of the 3
    jmp return
rdx_store:
    mov rax, num3               ; num3 is the min out of the 3
    jmp return

return:
    ret
;-----------------END - FIND MINIMUM-----------------

_sum_top_three:
xor rax, rax
mov rbx, [num1]
add rax, rbx
mov rbx, [num2]
add rax, rbx
mov rbx, [num3]
add rax, rbx
ret