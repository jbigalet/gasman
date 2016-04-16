.section .data
.section .text
.globl _start
_start:
  movq $60, %rax
  movq $27, %rdi
  syscall
