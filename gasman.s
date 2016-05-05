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

.equ TIMEOUT, 30  # watchdog timeout - cf SIGALARM


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


# KEYS

.equ KEY_Q, 30
.equ KEY_G, 34
.equ KEY_I, 23
.equ KEY_J, 36
.equ KEY_K, 37
.equ KEY_L, 38

.lcomm UP_PRESSED, 1
.lcomm DOWN_PRESSED, 1
.lcomm LEFT_PRESSED, 1
.lcomm RIGHT_PRESSED, 1


# MISC

.equ FRAME_TIMEOUT, 16666666   # in nanosec
.equ ROUND_PAUSE, 1   # in sec

.lcomm fb_handle, 8
.lcomm screensize, 8
.lcomm fb_map, 8
.lcomm walls_handle, 8
.lcomm buffer, 1
.lcomm select_timeval, 16
.lcomm sleep_timeval, 8
.lcomm sleep_timeval_nano, 8

.lcomm debug_grid_on, 1

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

.equ RANDOM_SEED_MULTIPLIER, 1103515245
.equ RANDOM_SEED_INCREMENT, 12345
.lcomm LAST_RANDOM_NUMBER, 4



# BOARD

.equ TILE_SIZE, 16

.equ TILE_RESOLUTION, 1600

.equ BOARD_WIDTH, 28
.equ BOARD_HEIGHT, 36

.equ PIX_WIDTH, BOARD_WIDTH*TILE_SIZE
.equ PIX_HEIGHT, BOARD_HEIGHT*TILE_SIZE

.lcomm BOARD, BOARD_WIDTH*BOARD_HEIGHT

.equ CHAR_SIZE, 12


# TILE TYPES - as flags

# TILE_EMPTY (<SPACE>) => no flag
.equ TILE_WALL, 0x01 # #
.equ TILE_GHOST_WALL, 0x02
.equ TILE_DOT, 0x04 # .     or, if nohup + dot: |
.equ TILE_ENERGIZE, 0x08 # O
.equ TILE_TUNNEL, 0x10 # T
.equ TILE_NOHUP, 0x20 # _


# DIRECTIONS

.equ DIRECTION_X, 0
.equ DIRECTION_Y, 4
.equ DIRECTION_OPPOSITE, 8

.equ DIRECTION_STRUCT_SIZE, 12

.equ DIRECTION_NONE, 0
.equ DIRECTION_UP, DIRECTION_STRUCT_SIZE*1
.equ DIRECTION_LEFT, DIRECTION_STRUCT_SIZE*2
.equ DIRECTION_DOWN, DIRECTION_STRUCT_SIZE*3
.equ DIRECTION_RIGHT, DIRECTION_STRUCT_SIZE*4

.equ FIRST_DIRECTION, DIRECTION_UP
.equ LAST_DIRECTION, DIRECTION_RIGHT

DIRECTION_VALUES:  # x, y, opposite direction
  .long 0 , 0 , DIRECTION_NONE  # none
  .long 0 , -1, DIRECTION_DOWN  # up
  .long -1, 0 , DIRECTION_RIGHT  # left
  .long 0 , 1 , DIRECTION_UP  # down
  .long 1 , 0 , DIRECTION_LEFT  # right


# STATE
# positions are in tiles + ratio/TILE_RESOLUTION

  # pacman & ghosts got the same struct discribed below,
  # excepts that pacman doesnt have a home corner tile
  # note: everything is 4 byte
.equ CHAR_X, 0
.equ CHAR_X_RATIO, 4
.equ CHAR_Y, 8
.equ CHAR_Y_RATIO, 12
.equ CHAR_DIRECTION, 16
.equ CHAR_CORNER_TILE_X, 20
.equ CHAR_CORNER_TILE_Y, 24
.equ CHAR_START_X, 28
.equ CHAR_START_X_RATIO, 32
.equ CHAR_START_Y, 36
.equ CHAR_START_Y_RATIO, 40
.equ CHAR_CURRENT_MODE, 44
.equ CHAR_CURRENT_MODE_TIMEOUT, 48
.equ CHAR_SPEED, 52  # unit: resoltion / tick

.equ CHAR_STRUCT_SIZE, 56



