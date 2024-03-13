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
    push rsi
    flush buffer, buffer_size
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

no_format:
    mov al, '%'
    cmp rcx, 0
    je .flush
    dec rcx
.continue:
    dec rsi
    stosb
    jmp miniprintf_cdecl.load_char
.flush:
    flush buffer, buffer_size
    jmp .continue

section .rodata
buffer_size equ 0x20
format_jmp_table_size equ 0x100

section .data
buffer db buffer_size dup(0)
miniprintf_ret_addr dq 0
format_jmp_table dq format_jmp_table_size dup(no_format)
