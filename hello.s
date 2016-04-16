.section .data
hello:
  .ascii  "Yu!\n"
  len = . - hello

.section .text
.globl _start
_start:

  #write hello
  mov $1, %rax # write
  mov $1, %rdi # stdout
  mov $hello, %rsi
  mov $len, %rdx
  syscall

  #exit
  mov $60, %rax
  mov $21, %rdi
  syscall