.lcomm PACMAN, CHAR_STRUCT_SIZE

  # ghosts
.lcomm BLINKY, CHAR_STRUCT_SIZE
.lcomm PINKY, CHAR_STRUCT_SIZE
.lcomm INKY, CHAR_STRUCT_SIZE
.lcomm CLYDE, CHAR_STRUCT_SIZE

CHARACTERS:
  .quad PACMAN, BLINKY, PINKY, INKY, CLYDE, 0
GHOSTS:
  .quad BLINKY, PINKY, INKY, CLYDE, 0

.equ START_PACMAN_LIFES, 3
.lcomm PACMAN_LIFES, 4


# LEVELS

.equ PACMAN_STARTING_SPEED, 200
.equ GHOST_STARTING_SPEED, 160

.equ TUNNEL_GHOST_SPEED, GHOST_STARTING_SPEED/2



# GHOST MODES

.equ MODE_NONE, 0
.equ MODE_CHASE, 1
.equ MODE_SCATTER, 2
.equ MODE_FRIGHTENED, 3







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



  # initial random seed
  rdtsc
  movl %eax, LAST_RANDOM_NUMBER




# setup initial state

  # read the board
  call .read_board_from_file

  # pacman starts with 3 lifes
  movl $START_PACMAN_LIFES, PACMAN_LIFES


# game init
.spawn:

  # set everyone's position
  mov $0, %rdi  # array offset
.spawn__set_position:
  mov CHARACTERS(%rdi), %rsi
  cmp $0, %rsi  # the array is 0 terminated
  je .spawn__set_position_end

  movl CHAR_START_X(%rsi), %eax
  movl %eax, CHAR_X(%rsi)
  movl CHAR_START_Y(%rsi), %eax
  movl %eax, CHAR_Y(%rsi)
  movl CHAR_START_X_RATIO(%rsi), %eax
  movl %eax, CHAR_X_RATIO(%rsi)
  movl CHAR_START_Y_RATIO(%rsi), %eax
  movl %eax, CHAR_Y_RATIO(%rsi)

  movl $DIRECTION_NONE, CHAR_DIRECTION(%rsi)

  cmp $PACMAN, %rsi
  jne .spawn__set_position_is_ghost
  movl $PACMAN_STARTING_SPEED, CHAR_SPEED(%rsi)
  jmp .spawn__set_position_next

.spawn__set_position_is_ghost:
  movl $GHOST_STARTING_SPEED, CHAR_SPEED(%rsi)

.spawn__set_position_next:
  add $8, %rdi
  jmp .spawn__set_position
.spawn__set_position_end:


  # blinky starts going left
  mov $BLINKY, %rsi
  movl $DIRECTION_LEFT, CHAR_DIRECTION(%rsi)


  # draw the board & then sleep for 3 seconds before starting a new round
  call .draw_board

  movb $ROUND_PAUSE, sleep_timeval
  movl $0, sleep_timeval_nano

  mov $SYS_NANOSLEEP, %rax
  mov $sleep_timeval, %rdi
  mov $0, %rsi
  syscall

  # standard sleep is 1/60 s (used to keep 60 fps going)
  movb $0, sleep_timeval
  movl $FRAME_TIMEOUT, sleep_timeval_nano

  jmp .main_loop





.death:
  subl $1, PACMAN_LIFES
  cmp $0, PACMAN_LIFES
  je .game_over
  jmp .spawn





.game_over:
  jmp .cleanup_and_exit





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
  # check if we can read a key event from stdin (we cant directly read one as sys_read is blocking)
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

  # a key event is available - read it
  mov $SYS_READ, %rax # read
  mov $0, %rdi # stdin
  mov $buffer, %rsi
  mov $1, %rdx
  syscall


  # debug: print key press
  /* mov buffer, %rsi  # %rdi = caught signal code */
  /* mov $key_pressed, %rdi */
  /* xor %rax, %rax */
  /* call printf */


  # exit on 'q'
  cmpb $KEY_Q, buffer
  je .cleanup_and_exit

  # toggle grid on 'g'
  cmp $KEY_G, buffer
  jne .update_movement_key_status
  notb debug_grid_on

