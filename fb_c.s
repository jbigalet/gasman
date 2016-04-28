.section .data

fbdev: # framebuffer
  .asciz "/dev/fb0"


# SYSCALLS

.equ SYS_READ, 0
.equ SYS_WRITE, 1
.equ SYS_OPEN, 2
.equ SYS_CLOSE, 3
.equ SYS_MMAP, 9
.equ SYS_RT_SIGACTION, 13
.equ SYS_IOCTL, 16
.equ SYS_SELECT, 23
.equ SYS_NANOSLEEP, 35
.equ SYS_ALARM, 37


# SIGNALS

.equ SIGHUP, 1
.equ SIGINT, 2
.equ SIGQUIT, 3
.equ SIGILL, 4
.equ SIGTRAP, 5
.equ SIGABRT, 6  # sig of SIGIOT
.equ SIGFPE, 8
.equ SIGKILL, 9
.equ SIGUSR1, 10
.equ SIGSEGV, 11
.equ SIGUSR2, 12
.equ SIGPIPE, 13
.equ SIGALARM, 14  # ctrl-c is not working as we're in raw mode, so we setup a watchdog (cf TIMEOUT)
.equ SIGTERM, 15
.equ SIGSTKFLT, 16
.equ SIGCHLD, 17
.equ SIGCONT, 18
.equ SIGSTOP, 19
.equ SIGTSTP, 20
.equ SIGTTIN, 21
.equ SIGTTOU, 22

sig_array:  # 0 terminated
  .byte SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGTRAP, SIGABRT, SIGFPE, SIGKILL, SIGUSR1, SIGSEGV, SIGUSR2, SIGPIPE, SIGALARM, SIGTERM, SIGSTKFLT, SIGCHLD, SIGCONT, SIGSTOP, SIGTSTP, SIGTTIN, SIGTTOU, 0

sigaction_handler:  # __rt_sigaction
  .quad .signal_handler  # handler adresse
  .quad 0x04000000   # flags = SA_RESTORER - warning: the doc is all fked up and says you need not to provide it if your calling sigaction directly as a syscall (& not the libc wrapper) -- its wrong, you need it for the kernel not to throw a EFAULT at you - on x64
  .quad 0
  .fill 128, 1, 0

.equ TIMEOUT, 10  # watchdog timeout - cf SIGALARM


# IOCTL

.equ FBIOGET_VSCREENINFO, 17920  # get frame buffer virtal screen info
.equ FBIOGET_FSCREENINFO, 17922  # get frame buffer fixed screen info

.equ TCGETS, 0x5401  # get stdin termios
.equ TCSETS, 0x5402  # set stdin termios

.equ KDGKBMODE, 0x4B44  # get console keyboard mode
.equ KDSKBMODE, 0x4B45  # set console keyboard mode


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
.lcomm sleep_timeval, 8
.lcomm sleep_timeval_nano, 8


old_termios:  # termios backup, to allow restoration
  .fill 36, 1, 0

termios:  # termios with flag modification - will be set during execution
  .fill 12, 1, 0
termios_from_lflag:
  .fill 24, 1, 0

.equ K_MEDIUMRAW, 2  # keyboard mode
oldkbmode:
  .byte 255  # cant be 0 (0 == K_RAW)

fd_set:
  .fill 128, 1, 0



# BOARD

.equ TILE_SIZE, 16

.equ TILE_RESOLUTION, 10

.equ BOARD_WIDTH, 28
.equ BOARD_HEIGHT, 36

.equ PIX_WIDTH, BOARD_WIDTH*TILE_SIZE
.equ PIX_HEIGHT, BOARD_HEIGHT*TILE_SIZE

.lcomm BOARD, BOARD_WIDTH*BOARD_HEIGHT

.equ PACMAN_SIZE, 12


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
# positions are in tiles + ratio/TILE_RESOLUTION

  # pacman
.lcomm PACMAN_X, 4
.lcomm PACMAN_X_RATIO, 4
.lcomm PACMAN_Y, 4
.lcomm PACMAN_Y_RATIO, 4

.lcomm PACMAN_DIRECTION_X, 4
.lcomm PACMAN_DIRECTION_Y, 4

  # ghosts
.lcomm PINKY_X, 4
.lcomm PINKY_Y, 4
.lcomm PINKY_CORNER_TILE_X, 4
.lcomm PINKY_CORNER_TILE_Y, 4

.lcomm INKY_X, 4
.lcomm INKY_Y, 4
.lcomm INKY_CORNER_TILE_X, 4
.lcomm INKY_CORNER_TILE_Y, 4

.lcomm CLYDE_X, 4
.lcomm CLYDE_Y, 4
.lcomm CLYDE_CORNER_TILE_X, 4
.lcomm CLYDE_CORNER_TILE_Y, 4

.lcomm BLINKY_X, 4
.lcomm BLINKY_Y, 4
.lcomm BLINKY_CORNER_TILE_X, 4
.lcomm BLINKY_CORNER_TILE_Y, 4



