.section .data

fbdev:
  .ascii "/dev/fb0"

.equ SYS_OPEN, 2
.equ SYS_MMAP, 9
.equ SYS_IOCTL, 16

.equ FBIOGET_VSCREENINFO, 17920
.equ FBIOGET_FSCREENINFO, 17922

.lcomm fb_handle, 8
.lcomm screensize, 8
.lcomm fb_map, 8

.section .text
.globl main
main:
  # save state
  subq $500, %rsp
  mov %rsp, %rbp

  # open framebuffer
  mov $SYS_OPEN, %rax # open
  mov $fbdev, %rdi # device
  mov $2, %rsi # flags R+W
  syscall

  mov %rax, fb_handle # save handle

  # get screen infos
  mov fb_handle, %rdi # fb handle
  mov $SYS_IOCTL, %rax # ioctl
  mov $FBIOGET_VSCREENINFO, %rsi # FBIOGET_VSCREENINFO
  mov %rbp, %rdx
  syscall

  # print screen infos
  mov $screeninfo, %rdi
  mov (%rbp), %rsi
  mov 4(%rbp), %rdx
  mov 24(%rbp), %rcx
  xor %rax, %rax
  call printf

  # screensize = x*y*depth/8. store it in -300
  mov (%rbp), %esi
  imul 4(%rbp), %esi
  imul 24(%rbp), %esi
  shr $3, %esi
  mov %rsi, screensize

  # print screensize
  mov $screensize_format, %rdi
  xor %rax, %rax
  call printf

  # get fixed screen infos
  mov fb_handle, %rdi # fb handle
  mov $SYS_IOCTL, %rax # ioctl
  mov $FBIOGET_FSCREENINFO, %rsi # FBIOGET_FSCREENINFO
  lea 80(%rbp), %rdx
  syscall

  # print line_length
  mov $linelen, %rdi
  mov 128(%rbp), %rsi
  xor %rax, %rax
  call printf

  # mmap
  mov $SYS_MMAP, %rax  # mmap
  mov $0, %rdi  # addr
  mov screensize, %rsi  # len
  mov $3, %rdx  # prot = READ + WRITE
  mov $1, %r10  # flags = MAP_SHARED
  mov fb_handle, %r8  # fd
  mov $0, %r9  # off
  syscall
  mov %rax, fb_map

  mov $100, %r10 # x=100
  mov $100, %r11 # y=100
  mov $0xffff00, %r9 # color=yellow

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

.draw:  # x=r10, y=r11, color=r9
  mov 16(%rbp), %r12d
  add %r10, %r12
  imul 24(%rbp), %r12d
  shr $3, %r12

  mov 20(%rbp), %r14d
  add %r11, %r14
  imul 128(%rbp), %r14d

  add %r12, %r14
  add fb_map, %r14

  movl %r9d, (%r14)
  jmp .againx

.done:
  #exit
  mov $60, %rax
  mov $0, %rdi
  syscall

screeninfo:
  .asciz "screen info: %dx%d @ %d\n"
screensize_format:
  .asciz "screen size: %d\n"
linelen:
  .asciz "linelen: %d\n"
