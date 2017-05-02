.org 0x00
.label entry_addr
.label main

  push t_address,   myconst
  push t_size,      12
  push t_syscall,   sys_write
  syscall

  push float,       0.1
  push t_syscall,   sys_sleep
  syscall

  jmp main

.db myconst 12 "hello world\n"