.section .text
.globl main
main:
  # save state
  subq $500, %rsp
  mov %rsp, %rbp


  # watchdog
  mov $TIMEOUT, %rdi  # in seconds
  mov $SYS_ALARM, %rax
  syscall


  # framebuffer setup

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




  # signal handlers - to restore stdin if anything goes wrong
  mov $sig_array, %r15
  mov $0, %rdi
.install_signal_handler:
  movb (%r15), %dil # signal number
  cmp $0, %rdi # if the sig number is 0, we're at the end of the signal array: break off the loop
  je .signal_handlers_installed

  # debug: display signal handler installed
  /* mov %rdi, %rsi  # %rdi = caught signal code */
  /* mov $signal_caught, %rdi */
  /* xor %rax, %rax */
  /* call printf */

  mov $sigaction_handler, %rsi  # sigaction act - new action
  mov $0, %rdx  # sigaction oact - old action
  mov $8, %r10  # sigsetsize
  mov $SYS_RT_SIGACTION, %rax
  syscall

  # go to next signal inside [sig_array]
  add $1, %r15
  jmp .install_signal_handler
.signal_handlers_installed:







  # stdin setup - restored by signal handlers if anything goes wrong

  # get stdin termios a first time - backup it to allow restoration latter
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $TCGETS, %rsi # cmd
  mov $old_termios, %rdx # dump in
  syscall

  # get stdin termios a second time - this one will be modified & set
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


  # keyboard mode alteration - will be restored even if -almost- anything goes wrong

  # save old keyboard mode
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $KDGKBMODE, %rsi # cmd
  mov $oldkbmode, %rdx # dump in
  syscall

  # display old keyboard mode
  mov $old_keyboard_mode, %rdi
  mov oldkbmode, %rsi
  xor %rax, %rax
  call printf

  # set keyboard mode as K_MEDIUMRAW
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $KDSKBMODE, %rsi # cmd
  mov $K_MEDIUMRAW, %rdx # new mode
  syscall



  # standard sleep is 1/30 s
  movb $0, sleep_timeval
  movl $33333333, sleep_timeval_nano

  call .read_board_from_file







###########################
####### MAIN LOOP #########
###########################


.main_loop:

  # first tile blinking

  cmpb $0, BOARD
  je .blink_1
  movb $0, BOARD
  jmp .blink_end
.blink_1:
  movb $1, BOARD
.blink_end:






  # handle key events

.readkey:
  movb $1, fd_set
  mov $SYS_SELECT, %rax # select
  mov $1, %rdi # n
  mov $fd_set, %rsi # inp
  mov $0, %rdx # outp
  mov $0, %r10 # exp
  mov $select_timeval, %r8 # timeval
  syscall

  cmp $1, %rax
  jne .readkey_end

  mov $SYS_READ, %rax # read
  mov $0, %rdi # stdin
  mov $buffer, %rsi
  mov $1, %rdx
  syscall

  # exit on 'q'
  cmpb $30, buffer
  je .cleanup_and_exit

  # handle ijkl as pacman direction change
  cmpb $23, buffer # i <=> up
  je .go_up
  cmp $36, buffer # j <=> left
  je .go_left
  cmp $37, buffer # k <=> down
  je .go_down
  cmp $38, buffer # l <=> right
  je .go_right

  # debug: print key press
  /* mov buffer, %rsi  # %rdi = caught signal code */
  /* mov $key_pressed, %rdi */
  /* xor %rax, %rax */
  /* call printf */


  jmp .readkey

.go_up:
  movl $0, PACMAN_DIRECTION_X
  movl $-1, PACMAN_DIRECTION_Y
  jmp .readkey
.go_left:
  movl $-1, PACMAN_DIRECTION_X
  movl $0, PACMAN_DIRECTION_Y
  jmp .readkey
.go_down:
  movl $0, PACMAN_DIRECTION_X
  movl $1, PACMAN_DIRECTION_Y
  jmp .readkey
.go_right:
  movl $1, PACMAN_DIRECTION_X
  movl $0, PACMAN_DIRECTION_Y
  jmp .readkey

.readkey_end:






  # move pacman

  mov PACMAN_DIRECTION_X, %rax
  addl %eax, PACMAN_X_RATIO

  # if x_ratio >= resolution, then x++
  cmpl $TILE_RESOLUTION, PACMAN_X_RATIO
  jne .check_pacman_x_min
  movl $0, PACMAN_X_RATIO
  addl $1, PACMAN_X
  jmp .move_pacman_y

.check_pacman_x_min:
  # if x_ratio < 0, then x--
  cmpl $-1, PACMAN_X_RATIO
  jne .move_pacman_y
  movl $TILE_RESOLUTION-1, PACMAN_X_RATIO
  subl $1, PACMAN_X

.move_pacman_y:
  mov PACMAN_DIRECTION_Y, %rax
  addl %eax, PACMAN_Y_RATIO

  # if y_ratio >= resolution, then y++
  cmpl $TILE_RESOLUTION, PACMAN_Y_RATIO
  jne .check_pacman_y_min
  movl $0, PACMAN_Y_RATIO
  addl $1, PACMAN_Y
  jmp .move_pacman_end