.update_movement_key_status:
  # update movement key status (= pressed while not released)

  # key code == lower 7 bits
  # key status (pressed/released) = highest bit

  # rax will contain the status
  movb buffer, %al
  notb %al
  shr $7, %al

  # rbx will contain the key code
  movb buffer, %bl
  andb $0x7f, %bl


  cmpb $KEY_I, %bl # i <=> up
  je .key_i_pressed
  cmpb $KEY_J, %bl # j <=> left
  je .key_j_pressed
  cmpb $KEY_K, %bl # k <=> down
  je .key_k_pressed
  cmpb $KEY_L, %bl # l <=> right
  je .key_l_pressed

  jmp .readkey

.key_i_pressed:
  movb %al, UP_PRESSED
  jmp .readkey
.key_j_pressed:
  movb %al, LEFT_PRESSED
  jmp .readkey
.key_k_pressed:
  movb %al, DOWN_PRESSED
  jmp .readkey
.key_l_pressed:
  movb %al, RIGHT_PRESSED
  jmp .readkey

.readkey_end:





  # handle ijkl as pacman direction change
  mov $PACMAN, %rsi  # pacman is the current char

  # only allow moves while on the middle of a tile
  # or if pacman if standing still (ie at the start)
.handle_pacman_moves:

  # check if pacman is standing still
  cmpl $DIRECTION_NONE, CHAR_DIRECTION(%rsi)
  je .pacman_can_change_direction

  # check if pacman is centered
.is_pacman_centered:
  cmpl $TILE_RESOLUTION/2, CHAR_X_RATIO(%rsi)
  jne .handle_pacman_move_end # not horizontally centered
  cmpl $TILE_RESOLUTION/2, CHAR_Y_RATIO(%rsi)
  jne .handle_pacman_move_end # not vertically centered

.pacman_can_change_direction:
  # store PACMAN_X & PACMAN_Y in r12 & r13 to easily check later if the next tile got no walls
  movl CHAR_X(%rsi), %r12d
  movl CHAR_Y(%rsi), %r13d

  cmpb $1, UP_PRESSED
  je .go_up
  cmpb $1, LEFT_PRESSED
  je .go_left
  cmpb $1, DOWN_PRESSED
  je .go_down
  cmpb $1, RIGHT_PRESSED
  je .go_right

  jmp .pacman_direction_safety_check

# for every new direction, check if there is no wall there
.go_up:
  dec %r13d
  call .get_tile_type
  andb $(TILE_WALL | TILE_GHOST_WALL), %r8b
  cmpb $0, %r8b  # ie %r8b doesnt contain any wall flag
  jne .pacman_direction_safety_check

  movl $DIRECTION_UP, CHAR_DIRECTION(%rsi)
  jmp .pacman_direction_safety_check

.go_left:
  dec %r12d
  call .get_tile_type
  andb $(TILE_WALL | TILE_GHOST_WALL), %r8b
  cmpb $0, %r8b  # ie %r8b doesnt contain any wall flag
  jne .pacman_direction_safety_check

  movl $DIRECTION_LEFT, CHAR_DIRECTION(%rsi)
  jmp .pacman_direction_safety_check

.go_down:
  inc %r13d
  call .get_tile_type
  andb $(TILE_WALL | TILE_GHOST_WALL), %r8b
  cmpb $0, %r8b  # ie %r8b doesnt contain any wall flag
  jne .pacman_direction_safety_check

  movl $DIRECTION_DOWN, CHAR_DIRECTION(%rsi)
  jmp .pacman_direction_safety_check

.go_right:
  inc %r12d
  call .get_tile_type
  andb $(TILE_WALL | TILE_GHOST_WALL), %r8b
  cmpb $0, %r8b  # ie %r8b doesnt contain any wall flag
  jne .pacman_direction_safety_check

  movl $DIRECTION_RIGHT, CHAR_DIRECTION(%rsi)

.pacman_direction_safety_check:

  # safety check: recheck if we really can go in the 'new' direction
  # allow to check if there was no direction change (both case of not pressing any keys and pressing the key not changing our direction) - if there is still a wall in front of us, stop pacman
  movl CHAR_X(%rsi), %r12d
  movl CHAR_Y(%rsi), %r13d
  movl CHAR_DIRECTION(%rsi), %eax
  addl (DIRECTION_VALUES+DIRECTION_X)(%eax), %r12d
  addl (DIRECTION_VALUES+DIRECTION_Y)(%eax), %r13d
  call .get_tile_type
  andb $(TILE_WALL | TILE_GHOST_WALL), %r8b
  cmpb $0, %r8b  # ie %r8b doesnt contain any wall flag
  je .handle_pacman_move_end
  movb $DIRECTION_NONE, CHAR_DIRECTION(%rsi)
  jmp .handle_pacman_move_end

