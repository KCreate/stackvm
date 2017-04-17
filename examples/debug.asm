.def target r0

.org 200
.label entry_addr
  loadi target, 255
  push qword, 255
  push dword, 255
  push word, 255
  push byte, 255

  rpop r1b
  rpop r1w
  rpop r1d
  rpop r1q
