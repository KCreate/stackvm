.include "constants.asm"

.def VRAM_ADDR 0x400

.db a qword 255

.org VRAM_ADDR

.db b qword 255