.handle_pacman_move_end:





  # handle ghost direction change if they're centered on a tile
  mov $BLINKY, %rsi
.is_ghost_centered:
  cmpl $TILE_RESOLUTION/2, CHAR_X_RATIO(%rsi)
  jne .ghost_direction_change_end  # not horizontally centered
  cmpl $TILE_RESOLUTION/2, CHAR_Y_RATIO(%rsi)
  jne .ghost_direction_change_end  # not vertically centered

  # the ghost is centered: choose the next direction to take
  movl CHAR_DIRECTION(%rsi), %r9d  # current ghost direction - to check for the opposite one
  movl $FIRST_DIRECTION, %eax  # current direction beeing looked at
  movl $0xffffffff, %r10d  # current minimum distance
  movl %r9d, %r11d  # current minimum distance direction
.choose_ghost_direction_loop:
  cmpl %r9d, (DIRECTION_VALUES+DIRECTION_OPPOSITE)(%eax)
  je .choose_ghost_direction_next  # ghost can't go backwards

  movl CHAR_X(%rsi), %r12d  # current ghost position x
  movl CHAR_Y(%rsi), %r13d  # current ghost position y
  addl (DIRECTION_VALUES+DIRECTION_X)(%eax), %r12d
  addl (DIRECTION_VALUES+DIRECTION_Y)(%eax), %r13d
  call .get_tile_type
  andb $(TILE_WALL | TILE_GHOST_WALL), %r8b
  cmpb $0, %r8b  # ie %r8b doesnt contain any wall flag
  jne .choose_ghost_direction_next  # this direction is not possible

  # chase mode: TODO
  mov $PACMAN, %rbx
  subl CHAR_X(%rbx), %r12d  # r12 = tile x - target x
  imull %r12d, %r12d  # r12 = (x-x')^2
  subl CHAR_Y(%rbx), %r13d  # r13 = tile y - current y
  imull %r13d, %r13d  # r13 = (y-y')^2
  addl %r13d, %r12d  # r12 = (x-x')^2 + (y-y')^2
  mov %r12d, %r15d

  # scatter mode: TODO


  # frightened mode: move at random
  /* call .new_random_number */
  /* movl LAST_RANDOM_NUMBER, %r15d  # distance to the target tile */

  cmpl %r15d, %r10d
  jb .choose_ghost_direction_next
  mov %r15d, %r10d
  mov %eax, %r11d

.choose_ghost_direction_next:

  cmp $LAST_DIRECTION, %eax
  je .choose_ghost_direction_end
  add $DIRECTION_STRUCT_SIZE, %eax
  jmp .choose_ghost_direction_loop

.choose_ghost_direction_end:
  movl %r11d, CHAR_DIRECTION(%rsi)

.ghost_direction_change_end:





  # move pacman & the ghosts according to their direction

  mov $0, %rdi  # array offset
.move_char_loop:
  mov CHARACTERS(%rdi), %rsi
  cmp $0, %rsi  # the array is 0 terminated
  je .update_pacman_status
  call .move_char
  add $8, %rdi
  jmp .move_char_loop




.move_char:  # moves a character (in %rsi) according to its direction. handles board wrap & ratio update
  movl CHAR_DIRECTION(%rsi), %eax
  movl (DIRECTION_VALUES+DIRECTION_X)(%eax), %eax
  imull CHAR_SPEED(%rsi), %eax
  addl %eax, CHAR_X_RATIO(%rsi)

  # if x_ratio >= resolution, then x++
  cmpl $TILE_RESOLUTION, CHAR_X_RATIO(%rsi)
  jl .check_char_x_min
  subl $TILE_RESOLUTION, CHAR_X_RATIO(%rsi)
  addl $1, CHAR_X(%rsi)
  jmp .move_char_y

