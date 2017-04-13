; this program flips 255 bytes starting at data
; on and off in a loop

main:

  ; prepare registers
  loadi r0, qword, data   ; pointer to data segment
  loadi r1, byte, 0       ; pointer offset
  loadi r2, qword, 0      ; absolute pointer to current byte
  loadi r3, byte, 1       ; static 1
  loadi r4, byte, 16      ; amount that get's added to the bytes each time
  loadi r5, byte, 0       ; serves as our calculation register

loop:

  ; increment the base pointer
  rst r2                  ; clear r2
  add r1, r1b, r3b        ; increment pointer offset
  add r2, r2b, r0b        ; add base pointer to absolute offset
  add r2, r2b, r1b        ; add relative offset to absolute offset

  ; read the current byte into r6
  read r5b, r2            ; read the byte at the current absolute offset into r6b
  add r5b, r5, r4         ; increment the byte
  write r2, r5b           ; store the byte back at it's original location

  push dword, 1           ; millisecond
  push word, 3            ; sleep
  syscall

  ; go back
  jmp loop

; base pointer of the data area
.data byte 0
