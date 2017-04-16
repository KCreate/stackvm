.org 0x40
.label foo

.org 0x20
.label bar

.org 0x00
loadi r0, foo
loadi r0, bar
