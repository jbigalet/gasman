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

  subq $500, %rsp

  # get screen infos
  mov %rbp, %rdi # fb handle
  mov $16, %rax # ioctl
  mov $17920, %rsi # FBIOGET_VSCREENINFO
  mov %rsp, %rdx
  syscall

  # print screen infos
  mov $screeninfo, %rdi
  mov (%rsp), %rsi
  mov 4(%rsp), %rdx
  mov 24(%rsp), %rcx
  xor %rax, %rax
  call printf

  # screensize = x*y*depth/8. store it in -300
  mov (%rsp), %rsi
  imul 4(%rsp), %rsi
  imul 24(%rsp), %rsi
  shr $3, %rsi
  mov %rsi, 300(%rsp)

  # print screensize
  mov $screensize, %rdi
  xor %rax, %rax
  call printf

  # get fixed screen infos
  mov %rbp, %rdi # fb handle
  mov $16, %rax # ioctl
  mov $17922, %rsi # FBIOGET_FSCREENINFO
  lea 80(%rsp), %rdx
  syscall

  # print line_length
  mov $linelen, %rdi
  mov 128(%rsp), %rsi
  xor %rax, %rax
  call printf

  # mmap
  /* mov $9, %rax */
  /* syscall */

  #exit
  mov $60, %rax
  mov $0, %rdi
  syscall

screeninfo:
  .asciz "screen info: %dx%d @ %d\n"
screensize:
  .asciz "screen size: %d\n"
linelen:
  .asciz "linelen: %d\n"
