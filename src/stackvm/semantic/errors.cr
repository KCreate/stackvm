module StackVM::Semantic

  # Error codes the machine will use on exit
  enum Err : UInt8
    REGULAR_EXIT          = 0x00 # Regular exit
    STACKOVERFLOW         = 0x00 # Operation would overflow the stack
    STACKUNDERFLOW        = 0x01 # Operation would underflow the stack
    ILLEGAL_MEMORY_ACCESS = 0x02 # Memory read and write is out-of-bounds
    INVALID_INSTRUCTION   = 0x03 # Unknown instruction
    INVALID_REGISTER      = 0x04 # Unknown register
    INVALID_JUMP          = 0x05 # Jump out of bounds
    OUT_OF_MEMORY         = 0x06 # Not enough memory
  end

end
