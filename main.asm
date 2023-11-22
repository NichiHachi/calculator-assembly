section .bss
    stringBuffer resb 100
    stringBufferPos resb 8
    inputBuffer resb 16
    result resb 16
    operationBuffer resb 1

section .data
    messageNumber db "Enter a number: ", 0
    messageNumberLen equ $ - messageNumber
    messageOperation db "Enter an operation: ", 0
    messageOperationLen equ $ - messageOperation
    messageVerifyFalse db "I didn't understand the operation. Please try again.", 0xA
    messageVerifyFalseLen equ $ - messageVerifyFalse
    messageResult db "Result: ", 0
    messageResultLen equ $ - messageResult
    messageDivideZero db "Well played but you can't divide by 0 :)", 0
    messageDivideZeroLen equ $ - messageResult
    newline db "-----------------------", 0xA
    newlineLen equ $ - newline


section .text
global _start

_start:
    call _askNumber
    mov [result], rax ; The first number is the result
    
    call _askOperation

    call _exitSucess

_askNumber: ; store in rax the number
    mov rax, 1
    mov rdi, 1
    lea rsi, [messageNumber]
    mov rdx, messageNumberLen
    syscall

    call _getInput
    call _strToInt 

    ret

_askOperation:
.loop:
    mov rax, 1
    mov rdi, 1
    lea rsi, [messageOperation]
    mov rdx, messageOperationLen
    syscall

    call _getInput
    mov al, [inputBuffer]
    mov [operationBuffer], al

    jmp .verify

.verifyFalse: ; if the operator is not valid
    mov rax, 1
    mov rdi, 1
    lea rsi, [messageVerifyFalse]
    mov rdx, messageVerifyFalseLen
    syscall
    jmp .loop

.verify:
    cmp byte [operationBuffer], '+' ; add
    je .addNumbers

    cmp byte [operationBuffer], '-' ; subtract
    je .subtractNumbers

    cmp byte [operationBuffer], '*' ; multiply
    je .multiplyNumbers

    cmp byte [operationBuffer], '/' ; divide
    je .divideNumbers

    cmp byte [operationBuffer], '%' ; modulo
    je .moduloNumbers

    cmp byte [operationBuffer], '^' ; power
    je .powerNumbers

    cmp byte [operationBuffer], 'r' ; reset / restart
    je _start

    cmp byte [operationBuffer], 'e' ; exit / end
    je _exitSucess

    jmp .verifyFalse

.addNumbers:
    call _askNumber
    add [result], rax
    jmp .printResult

.subtractNumbers:
    call _askNumber
    sub [result], rax
    jmp .printResult

.multiplyNumbers:
    call _askNumber
    cmp rax, 0 ; if the number is multiplied by 0, change it to 0
    je .isZeroMult
    call _multiplyByRAX
    jmp .printResult
    .isZeroMult:
        mov qword [result], 0
        jmp .printResult
    
.divideNumbers:
    call _askNumber
    cmp rax, 0 ; can't divide by 0 :)
    je .isZeroDiv
    xor r8, r8
    mov r10, rax
    .divide:
        cmp qword [result], rax
        jl .divideEnd
        inc r8
        add rax, r10
        jmp .divide
    .divideEnd:
        mov qword [result], r8
        jmp .printResult
    .isZeroDiv:
        mov rax, 1
        mov rdi, 1
        lea rsi, [messageDivideZero]
        mov rdx, messageDivideZeroLen
        syscall
        jmp .printResult
        
.moduloNumbers:
    call _askNumber
    cmp rax, 0
    je .printResult
    mov r10, rax
    .modulo:
        cmp qword [result], rax
        jl .moduloEnd
        add rax, r10
        jmp .modulo
    .moduloEnd:
        sub rax, r10
        sub qword [result], rax
        jmp .printResult
    

.powerNumbers:
    call _askNumber
    cmp rax, 0 ; if the number is powered by 0, change it to 1
    je .isZeroPower
    mov r8, rax
    mov r9, qword [result]
    .power:
        cmp r8, 1
        je .printResult
        mov rax, r9
        call _multiplyByRAX
        dec r8
        jmp .power
    .isZeroPower:
        mov qword [result], 1
        jmp .printResult


.printResult:
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, newlineLen
    syscall
    call _printResult
    jmp .loop

_multiplyByRAX:
    mov r10, qword[result]
.multiply:
    cmp rax, 1
    je .end
    add qword [result], r10
    dec rax
    jmp .multiply
.end:
    ret

_getInput:
    mov rax, 0
    mov rdi, 0
    lea rsi, [inputBuffer]
    mov rdx, 16
    syscall
    
    ret

_printResult:
    mov rax, 1
    mov rdi, 1
    lea rsi, [messageResult]
    mov rdx, messageResultLen
    syscall

    mov rax, [result]
    call _printnumberRAX

    ret

_strToInt:
    xor rax, rax
    mov rdi, inputBuffer

.loop:
    movzx rcx, byte [rdi]
    inc rdi

    cmp rcx, '0' ; if the ascii is < then the 0 one
    jl .end

    cmp rcx, '9'; if the ascii is > then the 9 one
    jg .end

    sub rcx, '0'
    imul rax, rax, 10  
    add rax, rcx  

    jmp .loop

.end:
    ret

_printnumberRAX:
    mov rcx, stringBuffer 
    mov rbx, 10
    mov [rcx], rbx
    inc rcx;
    mov [stringBufferPos], rcx

_printnumberRAXLoop:
    mov rdx, 0
    mov rbx, 10 

    div rbx 
    push rax
    add rdx, 48  
    
    mov rcx, [stringBufferPos] 
    mov [rcx], dl
    inc rcx
    mov [stringBufferPos], rcx
    
    pop rax
    cmp rax, 0
    jne _printnumberRAXLoop

_printnumberRAXLoop2: 
    mov rcx, [stringBufferPos]
    
    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, 1
    syscall
    
    mov rcx, [stringBufferPos]

    dec rcx
    mov [stringBufferPos], rcx
    
    cmp rcx, stringBuffer 
    jge _printnumberRAXLoop2
    
    ret

_exitError:
    mov rax, 60
    mov rdi, 1
    syscall  

_exitSucess:
    mov rax, 60
    mov rdi, 0
    syscall  
