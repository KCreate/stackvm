; Constant definitions
.def GFX_TMP                  r58
.def GFX_TMP2                 r59
.def GFX_TMP_BYTE             r58b

; void gfx_draw_pixel(int x, int y, byte color)
; x     : 17
; y     : 13
; color : 12
.label gfx_draw_pixel
  .def gfx_draw_pixel_offset      r0
  .def gfx_draw_pixel_arg_x       17
  .def gfx_draw_pixel_arg_y       13
  .def gfx_draw_pixel_arg_color   12

  ; backup register
  rpush gfx_draw_pixel_offset

  ; calculate offset into vram
  loadi gfx_draw_pixel_offset, VRAM_ADDRESS
  load GFX_TMP, gfx_draw_pixel_arg_x
  add gfx_draw_pixel_offset, GFX_TMP
  load GFX_TMP, gfx_draw_pixel_arg_y
  loadi GFX_TMP2, VRAM_WIDTH
  mul GFX_TMP, GFX_TMP2
  add gfx_draw_pixel_offset, GFX_TMP

  ; write the color
  load GFX_TMP_BYTE, gfx_draw_pixel_arg_color
  write gfx_draw_pixel_offset, GFX_TMP_BYTE

  ; restore registers
  rpop gfx_draw_pixel_offset

  ret