.check_char_x_min:
  # if x_ratio < 0, then x--
  cmpl $0, CHAR_X_RATIO(%rsi)
  jge .move_char_y
  addl $TILE_RESOLUTION, CHAR_X_RATIO(%rsi)
  subl $1, CHAR_X(%rsi)

.move_char_y:
  movl CHAR_DIRECTION(%rsi), %eax
  movl (DIRECTION_VALUES+DIRECTION_Y)(%eax), %eax
  imull CHAR_SPEED(%rsi), %eax
  addl %eax, CHAR_Y_RATIO(%rsi)

  # if y_ratio >= resolution, then y++
  cmpl $TILE_RESOLUTION, CHAR_Y_RATIO(%rsi)
  jl .check_char_y_min
  subl $TILE_RESOLUTION, CHAR_Y_RATIO(%rsi)
  addl $1, CHAR_Y(%rsi)
  jmp .move_char_end

.check_char_y_min:
  # if y_ratio < 0, then y--
  cmpl $0, CHAR_Y_RATIO(%rsi)
  jge .move_char_end
  addl $TILE_RESOLUTION, CHAR_Y_RATIO(%rsi)
  subl $1, CHAR_Y(%rsi)
.move_char_end:


  # if the char position overflows, wrap indexes

  # check if y < 0
  cmpl $0, CHAR_Y(%rsi)
  jge .char_overflow_check__y_sup_0
  addl $BOARD_HEIGHT, CHAR_Y(%rsi) # y < 0 => y = height + y
  jmp .char_overflow_check__y_inf_height

.char_overflow_check__y_sup_0:
  # check if y >= height
  cmpl $BOARD_HEIGHT, CHAR_Y(%rsi)
  jl .char_overflow_check__y_inf_height
  subl $BOARD_HEIGHT, CHAR_Y(%rsi) # y >= height => y = y - height
.char_overflow_check__y_inf_height:

  # check if x < 0
  cmpl $0, CHAR_X(%rsi)
  jge .char_overflow_check__x_sup_0
  addl $BOARD_WIDTH, CHAR_X(%rsi) # x < 0 => x = width + x
  jmp .char_overflow_check__x_inf_height

.char_overflow_check__x_sup_0:
  # check if x >= width
  cmpl $BOARD_WIDTH, CHAR_X(%rsi)
  jl .char_overflow_check__x_inf_height
  subl $BOARD_WIDTH, CHAR_X(%rsi) # x >= width => x = x - width
.char_overflow_check__x_inf_height:

  ret







.update_pacman_status:
  # check pacman position for stuff (dots, energizers & ghosts)
  mov $PACMAN, %rsi

  movl CHAR_X(%rsi), %r12d
  movl CHAR_Y(%rsi), %r13d
  call .get_tile_type

  # dot
  mov %r8b, %r9b
  andb $TILE_DOT, %r9b
  cmpb $0, %r9b
  jne .pacman_event__dot

  # energizer
  mov %r8b, %r9b
  andb $TILE_ENERGIZE, %r9b
  cmpb $0, %r9b
  jne .pacman_event__energizer

  jmp .pacman_event__end


.pacman_event__dot:
  mov $TILE_DOT, %r8b
  call .remove_flags_from_tile
  jmp .pacman_event__end

.pacman_event__energizer:
  mov $TILE_ENERGIZE, %r8b
  call .remove_flags_from_tile
  jmp .pacman_event__end

.pacman_event__end:



  # ghosts
  mov $0, %rdi  # array offset
.check_ghost_collision:
  mov GHOSTS(%rdi), %rsi
  cmp $0, %rsi  # the array is 0 terminated
  je .check_ghost_collision_end

  cmpl %r12d, CHAR_X(%rsi)
  jne .check_ghost_collision_next
  cmpl %r13d, CHAR_Y(%rsi)
  jne .check_ghost_collision_next

  # there was a collision: die
  jmp .death

.check_ghost_collision_next:
  add $8, %rdi
  jmp .check_ghost_collision
.check_ghost_collision_end:






  # update ghost speeds if they're in the tunnel or not
  mov $0, %rdi  # array offset
