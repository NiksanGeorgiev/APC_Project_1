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
    l_count dd 0                ; Will store the number of characters during manual input       
    ; Console output
    introduction db "Elves' expedition traditionally goes on foot.", NEW_LINE, "As your boats approach land, the Elves begin taking inventory of their supplies.", NEW_LINE, "One important consideration is food - in particular, the number of Calories each Elf is carrying",NEW_LINE, NEW_LINE,0
    introduction1 db "The Elves take turns writing down the number of Calories contained by the various meals",NEW_LINE, "that they've brought with them, one item per line.", NEW_LINE, "Each Elf separates their own inventory from the previous Elf's inventory (if any) by a blank line.",NEW_LINE, NEW_LINE,0
    part1 db "PART 1:", NEW_LINE, "In case the Elves get hungry and need extra snacks, they need to know which Elf to ask.",NEW_LINE, "They'd like to know how many Calories are being carried by the Elf carrying the most Calories.", NEW_LINE, NEW_LINE, 0
    part2 db "PART 2:", NEW_LINE, "To avoid this unacceptable situation, the Elves would instead like to know the total Calories carried", NEW_LINE, "by the top three Elves carrying the most Calories.", NEW_LINE, "That way, even if one of those Elves runs out of snacks, they still have two backups.", NEW_LINE, NEW_LINE, 0
    example_input db "Example input:", NEW_LINE, "1000",NEW_LINE,"2000", NEW_LINE, "3000", NEW_LINE, NEW_LINE, "4000", NEW_LINE, NEW_LINE, "5000", NEW_LINE, "6000", NEW_LINE, NEW_LINE, "7000", NEW_LINE, "8000", NEW_LINE, "9000",NEW_LINE,NEW_LINE, "Highest - 24000",NEW_LINE, "Sum of 3 highest - 45000", NEW_LINE, NEW_LINE, 0
    highest_answer db "The highest calorie count is:", NEW_LINE, 0
    top_three_answer db "The sum of the 3 highest calorie counts is:", NEW_LINE, 0
    manual_input_prompt db "Choose (m)anual or (f)ile input", NEW_LINE, "Invalid input will be ignored", NEW_LINE, 0
    manual_rules db "Input meals on different lines. Separate elfs with an empty line.", NEW_LINE, "(Lines not containing only integers will be ignored e.g. 123as1)", NEW_LINE, "Begin a line with 'n' to stop inputing", NEW_LINE, 0
    cls db `\033[H\033[2J`, 0   ; ANSI escape code for "clearing" console

;-----------------MEMORY RESERVATIONS-----------------
section .bss
    manual: resb 1              ; Will store whether the input will be manual
    buffer: resb 24000          ; Buffer big enough to store the input file
    digitString: resb 100       ; Stores the string representation of a number
    digitIndex: resb 8          ; Enough to store a value of a register
    lineNum: resb 8             ; Will be storing the integer value of the number on the line
    blockSum: resb 8            ; Will be storing the block sum
    highest: resb 8             ; Will be storing the highest num sum
    num1: resb 8                ; Will be used to store one of the three highest numbers
    num2: resb 8                ; Will be used to store one of the three highest numbers
    num3: resb 8                ; Will be used to store one of the three highest numbers
    line: resb 40               ; Will store the line during manual input
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

; @param - the address of the string
%macro print_string 1
    mov rax, %1
    call _print_string
%endmacro


    
; %endmacro
;-----------------PROGRAM-----------------
section .text
    global _start               

_start:
    call _print_intro           ; Prints the introduction to the program
    call _manual_input          ; Returns whether the user wants manual or file input

    mov rax, [manual]
    cmp rax, 'm'                ; Check what type of input was chosen
    je manual_input
    jmp file_input

manual_input:
    print_string cls            ; Clear console
    xor rax, rax
    mov [l_count], rax          ; Will be used for letter count of manual input  
    print_string manual_rules   ; Indicating how to use the manual input
    call _read_console          ; Reads input from the console
    jmp main_logic

file_input:
    call _read_file             ; Reads input from a file

main_logic:
    ; Register initialisation
    xor rax, rax                
    mov [lineNum], rax          ; Will be used for storing the number read on a line
    mov [blockSum], rax         ; Will be used for storing the sum of block of numbers
    mov [highest], rax          ; Will be used for keeping track of the highest sum
    xor r8, r8                  ; Will be used for representing the length of a number
    
    ; Find and print highest sum
    print_string highest_answer
    mov rdi, buffer             ; Load address of the input string
    call _find_highest
    print_number rax            ; Print the highest value

    ; Find and print the sum of the top 3
    print_string top_three_answer
    call _sum_top_three
    print_number rax            ; Print the sum (rax is holding the value)
    exit

;-------------------------------------------
;-----------------FUNCTIONS-----------------
;-------------------------------------------

