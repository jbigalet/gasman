.section .data

fbdev: # framebuffer
  .ascii "/dev/fb0"


# SYSCALLS

.equ SYS_READ, 0
.equ SYS_WRITE, 1
.equ SYS_OPEN, 2
.equ SYS_CLOSE, 3
.equ SYS_MMAP, 9
.equ SYS_IOCTL, 16
.equ SYS_SELECT, 23
.equ SYS_NANOSLEEP, 35


# IOCTL

.equ FBIOGET_VSCREENINFO, 17920
.equ FBIOGET_FSCREENINFO, 17922

.equ TCGETS, 0x5401
.equ TCSETS, 0x5402


# FLAGS

.equ ICANON, 2
.equ ECHO, 8
.equ ICANON_OR_ECHO, 10


# MISC

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



# BOARD

.equ TILE_SIZE, 16

.equ BOARD_WIDTH, 28
.equ BOARD_HEIGHT, 36

.equ PIX_WIDTH, BOARD_WIDTH*TILE_SIZE
.equ PIX_HEIGHT, BOARD_HEIGHT*TILE_SIZE

.lcomm BOARD, BOARD_WIDTH*BOARD_HEIGHT


# TILE TYPES

.equ TILE_WALL, 0 # #
.equ TILE_NOHUP, 1 # _
.equ TILE_DOT, 2 # .
.equ TILE_EMPTY, 3 # <SPACE>
.equ TILE_TUNNEL, 4 # T
.equ TILE_ENERGIZE, 5 # O
.equ TILE_GHOST_WALL, 6 # ^
.equ TILE_NOHUP_AND_DOT, 7 # |


# STATE
# positions are in pixels, except for the corners

  # pacman
.lcomm PACMAN_X, 2
.lcomm PACMAN_Y, 2

  # ghosts
.lcomm PINKY_X, 2
.lcomm PINKY_Y, 2
.lcomm PINKY_CORNER_TILE_X, 2
.lcomm PINKY_CORNER_TILE_Y, 2

.lcomm INKY_X, 2
.lcomm INKY_Y, 2
.lcomm INKY_CORNER_TILE_X, 2
.lcomm INKY_CORNER_TILE_Y, 2

.lcomm CLYDE_X, 2
.lcomm CLYDE_Y, 2
.lcomm CLYDE_CORNER_TILE_X, 2
.lcomm CLYDE_CORNER_TILE_Y, 2

.lcomm BLINKY_X, 2
.lcomm BLINKY_Y, 2
.lcomm BLINKY_CORNER_TILE_X, 2
.lcomm BLINKY_CORNER_TILE_Y, 2



.section .text
.globl main
main:
  # save state
  subq $500, %rsp
  mov %rsp, %rbp

  /* # get stdin termios */
  /* mov $SYS_IOCTL, %rax # ioctl */
  /* mov $0, %rdi # stdin */
  /* mov $TCGETS, %rsi # cmd */
  /* mov $termios, %rdx # dump in */
  /* syscall */

  /* # remove icanon & echo frmo termios */
  /* mov $ICANON_OR_ECHO, %r8d */
  /* not %r8d */
  /* and %r8d, termios_from_lflag */

  /* # set stdin termios (without icanon & echo) */
  /* mov $SYS_IOCTL, %rax # ioctl */
  /* mov $0, %rdi # stdin */
  /* mov $TCSETS, %rsi # cmd */
  /* mov $termios, %rdx # dump in */
  /* syscall */

/* .readkey: */
  /* # sleep for 1 second */
  /* movb $1, sleep_timeval */
  /* mov $SYS_NANOSLEEP, %rax */
  /* mov $sleep_timeval, %rdi */
  /* mov $0, %rsi */
  /* syscall */

  /* movb $1, fd_set */
  /* mov $SYS_SELECT, %rax # select */
  /* mov $1, %rdi # n */
  /* mov $fd_set, %rsi # inp */
  /* mov $0, %rdx # outp */
  /* mov $0, %r10 # exp */
  /* mov $select_timeval, %r8 # timeval */
  /* syscall */

  /* cmp $1, %rax */
  /* jne .dont_read */

  /* mov $SYS_READ, %rax # read */
  /* mov $0, %rdi # stdin */
  /* mov $buffer, %rsi */
  /* mov $1, %rdx */
  /* syscall */

  /* mov $SYS_WRITE, %rax */
  /* mov $1, %rdi */
  /* mov $buffer, %rsi */
  /* mov $1, %rdx */
  /* syscall */

  /* jmp .readkey */

/* .dont_read: */
  /* jmp .exit */

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

  call .read_board_from_file
  call .draw_board
  jmp .exit




