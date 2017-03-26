module StackVM::Semantic

  # Opcodes
  enum OP : UInt16

    # Registers
    RPUSH  = 0x00 # Push the value of a register onto the stack
    RPOP   = 0x01 # Pop the top of the stack into a register
    INCR   = 0x02 # Increment the value inside a register by 1
    DECR   = 0x03 # Decrement the value inside a register by 1
    MOV    = 0x04 # Copies the contents of the source register into the target register

    # Arithmetic
    ADD    = 0x05 # Push the sum of the top two values
    SUB    = 0x06 # Push the difference of the top two values (lower - upper)
    MUL    = 0x07 # Push the product of the top two values
    DIV    = 0x08 # Push the quotient of the top two values
    REM    = 0x09 # Push the remainder of the top two values (lower % upper)
    EXP    = 0x0A # Push the power of the top two values (lower ** upper)

    # Comparisons
    CMP    = 0x0B # Push 0 if the top two values are equal
    LT     = 0x0C # Push 0 if the second-highest value is less than the top
    GT     = 0x0D # Push 0 if the second-highest value is greater than the top
    LTE    = 0x0E # Push 0 if the second-highest value is less or equal than the top
    GTE    = 0x0F # Push 0 if the second-highest value is greater or equal than the top

    # Bitwise operations
    SHR    = 0x10 # Shift the bits of the top value to the right n times (lower >> upper)
    SHL    = 0x11 # Shift the bits of the top value to the left n times (lower << upper)
    AND    = 0x12 # Push bitwise AND of the top two values
    XOR    = 0x13 # Push bitwise OR of the top two values
    NAND   = 0x14 # Push bitwise NAND of the top two values
    OR     = 0x15 # Push bitwise OR of the top two values
    NOT    = 0x16 # Push bitwise NOT on the top two values

    # Casting instructions
    TRUNC  = 0x17 # Truncate a value from type1 to type2
    SE     = 0x18 # Sign-extend a value from type1 to type2
    ZE     = 0x19 # Zero-extend a value from type1 to type2

    # Stack instructions
    LOAD   = 0x1A # Load a type value located at (fp + offset)
    LOADR  = 0x1B # Load a type value located at (fp + [reg])
    LOADI  = 0x1C # Load an immediate type value
    STORE  = 0x1D # Pop a type value and save at (fp + offset)
    STORER = 0x1E # Pop a type value and save at (fp + [reg])
    INC    = 0x1F # Increment a type value at (fp + offset)
    DEC    = 0x20 # Decrement a type value at (fp + offset)

    # Memory
    READ   = 0x21 # Read a type value from address and push it onto the stack
    READR  = 0x22 # Read a type value from [reg] and push it onto the stack
    WRITE  = 0x23 # Read a type value from the stack and write it to address
    WRITER = 0x24 # Read a type value from the stack and write it to [reg]
    COPY   = 0x25 # Read a type value from source and write it to the given target
    COPYR  = 0x26 # Read a type value from source and write it to [reg]

    # Jumps
    JZ     = 0x27 # Relative or absolute jump to given offset if top of the stack is 0
    JZR    = 0x28 # Relative or absolute jump to [reg] if top of the stack is 0
    JNZ    = 0x29 # Relative or absolute jump to given offset if top of the stack is not 0
    JNZR   = 0x2A # Relative or absolute jump to [reg] if top of the stack is not 0
    JMP    = 0x2B # Unconditional relative or absolute jump to given offset
    JMPR   = 0x2C # Unconditional relative or absolute jump to [reg]
    CALL   = 0x2D # Relative or absolute jump to given offset, pushing a stack frame
    CALLR  = 0x2E # Relative or absolute jump to [reg], pushing a stack frame
    RET    = 0x2F # Return from the current stack frame

    # Miscellaneous
    NOP    = 0x30 # Does nothing
    PUTS   = 0x31 # Copy a type value from the stack into stdout
    HALT   = 0x32 # Halts the machine with a given 1 byte exit code from the stack

    # Bitmasks
    M_S    = 0b1000000000000000 # Signed / Unsigned
    M_T    = 0b0100000000000000 # Integer / Floating-point
    M_B    = 0b0010000000000000 # 32-bit / 64-bit
    M_O    = 0b0001111111111111 # Instruction opcode
  end

end
