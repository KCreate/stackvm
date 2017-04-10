main:

  ; prepare registers for copy call
  loadi r0, qword, source1
  loadi r1, qword, target1
  copy r1, qword, r0

  copyc target2, qword, source2

.source1 qword 255
.target1 qword 0

.source2 qword 255
.target2 qword 0
