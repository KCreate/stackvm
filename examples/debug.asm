main:

  push qword, 124
  push word, 1
  syscall

  push qword, 0
  push word, 1
  syscall

  push qword, 255
  push word, 1
  syscall
