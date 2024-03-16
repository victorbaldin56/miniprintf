;==============================================================================
; Simplified printf implementation. 
; (C) Victor Baldin, 2024.
;==============================================================================

section .text

%macro flush 2
    mov rax, 1
    mov rdi, 1  ; STDOUT
    mov rsi, %1 ; Buffer address
    mov rdx, %2 ; Size
    syscall
%endmacro

global miniprintf

;==============================================================================
; Minimal printf, supports: %s, %c, %x, %o, %d, %b.
; Entry: variable-lenght, uses fastcall convention.
;==============================================================================
miniprintf:
    pop qword [miniprintf_ret_addr]
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi
    call miniprintf_cdecl
    add rsp, 8 * 6
    push qword [miniprintf_ret_addr]
    ret

%macro flush_buffer 0
    push rsi
    push rbp
    push rax
    push rdx
    push r13
    push r14
    push r15
    flush buffer, buffer_size
    pop r15
    pop r14
    pop r13
    pop rdx
    pop rax
    pop rbp
    pop rsi
    mov rcx, buffer_size
    mov rdi, buffer
    jmp .continue
%endmacro

miniprintf_cdecl:
    mov rsi, [rsp + 8]  ; fmt string
    mov rbp, rsp
    add rbp, 8 * 2      ; fmt arguements pointer

.print_str:
    mov rcx, buffer_size
    mov rdi, buffer
.continue:
    lodsb
    cmp al, 0
    je .exit
    cmp al, '%'
    je .format
    stosb
    loop .continue
.flush:
    flush_buffer
.format:
    lodsb 
    jmp [format_jmp_table + rax * 8]

.exit:
    sub rdi, buffer
    mov rcx, rdi
    flush buffer, rcx
    ret

%macro return_to_printf 0
    cmp rcx, 0
    je miniprintf_cdecl.flush
    jmp miniprintf_cdecl.continue
%endmacro

%macro get_next_arg 0
    add rbp, 8
    return_to_printf
%endmacro

no_format:
    mov al, '%'
    stosb
    dec rsi
    dec rcx
    return_to_printf

percent_format:
    mov al, '%'
    stosb
    dec rcx
    return_to_printf

char_format:
    mov al, byte [rbp]
    stosb
    dec rcx
    get_next_arg

string_format:
    push rsi    ; Save fmt addr
    mov rsi, [rbp]
.print_str:
    lodsb
    cmp al, 0
    je .exit
    cmp rcx, 0
    je .flush
.continue:
    stosb
    dec rcx
    jmp .print_str 
.flush:
    flush_buffer
.exit:
    pop rsi
    get_next_arg

%macro get_decimal_digit 0
    mov eax, edx
    xor edx, edx
    div r15d        ; quotient (eax) is current digit, the rest is in remainder (edx)
    push rax        ;   |
    push rdx        ;   |
                    ;   |
    xor edx, edx    ;   |
    mov eax, r15d   ;   |
    mov r14, 10
    div r14         ;   |
    mov r15d, eax   ;   |
                    ;   |
    pop rdx         ;   |
    pop rax         ;<--+ 
%endmacro

decimal_format:
    mov edx, dword [rbp]
    cmp edx, 0
    je .zero
    jg .unsigned

    mov al, '-'
    stosb
    dec rcx

.unsigned:
    mov edx, dword [rbp]
    cmp edx, 0
    jge .positive
    neg edx

.positive:
    mov r15d, 1000000000   ; To start from left to right
    push rcx
    mov rcx, 10            ; Max number of leading zeroes to skip

.skip_leading_zeroes:
    get_decimal_digit
    cmp eax, 0
    jne .print_decimal
    loop .skip_leading_zeroes

.print_decimal:
    pop rcx

.continue:
    cmp rcx, 0
    je .flush
    add al, '0'
    stosb
    cmp r15d, 0
    je .exit
    get_decimal_digit
    dec rcx
    jmp .continue

.zero:
    mov al, '0'
    stosb
    dec rcx
    jmp .exit

.flush:
    flush_buffer

.exit:
    dec rcx
    get_next_arg

binary_format:
    mov r15, 1
    jmp bit_format

octal_format:
    mov r15, 3
    jmp bit_format

hex_format:
    mov r15, 4
    jmp bit_format

%macro shr_mask 0
    push rcx
    mov cl, r15b
    shr r14, cl
    pop rcx
    sub cl, r15b
%endmacro

;==============================================================================
; Formats %b, %x, %o
; Entry: [rbp] -- number (dword), r15b -- bits per digit (%b -- 1, %o -- 3, %x -- 4)
;==============================================================================
bit_format:
    push rax
    mov eax, [rbp]
    mov r14, [bit_masks + r15 * 8]      ; get initial mask
    push rcx
    mov cl, [bit_offsets + r15]         ; get initial offset

.skip_leading_zeroes:
    mov edx, eax
    and edx, r14d
    cmp edx, 0
    jne .print_bits
    cmp cl, r15b
    je .print_bits
    shr_mask
    jmp .skip_leading_zeroes 

.continue:
    push rcx
    mov cl, r13b         ; get initial offset

.print_bits:
    mov r13b, cl
    pop rcx
    cmp rcx, 0
    je .flush
    dec rcx
    push rcx 
    and edx, r14d
    mov cl, r13b
    shr edx, cl
    and rdx, 0xff
    mov dl, [hex_digits + rdx]
    mov [rdi], dl
    inc di
    and rcx, 0xff
    cmp cl, 0
    je .exit
    shr_mask
    mov edx, eax
    jmp .print_bits

.flush:
    flush_buffer
    
.exit:
    pop rcx
    pop rax
    get_next_arg

section .rodata
buffer_size equ 32
hex_digits db '0123456789abcdef'
bit_offsets  db 0, 31, 0, 30, 28   ; offset to bit mask to obtain the first digit
bit_masks   dq 0, 0x1 << 31, 0, 0x7 << 30, 0xf << 28
format_jmp_table_size equ 0x100
format_jmp_table    dq '%' dup(no_format)
                    dq percent_format
                    dq 'b' - '%' - 1 dup(no_format)
                    dq binary_format
                    dq char_format
                    dq decimal_format
                    dq 'o' - 'd' - 1 dup(no_format)
                    dq octal_format
                    dq 's' - 'o' - 1 dup(no_format)
                    dq string_format
                    dq 'x' - 's' - 1 dup(no_format)
                    dq hex_format
                    dq format_jmp_table_size - 'x' - 1 dup(no_format)

section .data
buffer db buffer_size dup(0)
miniprintf_ret_addr dq 0
