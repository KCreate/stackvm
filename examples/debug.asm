main:
  loadi flagsb, byte, 4
  jz myfunction
  nop
  nop
  nop

myfunction:
  loadi r0, qword, 255

  loadi r2, qword, myotherfunction
  jzr r2
  nop
  nop
  nop

myotherfunction:
  loadi r1, qword, 255
