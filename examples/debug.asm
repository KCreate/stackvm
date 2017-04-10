main:

  ; exit
  push word, 0
  syscall

  ; debugger
  push word, 1
  syscall

  ; debugger
  push word, 1
  syscall

  ; debugger
  push word, 1
  syscall

  ; grow
  push word, 2
  syscall
