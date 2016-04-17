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
  mov (%rsp), %esi
  imul 4(%rsp), %esi
  imul 24(%rsp), %esi
  shr $3, %esi
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
  mov $9, %rax  # mmap
  mov $0, %rdi  # addr
  mov 300(%rsp), %rsi  # len
  mov $3, %rdx  # prot = READ + WRITE
  mov $1, %r10  # flags = MAP_SHARED
  mov %rbp, %r8  # fd
  mov $0, %r9  # off
  syscall
  mov %rax, 400(%rsp) # save res
  mov %rax, %r13

  mov $100, %r10
  mov $100, %r11

.againx:
  add $1, %r10
  cmp $400, %r10
  je .againy
  jmp .draw

.againy:
  mov $100, %r10
  add $1, %r11
  cmp $400, %r11
  jne .draw
  jmp .done

.draw:  # x=r10, y=r11
  mov 16(%rsp), %r12d
  add %r10, %r12
  imul 24(%rsp), %r12d
  shr $3, %r12

  mov 20(%rsp), %r14d
  add %r11, %r14
  imul 128(%rsp), %r14d

  add %r12, %r14

  movl $0xffff00, (%r14, %r13)
  jmp .againx

.done:
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
