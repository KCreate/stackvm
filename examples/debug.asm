; this program flips 255 pixels in the vram section on and off

; registers used by this program
.def r_vram_ptr     r0  ; pointer to vram
.def r_vram_index   r1b ; index 0 - 255
.def r_vram_offset  r2  ; absolute pointer into vram
.def r_one          r3b ; static 1
.def r_increment    r4b ; amount that get's added to each pixel
.def r_calc         r5b ; calculation register

; machine startup and register initialisation
.label entry_addr
.label init
  loadi r_vram_ptr,     VRAM_ADDRESS
  loadi r_vram_index,   0
  loadi r_vram_offset,  0
  loadi r_one,          1
  loadi r_increment,    16
  loadi r_calc,         0
  jmp loop

; main machine loop
.label loop

  ; increment the base pointer
  rst r_vram_offset
  add r_vram_index, r_vram_index, r_one           ; increment index
  add r_vram_offset, r_vram_offset, r_vram_ptr    ; add the vram ptr
  add r_vram_offset, r_vram_offset, r_vram_index  ; add the index

  ; increment the pixel at the current offset
  read r_calc, r_vram_offset                      ; read the current pixel
  add r_calc, r_calc, r_increment                 ; increment the current pixel
  write r_vram_offset, r_calc                     ; update the pixel

  ; sleep for 10 millisecond
  push float64, 0.002
  push word, 1
  syscall

  jmp loop