;-----------------START - PRINT INTRO-----------------
_print_intro:
    print_string cls
    print_string introduction
    print_string introduction1
    print_string part1
    print_string part2
    print_string example_input
    print_string manual_input_prompt
ret
;-----------------END - PRINT INTRO-----------------

;-----------------START - INPUT CHOICE-----------------
_manual_input:
validate:
    
    mov rax, SYS_READ           ; Mode for reading
    mov rdi, STDIN              ; File descriptor of the console
    mov rsi, manual             ; Buffer to store the input   
    mov rdx, 1                  ; Number of bytes to be read
    syscall 

    mov rdx, [manual]           ; Store the input in rdx
    cmp rdx, 'm'                ; 155 - 'm' in ascii
    je return_input 
    cmp rdx, 'f'                ; 146 - 'f' in ascii
    jne validate

return_input:
    ret
;-----------------END - INPUT CHOICE-----------------

;-----------------START - READ FILE-----------------
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
;-----------------END - READ FILE-----------------

;-----------------START - PRINT STRING-----------------
; Input: rax as pointer to string
_print_string:
    push rax
    mov rbx, 0
print_string_loop:
    inc rax
    inc rbx
    mov cl, [rax]
    cmp cl, 0
    jne print_string_loop
 
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    pop rsi
    mov rdx, rbx
    syscall
 
    ret
;-----------------END - PRINT STRING-----------------

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
    
    ; Windows line formatting
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
    mov rbx, [blockSum]         ; Get block sum
    add rbx, rax                ; Account for the last number
    mov [blockSum], rbx         ; Update block sum
    call _min                   ; Get address of the samllest out of the three highest numbers
    mov rbx, [rax]              ; Store the value of the number
    mov rcx, [blockSum]         ; Get the block sum so it can be compared
    cmp rbx, rcx                ; If the block sum is greater - update the 3 highest
    jl update_three
    jmp final_check             ; Skip update if not needed

update_three:
    mov [rax], rcx              ; Move the block sum into the address
    xor rax, rax                ; Reset rax

final_check:
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rcx, [highest]          ; Load the highest num into rcx
    cmp rbx, rcx                ; Last comparisson
    jg swap                     ; If last block sum is bigger then swap values
    jmp end                     ; Else go to the end

swap:
    mov rbx, [blockSum]         ; Load the block sum into rbx
    mov rcx, [highest]          ; Load the highest num into rcx
    mov rcx, rbx                ; Update maximum value     
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
add rax, rbx                    ; Storing the result in rax to meet common conventions
ret

;-----------------START - MANUAL INPUT-----------------
_read_console:
        
    ;read a line
    mov rax, SYS_READ           ; Mode for reading
    mov rdi, STDIN              ; File descriptor of the console
    mov rsi, line               ; Buffer to store the input   
    mov rdx, 60                 ; Number of bytes to be read
    syscall

    ; Check if the line is valid
    call _validate_line         
    cmp rax, 0                  ; Invalid
    je _read_console            ; Ignore the line and input another one

    ; Count the length of the line (\n inclusive)
    xor rax, rax                ; Reset rax
    mov rdi, line               ; Load the address of the line in rdi   
    mov rbx, buffer             ; Load the address of the buffer in rbx
    mov rcx, [l_count]          ; Store the value of the letter count in rcx
    
add_char:
    movzx rsi, byte [rdi]       ; Store character from the line
    
    cmp rsi, 'n'                ; 'n' indicates ends of input
    je end_buffer                    

    cmp rsi, 0                  ; Indicates the end of the line
    je end_line
    mov [buffer + rcx + rax], rsi ; Store the character in the buffer
    inc rax                     ; Incrementing rax (incrementing the count of characters in the line)
    inc rdi                     ; Incrementing rdi (moving to the next character in the line)
    cmp rsi, NEW_LINE           ; Check if it is a new line    
    je end_line
    jmp add_char   
    

end_line:
    add rcx, rax                ; Adding the character count of the line to the total length of the buffer
    mov [l_count], rcx          ; Updating the character count
    jmp _read_console  

end_buffer:
    ; Adding terminating character at the end of buffer
    mov rax, [l_count]          
    mov rbx, 0
    mov [buffer + rax], rbx
    ret

;-----------------END - MANUAL INPUT-----------------

;-----------------START - VALIDATE LINE-----------------
; Validates whether the line consists of only integers
; @return - 0 if invalid and 1 if valid
_validate_line:
    mov rdi, line               ; Load the address of the line to check in rdi

validation_loop:
    movzx rsi, byte [rdi]       ; Get current character
    
    cmp rsi, 0                  ; End of line - successful
    je valid

    cmp rsi, NEW_LINE           ; Checks for a new line
    je valid

    cmp rsi, 'n'                ; Checks for 'n' which signals the end of input
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
;-----------------END - VALIDATE LINE-----------------
