;-----------------------------------------------------------------------------
; Simplified printf implementation. 
; (C) Victor Baldin, 2024.
;-----------------------------------------------------------------------------

section .text

global _miniprintf

extern _strchr

_miniprintf:
    mov rbp, rsp
    add rbp, 8
    push '%'
    push qword [rbp]
    call far _strchr
putc:
    inc qword [rbp]
    cmp [rbp], rax
    call _putc
    je putc
    ret

_putc:
    mov rdx, 1
    mov rdi, 1
    mov rax, 1
    syscall
    ret
