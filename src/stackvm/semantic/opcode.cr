module StackVM::Semantic

  # Opcodes
  module OP

    # Registers
    RPUSH  = 0x00_u16 # Push the value of a register onto the stack
    RPOP   = 0x01_u16 # Pop the top of the stack into a register
    INCR   = 0x02_u16 # Increment the value inside a register by 1
    DECR   = 0x03_u16 # Decrement the value inside a register by 1
    MOV    = 0x04_u16 # Copies the contents of the source register into the target register

    # Arithmetic
    ADD    = 0x05_u16 # Push the sum of the top two values
    SUB    = 0x06_u16 # Push the difference of the top two values (lower - upper)
    MUL    = 0x07_u16 # Push the product of the top two values
    DIV    = 0x08_u16 # Push the quotient of the top two values
    REM    = 0x09_u16 # Push the remainder of the top two values (lower % upper)
    EXP    = 0x0A_u16 # Push the power of the top two values (lower ** upper)

    # Comparisons
    CMP    = 0x0B_u16 # Push 0 if the top two values are equal
    LT     = 0x0C_u16 # Push 0 if the second-highest value is less than the top
    GT     = 0x0D_u16 # Push 0 if the second-highest value is greater than the top
    LTE    = 0x0E_u16 # Push 0 if the second-highest value is less or equal than the top
    GTE    = 0x0F_u16 # Push 0 if the second-highest value is greater or equal than the top

    # Bitwise operations
    SHR    = 0x10_u16 # Shift the bits of the top value to the right n times (lower >> upper)
    SHL    = 0x11_u16 # Shift the bits of the top value to the left n times (lower << upper)
    AND    = 0x12_u16 # Push bitwise AND of the top two values
    XOR    = 0x13_u16 # Push bitwise OR of the top two values
    NAND   = 0x14_u16 # Push bitwise NAND of the top two values
    OR     = 0x15_u16 # Push bitwise OR of the top two values
    NOT    = 0x16_u16 # Push bitwise NOT on the top two values

    # Casting instructions
    TRUNC  = 0x17_u16 # Truncate a value from type1 to type2
    SE     = 0x18_u16 # Sign-extend a value from type1 to type2
    ZE     = 0x19_u16 # Zero-extend a value from type1 to type2

    # Stack instructions
    LOAD   = 0x1A_u16 # Load a type value located at (fp + offset)
    LOADR  = 0x1B_u16 # Load a type value located at (fp + [reg])
    LOADI  = 0x1C_u16 # Load an immediate type value
    STORE  = 0x1D_u16 # Pop a type value and save at (fp + offset)
    STORER = 0x1E_u16 # Pop a type value and save at (fp + [reg])
    INC    = 0x1F_u16 # Increment a type value at (fp + offset)
    DEC    = 0x20_u16 # Decrement a type value at (fp + offset)

    # Memory
    READ   = 0x21_u16 # Read a type value from address and push it onto the stack
    READR  = 0x22_u16 # Read a type value from [reg] and push it onto the stack
    WRITE  = 0x23_u16 # Read a type value from the stack and write it to address
    WRITER = 0x24_u16 # Read a type value from the stack and write it to [reg]
    COPY   = 0x25_u16 # Read a type value from source and write it to the given target
    COPYR  = 0x26_u16 # Read a type value from source and write it to [reg]

    # Jumps
    JZ     = 0x27_u16 # Relative or absolute jump to given offset if top of the stack is 0
    JZR    = 0x28_u16 # Relative or absolute jump to [reg] if top of the stack is 0
    JNZ    = 0x29_u16 # Relative or absolute jump to given offset if top of the stack is not 0
    JNZR   = 0x2A_u16 # Relative or absolute jump to [reg] if top of the stack is not 0
    JMP    = 0x2B_u16 # Unconditional relative or absolute jump to given offset
    JMPR   = 0x2C_u16 # Unconditional relative or absolute jump to [reg]
    CALL   = 0x2D_u16 # Relative or absolute jump to given offset, pushing a stack frame
    CALLR  = 0x2E_u16 # Relative or absolute jump to [reg], pushing a stack frame
    RET    = 0x2F_u16 # Return from the current stack frame

    # Miscellaneous
    NOP    = 0x30_u16 # Does nothing
    PUTS   = 0x31_u16 # Copy a type value from the stack into stdout
    HALT   = 0x32_u16 # Halts the machine with a given 1 byte exit code from the stack

    # Bitmasks
    M_S    = 0b10000000_00000000_u16 # Signed / Unsigned
    M_T    = 0b01000000_00000000_u16 # Integer / Floating-point
    M_B    = 0b00100000_00000000_u16 # 32-bit / 64-bit
    M_O    = 0b00011111_11111111_u16 # Instruction opcode
  end

end
