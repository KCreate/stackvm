; Instructions:
;
; ./stackvm build keyboard-input.asm -o out.bc
; ./stackvm run out.bc
; ./stackvm monitor machine.memory -s 2
;
; Focus the window opened by the monitor command
; and press some keys on your keyboard. You should now
; see some stuff popping up in the terminal off the run command

; Configure the interrupt handler's address
.org INTERRUPT_HANDLER_ADDRESS
.db _interrupt_handler_address t_address my_interrupt_handler

.org INTERRUPT_MEMORY
.db _interrupt_memory INTERRUPT_MEMORY_SIZE 0

.org 0x00

.db io_buffer 255 0
.def io_cursor r0

.label entry_addr

  ; execute the main function
  push t_size, 0
  call main

  ; exit the program
  push byte, 0
  push t_syscall, sys_exit
  syscall

.label main
  nop
  jmp main

.label my_interrupt_handler

  ; skip if this is a keydown
  readc r2b, INTERRUPT_KEYBOARD_KEYDOWN
  loadi r3b, 1
  cmp r2b, r3b
  jz read_char
  ret

.label read_char

  ; calculate the cursor offset
  mov r1, io_cursor
  loadi r2, io_buffer
  add r1, r2

  ; copy the char
  readc r2b, INTERRUPT_KEYBOARD_SYM
  write r1, r2b

  ; increment the io cursor
  push t_size, 0x0
  call increment_io_cursor

  push t_size, 0x0
  call print_io_buffer

  ret

.label increment_io_cursor
  mov r1, io_cursor
  loadi r2, 1
  add r1, r2
  mov io_cursor, r1
  ret

.label print_io_buffer
  mov r1, INTERRUPT_MEMORY
  mov r2, io_cursor
  add r2, r1

.label loop
  cmp r1, r2
  jz loop_end

  rpush r1
  push t_size, byte
  push t_syscall, sys_write
  syscall

  loadi r3, 1
  add r1, r3

  jmp loop

.label loop_end
  push byte, 13
  rpush sp
  push t_size, 1
  push t_syscall, sys_write
  syscall

  loadi r59, 1
  add sp, r59
  ret

; Note to future self
; Somewhere is a bug which causes an invalid jump to 0x3a
; in the case when an interrupt happens inside an interrupt handler
;
; this is likely an issue of us not producing a correct stack frame
; and thus making it jump to some weird address
;
; something worth to investiage:
; 0x3a = 58 = syscall
;
; maybe the ret instruction tries to jump to an opcodes value ???
