.section .data
fbdev:
  .ascii "/dev/fb0"

.section .text
.globl main
main:

  # open framebuffer
  mov $2, %rax # open
  mov $fbdev, %rdi # device
  mov $2, %rsi # flags R+W
  syscall

  mov %rax, %rbp # save handle

  subq $168, %rsp

  # get screen infos
  mov %rbp, %rdi # fb handle
  mov $16, %rax # ioctl
  mov $17920, %rsi
  mov %rsp, %rdx
  syscall

  mov $format, %rdi
  mov (%rsp), %rsi
  mov 4(%rsp), %rdx
  mov 24(%rsp), %rcx
  xor %rax, %rax
  call printf

  #exit
  mov $60, %rax
  mov $21, %rdi
  syscall

format:
  .string "screen info: %dx%d @ %d\n"
