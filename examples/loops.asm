; Define some constants
.def counter    r0 ; counter register
.def calc1      r1 ; used for calculations
.def calc2      r2

.def s_one      r4 ; static one
.def s_zero     r5 ; static zero

.label entry_addr
.label setup

  ; setup registers
  loadi counter,    100
  loadi s_one,      1
  loadi s_zero,     0

  ; print the welcome and description messages
  push t_address,   msg_welcome
  push t_size,      10
  push t_syscall,   sys_write
  syscall

  push t_address,   msg_description
  push t_size,      39
  push t_syscall,   sys_write
  syscall

.label loop

  ; print the current number
  push t_register, counter
  push t_syscall, sys_puts
  syscall

  ; exit if zero was reached
  cmp counter, s_zero
  jz _exit

  ; decrement the counter
  sub counter, s_one

  ; repeat
  jmp loop

; exit the program
.label _exit

  ; write the goodbye message
  push t_address,   msg_goodbye
  push t_size,      10
  push t_syscall,   sys_write
  syscall

  ; exit the program
  push byte,        0
  push t_syscall,   sys_exit
  syscall


; string constants
.db msg_welcome 10 "Welcome!!\n"
.db msg_description 39 "This program counts from 100 down to 0\n"
.db msg_goodbye 10 "Goodbye!!\n"
