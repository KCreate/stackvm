.include "constants.asm"

.label foo

.label bar

.label baz

.def VRAM_ADDR 0x400
.def VRAM_SIZE 36400



.org VRAM_ADDR
.db splashscreen VRAM_SIZE 0
