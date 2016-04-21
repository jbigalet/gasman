.section .data
hello:
  .ascii  "Yu!\n"
fbdev:
  .ascii "/dev/fb0"

.section .text
.globl _start
_start:

  # open framebuffer
  mov $2, %rax # open
  mov $fbdev, %rdi # device
  mov $2, %rsi # flags R+W
  syscall

  mov %rax, %rbp # save handle

  # get screen infos
  mov $16, %rax # ioctl
  mov %rbp, %rdi # fb handle
  mov $0x00004600, %rsi
  mov $0x00000002, %rdx
  syscall

  # write stuff
  mov $1, %rax # write
  mov $1, %rdi # stdout
  mov %rbp, %rsi
  mov $4, %rdx # len

  #exit
  mov $60, %rax
  mov $21, %rdi
  syscall
