; this program flips 255 pixels in the vram section on and off

; registers used by this program
.def r_vram_ptr     r0  ; pointer to vram
.def r_vram_offset  r1  ; absolute pointer into vram
.def r_one          r2  ; static 1
.def r_increment    r3  ; amount that get's added to each pixel
.def r_calc         r4b ; calculation register
.def r_cmp          r5  ; comparison register
.def r_memsize      r6  ; holds the memory size of the machine

; constants
.def increment_amount   1
.def vram_limit         38400 ; 240 * 160 bytes for each pixel

; machine startup and register initialisation
.label entry_addr
.label init
  loadi r_vram_ptr,      VRAM_ADDRESS
  loadi r_vram_offset,   VRAM_ADDRESS
  loadi r_one,           1
  loadi r_increment,     increment_amount
  loadi r_calc,          0
  loadi r_memsize,       memory_size

  sub r_vram_offset, r_one ; correct offset pointer

  jmp loop

; main machine loop
.label loop

  ; increment the base pointer
  add r_vram_offset, r_one         ; increment the offset

  ; check if we overflowed the vram section
  ; if we did, we will reset our index to zero
  ; and thus start over from the beginning
  cmp r_memsize, r_vram_offset
  jz init

  ; increment the pixel at the current offset
  read r_calc, r_vram_offset                      ; read the current pixel
  add r_calc, r_increment                 ; increment the current pixel
  write r_vram_offset, r_calc                     ; update the pixel

  jmp loop
