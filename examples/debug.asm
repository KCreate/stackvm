main:

  loadi r0, qword, 25

  push qword, 124
  push word, 1
  syscall

  push qword, 0
  push word, 1
  syscall

  push qword, 255
  push word, 1
  syscall

  ; exit
  push byte, 0
  push word, 0
  syscall