.update_ghost_speed:
  mov GHOSTS(%rdi), %rsi
  cmp $0, %rsi  # the array is 0 terminated
  je .update_ghost_speed_end

  movl CHAR_X(%rsi), %r12d  # current ghost position x
  movl CHAR_Y(%rsi), %r13d  # current ghost position y
  call .get_tile_type
  andb $TILE_TUNNEL, %r8b
  cmpb $0, %r8b
  je .update_ghost_speed_normal # no tunnel: set normal speed

  movl $TUNNEL_GHOST_SPEED, CHAR_SPEED(%rsi)
  jmp .update_ghost_speed_next

.update_ghost_speed_normal:
  movl $GHOST_STARTING_SPEED, CHAR_SPEED(%rsi)


.update_ghost_speed_next:
  add $8, %rdi
  jmp .update_ghost_speed
.update_ghost_speed_end:







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

  cmpb $32, buffer # <space> == empty
  je .read_board__empty

  cmpb $46, buffer # . == dot
  je .read_board__dot

  cmpb $79, buffer # O == energizer
  je .read_board__energizer

  cmpb $95, buffer # _ == no hup
  je .read_board__nohup

  cmpb $124, buffer # | == no hup + dot
  je .read_board__nohup_and_dot

  cmpb $84, buffer # T == tunnel
  je .read_board__tunnel

  cmpb $94, buffer # ^ == ghost wall
  je .read_board__ghost_wall

  cmpb $66, buffer # B == blinky's start
  je .read_board__blinky

  cmpb $98, buffer # b == blinky's corner
  je .read_board__blinky_corner

  cmpb $73, buffer # I == inky's start
  je .read_board__inky

  cmpb $105, buffer # i == inky's corner
  je .read_board__inky_corner

  cmpb $80, buffer # P == pinky's start
  je .read_board__pinky

  cmpb $112, buffer # p == pinky's corner
  je .read_board__pinky_corner

  cmpb $67, buffer # C == clyde's start
  je .read_board__clyde

  cmpb $99, buffer # c == clyde's corner
  je .read_board__clyde_corner

  jmp .read_board__empty # == unknown



.read_board__empty:
  mov $0, %r8
  jmp .read_board__set_tile

.read_board__wall:
  mov $TILE_WALL, %r8
  jmp .read_board__set_tile

.read_board__dot:
  mov $TILE_DOT, %r8
  jmp .read_board__set_tile

.read_board__energizer:
  mov $TILE_ENERGIZE, %r8
  jmp .read_board__set_tile

.read_board__nohup:
  mov $TILE_NOHUP, %r8
  jmp .read_board__set_tile

.read_board__nohup_and_dot:
  mov $(TILE_NOHUP | TILE_DOT), %r8
  jmp .read_board__set_tile

.read_board__tunnel:
  mov $TILE_TUNNEL, %r8
  jmp .read_board__set_tile

.read_board__ghost_wall:
  mov $TILE_GHOST_WALL, %r8
  jmp .read_board__set_tile

.read_board__pacman:
  mov $PACMAN, %rsi  # set current char to pacman
  jmp .read_board__character_spawn

.read_board__blinky:
  mov $BLINKY, %rsi
  jmp .read_board__character_spawn

.read_board__inky:
  mov $INKY, %rsi
  jmp .read_board__character_spawn

.read_board__pinky:
  mov $PINKY, %rsi
  jmp .read_board__character_spawn

.read_board__clyde:
  mov $CLYDE, %rsi
  jmp .read_board__character_spawn

.read_board__blinky_corner:
  mov $BLINKY, %rsi
  jmp .read_board__character_corner

.read_board__inky_corner:
  mov $INKY, %rsi
  jmp .read_board__character_corner

.read_board__pinky_corner:
  mov $PINKY, %rsi
  jmp .read_board__character_corner

.read_board__clyde_corner:
  mov $CLYDE, %rsi
  jmp .read_board__character_corner


.read_board__character_spawn:
  # uses %rsi as the current character
  # set pos
  movl %r12d, CHAR_START_X(%rsi)
  movl %r13d, CHAR_START_Y(%rsi)
  movl $0, CHAR_START_X_RATIO(%rsi)
  movl $TILE_RESOLUTION/2, CHAR_START_Y_RATIO(%rsi)
  # character tile defaults to empty
  mov $0, %r8
  jmp .read_board__set_tile