.check_pacman_y_min:
  # if y_ratio < 0, then y--
  cmpl $-1, PACMAN_Y_RATIO
  jne .move_pacman_end
  movl $TILE_RESOLUTION-1, PACMAN_Y_RATIO
  subl $1, PACMAN_Y
.move_pacman_end:





  call .draw_board



  # sleep for 1/30 second
  mov $SYS_NANOSLEEP, %rax
  mov $sleep_timeval, %rdi
  mov $0, %rsi
  syscall

  jmp .main_loop


#####################################
########## END MAIN LOOP ############
#####################################







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

  cmpb $35, buffer # # == wall
  je .read_board__wall

  cmpb $71, buffer # G == pacman
  je .read_board__pacman

  jmp .read_board__not_wall # == unknown

.read_board__wall:
  mov $TILE_WALL, %r8
  jmp .read_board__set_tile
.read_board__pacman:
  # set pacman pos
  movl %r12d, PACMAN_X
  movl %r13d, PACMAN_Y
  movl $0, PACMAN_X_RATIO
  movl $TILE_SIZE/2-2, PACMAN_Y_RATIO
  # pacman tile defaults to empty
  mov $TILE_EMPTY, %r8
  jmp .read_board__set_tile
.read_board__not_wall:
  mov $TILE_EMPTY, %r8
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
                # returns in r8b
  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  movb BOARD(%r14), %r8b
  ret




.set_tile_type: # x=r12, y=r13, type=r8b
                # uses r14 (as board index).
  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  movb %r8b, BOARD(%r14)
  ret




.draw_board: # uses r12 & r13 to loop through tiles
             # r14 & r15 to calculate stuff (cf draw_unicolor_tile)
             # r10 & r11 to draw the pixels
  mov $0, %r12 # tile_x
  mov $0, %r13 # tile_y

.draw_board__inc_x:
  call .get_tile_type
  cmpb $0, %r8b
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

  # all static stuff has been drawn
  # now, draw pacman & the ghosts
  # TODO ghosts



  # draw pacman

  mov $-PACMAN_SIZE/2, %r14
  mov $-PACMAN_SIZE/2, %r15
  mov $0xff0000, %r9
.pacman_draw_loop:
  imul $TILE_SIZE, PACMAN_X, %r10d
  mov $0, %rdx
  mov $0, %rax
  imul $TILE_SIZE, PACMAN_X_RATIO, %eax
  mov $TILE_RESOLUTION, %rcx
  idiv %rcx
  add %eax, %r10d

  imul $TILE_SIZE, PACMAN_Y, %r11d
  mov $0, %rdx
  mov $0, %rax
  imul $TILE_SIZE, PACMAN_Y_RATIO, %eax
  mov $TILE_RESOLUTION, %rcx
  idiv %rcx
  add %eax, %r11d

  add %r14, %r10
  add %r15, %r11

  call .draw_pixel
  add $1, %r14
  cmp $PACMAN_SIZE/2, %r14
  jne .pacman_draw_loop
  mov $-PACMAN_SIZE/2, %r14
  add $1, %r15
  cmp $PACMAN_SIZE/2, %r15
  jne .pacman_draw_loop

  # board is drawn (hopefully)
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

  mov %r13, %r11
  imul $TILE_SIZE, %r11
  add %r15, %r11

  call .draw_pixel
  add $1, %r14
  cmp $TILE_SIZE, %r14
  jne .draw_unicolor_tile__x

  add $1, %r15
  mov $0, %r14
  cmp $TILE_SIZE, %r15
  jne .draw_unicolor_tile__x
  ret


.signal_handler: # print stuff, cleanup & exit
  # print signal code
  mov %rdi, %rsi  # %rdi = caught signal code
  mov $signal_caught, %rdi
  xor %rax, %rax
  call printf




.cleanup_and_exit:
  # cleanup stdin & keyboard mode

  # restore stdin termios
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $TCSETS, %rsi # cmd
  mov $old_termios, %rdx # dump in
  syscall

  # reassure the user (or maybe just me) - the stdin is clean
  mov $SYS_WRITE, %rax
  mov $1, %rdi # stdout
  mov $stdin_restored, %rsi
  mov $stdin_restored_len, %rdx
  syscall

  # restore keyboard mode
  mov $SYS_IOCTL, %rax # ioctl
  mov $0, %rdi # stdin
  mov $KDSKBMODE, %rsi # cmd

  mov $0, %rdx # as we only move one byte to rdl, 0 the rest
  movb oldkbmode, %dl
  syscall

  # reassure the user (or maybe just me) - the stdin is clean
  mov $SYS_WRITE, %rax
  mov $1, %rdi # stdout
  mov $keyboard_mode_restored, %rsi
  mov $keyboard_mode_restored_len, %rdx
  syscall

  # exit
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
signal_caught:
  .asciz "signal caught: %d\n"
stdin_restored:
  .asciz "stdin mode restored\n"
  stdin_restored_len = . - stdin_restored
keyboard_mode_restored:
  .asciz "keyboard mode restored\n"
  keyboard_mode_restored_len = . - keyboard_mode_restored
old_keyboard_mode:
  .asciz "keyboard mode was: %d\n"
key_pressed:
  .asciz "key pressed/released: %d\n"
