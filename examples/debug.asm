; setup
.def calc1 r0
.def calc2 r1
.def exitreg r59

; main entry code
.label entry_addr
.label main
  push dword, 0
  push dword, 25
  push dword, 25
  push dword, qword
  call @"my nice function"

  rpop exitreg

.org 0x200
.label @"my nice function"
  load calc1, 16
  load calc2, 12
  add calc1, calc1, calc2
  store 20, calc1
  ret
