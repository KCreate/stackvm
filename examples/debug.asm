main:

  ; prepare stack
  push byte, 255
  push byte, 127

  ; write to constants
  loadi r0, qword, byte1
  writes r0, byte

  writecs byte2, byte

.byte1 byte 0
.byte2 byte 0
