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
  call add

  rpop exitreg

; Load the add method into address 0x200
.org 0x200
.label add
  load calc1, -12
  load calc2, -8
  add calc1, calc1, calc2
  store -16, calc1
  ret
