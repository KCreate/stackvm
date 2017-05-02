.def counter_x r0
.def counter_y r1
.def comp r2
.def s_zero r3
.def s_one r4

.label setup
.label entry_addr
  loadi counter_x, vram_width
  loadi counter_y, vram_height
  rst s_zero
  loadi s_one, 1

  sub counter_x, s_one
  sub counter_y, s_one

  push dword, msg_welcome
  push dword, 29
  push word, sys_write
  syscall

  push dword, msg_sleep
  push dword, 26
  push word, sys_write
  syscall

  push float, 3.0
  push word, sys_sleep
  syscall

  jmp main

.label main

  rpush counter_x
  rpush counter_y
  push byte, 0b11100011
  push dword, 9
  call gfx_draw_pixel

  jmp check_zero_reached1

.label check_zero_reached1
  cmp counter_x, s_zero
  jz check_zero_reached2
  jmp loop
.label check_zero_reached2
  cmp counter_y, s_zero
  jz quit_program
  jmp loop

.label loop

  cmp counter_x, s_zero
  jz br1

  sub counter_x, s_one

  jmp br2
.label br1
  sub counter_y, s_one
  loadi counter_x, vram_width
  sub counter_x, s_one

.label br2

  jmp main

.label quit_program
  push byte, 0
  push word, sys_exit
  syscall

.db msg_welcome 29 "welcome to the graphics demo\n"
.db msg_sleep 26 "sleeping for 3 seconds...\n"

.include "graphics.asm"
