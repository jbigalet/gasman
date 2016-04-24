.section .data

fbdev:
  .ascii "/dev/fb0"

.equ SYS_READ, 0
.equ SYS_WRITE, 1
.equ SYS_OPEN, 2
.equ SYS_CLOSE, 3
.equ SYS_MMAP, 9
.equ SYS_IOCTL, 16
.equ SYS_SELECT, 23
.equ SYS_NANOSLEEP, 35

.equ FBIOGET_VSCREENINFO, 17920
.equ FBIOGET_FSCREENINFO, 17922

.equ TILE_SIZE, 16

.equ TCGETS, 0x5401
.equ TCSETS, 0x5402
.equ ICANON, 2
.equ ECHO, 8
.equ ICANON_OR_ECHO, 10

.lcomm fb_handle, 8
.lcomm screensize, 8
.lcomm fb_map, 8
.lcomm walls_handle, 8
.lcomm buffer, 1
.lcomm select_timeval, 16
.lcomm sleep_timeval, 16

termios:
  .fill 12, 1, 0
termios_from_lflag:
  .fill 24, 1, 0

fd_set:
  .fill 128, 1, 0

.section .text
.globl main
main:
  # save state
  subq $500, %rsp
  mov %rsp, %rbp

  # get stdin termios
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $TCGETS, %rsi # cmd
  mov $termios, %rdx # dump in
  syscall

  # remove icanon & echo frmo termios
  mov $ICANON_OR_ECHO, %r8d
  not %r8d
  and %r8d, termios_from_lflag

  # set stdin termios (without icanon & echo)
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $TCSETS, %rsi # cmd
  mov $termios, %rdx # dump in
  syscall

.readkey:
  # sleep for 1 second
  movb $1, sleep_timeval
  mov $SYS_NANOSLEEP, %rax
  mov $sleep_timeval, %rdi
  mov $0, %rsi
  syscall

  movb $1, fd_set
  mov $SYS_SELECT, %rax # select
  mov $1, %rdi # n
  mov $fd_set, %rsi # inp
  mov $0, %rdx # outp
  mov $0, %r10 # exp
  mov $select_timeval, %r8 # timeval
  syscall

  cmp $1, %rax
  jne .dont_read

  mov $SYS_READ, %rax # read
  mov $0, %rdi # stdin
  mov $buffer, %rsi
  mov $1, %rdx
  syscall

  mov $SYS_WRITE, %rax
  mov $1, %rdi
  mov $buffer, %rsi
  mov $1, %rdx
  syscall

  jmp .readkey

.dont_read:
  jmp .done

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

  # open wall description
  mov $SYS_OPEN, %rax # open
  mov $wallfile, %rdi # device
  mov $0, %rsi # flags R+W
  syscall
  mov %rax, walls_handle # save handle

  mov $0, %r12 # tile x
  mov $0, %r13 # tile y
  mov $0xffff00, %r9 # color=yellow

  # read wall file
.readwalls:
  mov $SYS_READ, %rax # read
  mov walls_handle, %rdi # file
  mov $buffer, %rsi
  mov $1, %rdx
  syscall

  cmp $0, %rax
  je .closewalls

  cmpb $10, buffer
  je .wallincy
  add $1, %r12
  cmpb $35, buffer
  je .bluetile
  cmpb $46, buffer
  je .greytile
  cmpb $124, buffer
  je .greytile
  cmpb $71, buffer
  je .yellowtile
  cmpb $79, buffer
  je .beigetile
  cmpb $94, buffer
  je .redtile
  jmp .blacktile

.bluetile:
  mov $0x0000ff, %r9
  jmp .aftercolor
.blacktile:
  mov $0x000000, %r9
  jmp .aftercolor
.greytile:
  mov $0x555555, %r9
  jmp .aftercolor
.yellowtile:
  mov $0xffff00, %r9
  jmp .aftercolor
.redtile:
  mov $0xff0000, %r9
  jmp .aftercolor
.beigetile:
  mov $0xf5f5dc, %r9
  jmp .aftercolor
.aftercolor:
  call .drawtile
  jmp .readwalls

.wallincy:
  mov $0, %r12
  add $1, %r13
  jmp .readwalls

  # print current wall to stdout
  /* mov $SYS_WRITE, %rax */
  /* mov $1, %rdi */
  /* mov $buffer, %rsi */
  /* mov $1, %rdx */
  /* syscall */

  jmp .readwalls

.closewalls:
  mov $SYS_CLOSE, %rax
  mov walls_handle, %rdi
  syscall

  jmp .done

.draw:  # x=r10, y=r11, color=r9
  mov 16(%rbp), %ebx
  add %r10, %rbx
  imul 24(%rbp), %ebx
  shr $3, %rbx

  mov 20(%rbp), %ecx
  add %r11, %rcx
  imul 128(%rbp), %ecx

  add %rbx, %rcx
  add fb_map, %rcx

  movl %r9d, (%rcx)
  ret

.drawtile: # tilex=r12, tiley=r13, color=r9
           # uses r14 & r15, puts in r10 & r11
  mov $0, %r14
  mov $0, %r15
.drawtilex:
  mov %r12, %r10
  imul $TILE_SIZE, %r10
  add %r14, %r10
  add $100, %r10

  mov %r13, %r11
  imul $TILE_SIZE, %r11
  add %r15, %r11
  add $100, %r11

  call .draw
  add $1, %r14
  cmp $TILE_SIZE, %r14
  jne .drawtilex

  add $1, %r15
  mov $0, %r14
  cmp $TILE_SIZE, %r15
  jne .drawtilex
  ret

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
wallfile:
  .asciz "/home/jbigalet/plop/walls"
left_pressed:
  .asciz "left pressed"
right_pressed:
  .asciz "right pressed"
up_pressed:
  .asciz "up pressed"
down_pressed:
  .asciz "down pressed"