.read_board__character_corner:
  # uses %rsi as the current character
  # set pos
  movl %r12d, CHAR_CORNER_TILE_X(%rsi)
  movl %r13d, CHAR_CORNER_TILE_Y(%rsi)
  # corner tile defaults to empty
  mov $0, %r8
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





.get_tile_type: # x=r12, y=r13
                # uses r14 (as board index).
                # x & y can overflow (ie <0 or >board_width/height - they be wrapped
                # returns in r8b

  # backup indexes as we'll modify them if they overflow
  push %r12
  push %r13
  push %r14

  # check if y < 0
  cmpl $0, %r13d
  jge .get_tile_type__y_sup_0
  addl $BOARD_HEIGHT, %r13d  # y < 0 => y = height + y
  jmp .get_tile_type__y_inf_height

.get_tile_type__y_sup_0:
  # check if y >= height
  cmpl $BOARD_HEIGHT, %r13d
  jl .get_tile_type__y_inf_height
  subl $BOARD_HEIGHT, %r13d # y >= height => y = y - height
.get_tile_type__y_inf_height:

  # check if x < 0
  cmpl $0, %r12d
  jge .get_tile_type__x_sup_0
  addl $BOARD_WIDTH, %r12d  # x < 0 => x = width + x
  jmp .get_tile_type__x_inf_height

.get_tile_type__x_sup_0:
  # check if x >= width
  cmpl $BOARD_WIDTH, %r12d
  jl .get_tile_type__x_inf_height
  subl $BOARD_WIDTH, %r12d # x >= width => x = x - width
.get_tile_type__x_inf_height:

  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  movb BOARD(%r14), %r8b

  # restore indexes
  pop %r14
  pop %r13
  pop %r12

  ret




.set_tile_type: # x=r12, y=r13, type=r8b
                # no index overflow is allowed
                # uses r14 (as board index).
  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  movb %r8b, BOARD(%r14)
  ret


.add_flags_to_tile: # x=r12, y=r13, flags=r8b
                    # no index overflow is allowed
                    # uses r14 (as board index).
  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  orb %r8b, BOARD(%r14)
  ret


.remove_flags_from_tile: # x=r12, y=r13, flags=r8b
                         # no index overflow is allowed
                         # uses r14 (as board index).

  mov $BOARD_WIDTH, %r14
  imul %r13, %r14
  add %r12, %r14
  notb %r8b
  andb %r8b, BOARD(%r14)

  notb %r8b  # restore r8 register

  ret





.draw_board: # uses r12 & r13 to loop through tiles
             # r14 & r15 to calculate stuff (cf draw_unicolor_tile)
             # r10 & r11 to draw the pixels
  mov $0, %r12 # tile_x
  mov $0, %r13 # tile_y

.draw_board__inc_x:
  call .get_tile_type

  cmpb $TILE_WALL, %r8b
  je .draw_board__wall

  cmpb $TILE_GHOST_WALL, %r8b
  je .draw_board__ghost_wall

  mov %r8b, %r9b
  andb $TILE_DOT, %r9b
  cmpb $0, %r9b
  jne .draw_board__dot

  mov %r8b, %r9b
  andb $TILE_ENERGIZE, %r9b
  cmpb $0, %r9b
  jne .draw_board__energize

  jmp .draw_board__empty


.draw_board__wall:
  mov $0x0000ff, %r9
  call .draw_unicolor_tile
  jmp .draw_board__afterdraw

.draw_board__ghost_wall:
  mov $0x0000aa, %r9
  call .draw_unicolor_tile
  jmp .draw_board__afterdraw

.draw_board__dot:
  mov $0x444444, %r9
  call .draw_unicolor_tile
  jmp .draw_board__afterdraw

.draw_board__energize:
  mov $0x666666, %r9
  call .draw_unicolor_tile
  jmp .draw_board__afterdraw

.draw_board__empty:
  mov $0x000000, %r9
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
  # then draw the debug grid on top

  mov $PACMAN, %rsi  # set current char to pacman
  mov $0xffff00, %r9  # pacman is yellow
  call .draw_char

  mov $BLINKY, %rsi
  mov $0xff0000, %r9
  call .draw_char

  mov $INKY, %rsi
  mov $0x00ffff, %r9
  call .draw_char

  mov $PINKY, %rsi
  mov $0xff00ff, %r9
  call .draw_char

  mov $CLYDE, %rsi
  mov $0xff8000, %r9
  call .draw_char

  jmp .draw_debug_grid



