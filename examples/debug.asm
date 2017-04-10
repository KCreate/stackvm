main:
  loadi r0, qword, 127
  loadi r1, qword, myqword
  write r1, r0

  loadi r0, qword, 255
  writec myqword, r0

.myqword qword 0
