module Constants

  # Default memory size of the machine
  MEMORY_SIZE = 8_000_000

  # Initial position of the stack pointer
  STACK_BASE = 0x00400000

  # Pointer to the machine internals segment
  MACHINE_INTERNALS_PTR = 0x00400000

  # Size of the machine internals segment
  MACHINE_INTERNALS_SIZE = 3_767_274

  # Address of the interrupt handler
  INTERRUPT_HANDLER_ADDRESS = 0x00797bea

  # Address of interrupt memory
  INTERRUPT_MEMORY = 0x00797bee

  # Size of the interrupt memory section
  INTERRUPT_MEMORY_SIZE = 16

  # Address of the interrupt code
  INTERRUPT_CODE = 0x00797bfe

  # Address of interrupt status
  INTERRUPT_STATUS = 0x00797bff

  # Address of video ram
  VRAM_ADDRESS = 0x00797c00

  # Size of video ram (240 * 160 pixels)
  VRAM_SIZE = 38400

  # Dimensions of the monitor
  VRAM_WIDTH  = 240
  VRAM_HEIGHT = 160
end
