main:

  ; push arguments
  push qword, 0
  push qword, 1
  push qword, 2
  push dword, 16
  call myfunction

  ; check that return works
  loadi r20, 4, [115, 117, 99, 99]

myfunction:
  load r0, qword, -20
  load r1, qword, -12

  ; write return value
  loadi r3, qword, 255
  store -28, r3

  ret