.read_board_from_file:
  # open wall description
  mov $SYS_OPEN, %rax # open
  mov $wallfile, %rdi # device
  mov $0, %rsi # flags R+W
  syscall
  mov %rax, walls_handle # save handle

  mov $0, %r12 # tile x
  mov $0, %r13 # tile y

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

  cmpb $35, buffer
  je .read_board__wall
  jmp .read_board__not_wall

.read_board__wall:
  mov $0, %r8
  jmp .read_board__set_tile
.read_board__not_wall:
  mov $1, %r8
  jmp .read_board__set_tile

.read_board__set_tile:
  call .set_tile_type
  add $1, %r12
  jmp .readwalls

.wallincy:
  mov $0, %r12
  add $1, %r13
  jmp .readwalls

.closewalls:
  mov $SYS_CLOSE, %rax
  mov walls_handle, %rdi
  syscall
  ret


  /* je .bluetile */
  /* cmpb $46, buffer */
  /* je .greytile */
  /* cmpb $124, buffer */
  /* je .greytile */
  /* cmpb $71, buffer */
  /* je .yellowtile */
  /* cmpb $79, buffer */
  /* je .beigetile */
  /* cmpb $94, buffer */
  /* je .redtile */
  /* jmp .blacktile */

/* .bluetile: */
  /* mov $0x0000ff, %r9 */
  /* jmp .aftercolor */
/* .blacktile: */
  /* mov $0x000000, %r9 */
  /* jmp .aftercolor */
/* .greytile: */
  /* mov $0x555555, %r9 */
  /* jmp .aftercolor */
/* .yellowtile: */
  /* mov $0xffff00, %r9 */
  /* jmp .aftercolor */
/* .redtile: */
  /* mov $0xff0000, %r9 */
  /* jmp .aftercolor */
/* .beigetile: */
  /* mov $0xf5f5dc, %r9 */
  /* jmp .aftercolor */
/* .aftercolor: */
  /* call .draw_unicolor_tile */
  /* jmp .readwalls */




.get_tile_type: # x=r12, y=r13
                # uses r14 (as board index).
                # returns in r8
  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  movb BOARD(%r14), %r8b
  ret




.set_tile_type: # x=r12, y=r13, type=r8
                # uses r14 (as board index).
  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  mov %r8, BOARD(%r14)
  ret




.draw_board: # uses r12 & r13 to loop through tiles
             # r14 & r15 to calculate stuff (cf draw_unicolor_tile)
             # r10 & r11 to draw the pixels
  mov $0, %r12 # tile_x
  mov $0, %r13 # tile_y

.draw_board__inc_x:
  call .get_tile_type
  cmp $0, %r8
  jne .draw_board__not_wall
  jmp .draw_board__wall

.draw_board__wall:
  mov $0x0000ff, %r9
  call .draw_unicolor_tile
  jmp .draw_board__afterdraw

.draw_board__not_wall:
  mov $0xffffff, %r9
  call .draw_unicolor_tile
  jmp .draw_board__afterdraw

.draw_board__afterdraw:
  add $1, %r12
  cmp $BOARD_WIDTH, %r12
  je .draw_board__inc_y
  jmp .draw_board__inc_x

.draw_board__inc_y:
  mov $0, %r12
  add $1, %r13
  cmp $BOARD_HEIGHT, %r13
  jne .draw_board__inc_x
  ret




.draw_pixel:  # x=r10, y=r11, color=r9
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




.draw_unicolor_tile: # tilex=r12, tiley=r13, color=r9
           # uses r14 & r15, puts in r10 & r11
  mov $0, %r14
  mov $0, %r15
.draw_unicolor_tile__x:
  mov %r12, %r10
  imul $TILE_SIZE, %r10
  add %r14, %r10
  add $100, %r10

  mov %r13, %r11
  imul $TILE_SIZE, %r11
  add %r15, %r11
  add $100, %r11

  call .draw_pixel
  add $1, %r14
  cmp $TILE_SIZE, %r14
  jne .draw_unicolor_tile__x

  add $1, %r15
  mov $0, %r14
  cmp $TILE_SIZE, %r15
  jne .draw_unicolor_tile__x
  ret





.exit:
  mov $60, %rax
  mov $0, %rdi
  syscall



#### STATIC MESS

screeninfo:
  .asciz "screen info: %dx%d @ %d\n"
screensize_format:
  .asciz "screen size: %d\n"
linelen:
  .asciz "linelen: %d\n"
wallfile:
  .asciz "walls"
left_pressed:
  .asciz "left pressed"
right_pressed:
  .asciz "right pressed"
up_pressed:
  .asciz "up pressed"
down_pressed:
  .asciz "down pressed"