.draw_char:  # will draw the char pointed by %rsi, wiht %r9 as the color
  mov $-CHAR_SIZE/2+1, %r14
  mov $-CHAR_SIZE/2+1, %r15
.char_draw_loop:
  imul $TILE_SIZE, CHAR_X(%rsi), %r10d
  mov $0, %rdx
  mov $0, %rax
  imull $TILE_SIZE, CHAR_X_RATIO(%rsi), %eax
  mov $TILE_RESOLUTION, %rcx
  idiv %rcx
  add %eax, %r10d

  imul $TILE_SIZE, CHAR_Y(%rsi), %r11d
  mov $0, %rdx
  mov $0, %rax
  imul $TILE_SIZE, CHAR_Y_RATIO(%rsi), %eax
  mov $TILE_RESOLUTION, %rcx
  idiv %rcx
  add %eax, %r11d

  add %r14, %r10
  add %r15, %r11

  call .draw_pixel_with_overflow_checks
  add $1, %r14
  cmp $CHAR_SIZE/2, %r14
  jne .char_draw_loop
  mov $-CHAR_SIZE/2+1, %r14
  add $1, %r15
  cmp $CHAR_SIZE/2, %r15
  jne .char_draw_loop
  ret



.draw_debug_grid:
  # draw debug grid
  cmp $0, debug_grid_on
  je .draw_debug_end

  mov $0x000000, %r9

  # draw lines
  mov $0, %r10  # x in pixels
  mov $0, %r11  # y in pixels
.draw_debug_x:
  call .draw_pixel
  inc %r10
  cmp $PIX_WIDTH, %r10
  jne .draw_debug_x
  mov $0, %r10
  add $TILE_SIZE, %r11
  cmp $PIX_HEIGHT, %r11
  jne .draw_debug_x

  # draw columns
  mov $0, %r10
  mov $0, %r11
.draw_debug_y:
  call .draw_pixel
  inc %r11
  cmp $PIX_HEIGHT, %r11
  jne .draw_debug_y
  mov $0, %r11
  add $TILE_SIZE, %r10
  cmp $PIX_WIDTH, %r10
  jne .draw_debug_y
.draw_debug_end:



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



.draw_pixel_with_overflow_checks:  # like .draw_pixel, but with overflow checks
                                   # 2 different functions are made as we dont want the useless checks in draw_pixel if we're sure there are no overflows

  # backup x & y
  push %r10
  push %r11

  # check if y < 0
  cmp $0, %r11
  jge .draw_pixel_overflow_check__y_sup_0
  add $PIX_HEIGHT, %r11  # y < 0 => y = height + y
  jmp .draw_pixel_overflow_check__y_inf_height

.draw_pixel_overflow_check__y_sup_0:
  # check if y >= height
  cmp $PIX_HEIGHT, %r11
  jl .draw_pixel_overflow_check__y_inf_height
  sub $PIX_HEIGHT, %r11 # y >= height => y = y - height
.draw_pixel_overflow_check__y_inf_height:

  # check if x < 0
  cmp $0, %r10
  jge .draw_pixel_overflow_check__x_sup_0
  add $PIX_WIDTH, %r10  # x < 0 => x = width + x
  jmp .draw_pixel_overflow_check__x_inf_height

.draw_pixel_overflow_check__x_sup_0:
  # check if x >= width
  cmp $PIX_WIDTH, %r10
  jl .draw_pixel_overflow_check__x_inf_height
  sub $PIX_WIDTH, %r10 # x >= width => x = x - width
.draw_pixel_overflow_check__x_inf_height:

  call .draw_pixel

  # restore x & y
  pop %r11
  pop %r10

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



.new_random_number:  # LCG
  push %rax
  movl LAST_RANDOM_NUMBER, %eax
  imull $RANDOM_SEED_MULTIPLIER, %eax
  addl $RANDOM_SEED_INCREMENT, %eax
  movl %eax, LAST_RANDOM_NUMBER
  pop %rax
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
