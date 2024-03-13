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

miniprintf_cdecl:
    mov rsi, [rsp + 8]  ; fmt string
    mov rbp, rsp
    add rbp, 8 * 2      ; fmt arguements pointer

.print_str:
    mov rcx, buffer_size
    mov rdi, buffer
.load_char:
    lodsb
    cmp al, 0
    je .exit
    cmp al, '%'
    je .format
    stosb
    loop .load_char
.flush:
    push rsi
    push rbp
    flush buffer, buffer_size
    pop rbp
    pop rsi
    jmp .print_str
.format:
    lodsb 
    jmp [format_jmp_table + rax * 8]

.exit:
    sub rdi, buffer
    mov rcx, rdi
    flush buffer, rcx
    ret

%macro return_to_printf 0
    dec rcx
    cmp cx, 0
    je miniprintf_cdecl.flush
    jmp miniprintf_cdecl.load_char
%endmacro

no_format:
    mov al, '%'
    stosb
    dec rsi
    return_to_printf

percent_format:
    mov al, '%'
    stosb
    return_to_printf

char_format:
    mov al, byte [rbp]
    stosb
    add rbp, 8
    return_to_printf

section .rodata
buffer_size equ 0x20
format_jmp_table_size equ 0x100

section .data
buffer db buffer_size dup(0)
miniprintf_ret_addr dq 0
format_jmp_table dq '%' dup(no_format)
                 dq percent_format
                 dq 'c' - '%' - 1 dup(no_format)
                 dq char_format
                 dq format_jmp_table_size - 'c' - 1 dup(no_format)
