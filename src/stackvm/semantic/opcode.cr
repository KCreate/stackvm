module StackVM::Semantic

  # Opcodes
  module OP

    # Registers
    RPUSH  = 0x00_u16
    RPOP   = 0x01_u16
    INCR   = 0x02_u16
    DECR   = 0x03_u16
    MOV    = 0x04_u16

    # Arithmetic
    ADD    = 0x05_u16
    SUB    = 0x06_u16
    MUL    = 0x07_u16
    DIV    = 0x08_u16
    REM    = 0x09_u16
    EXP    = 0x0A_u16

    # Comparisons
    CMP    = 0x0B_u16
    LT     = 0x0C_u16
    GT     = 0x0D_u16
    LTE    = 0x0E_u16
    GTE    = 0x0F_u16

    # Bitwise operati
    SHR    = 0x10_u16
    SHL    = 0x11_u16
    AND    = 0x12_u16
    XOR    = 0x13_u16
    NAND   = 0x14_u16
    OR     = 0x15_u16
    NOT    = 0x16_u16

    # Casting instruc
    TRUNC  = 0x17_u16
    SE     = 0x18_u16
    ZE     = 0x19_u16

    # Stack instructi
    LOAD   = 0x1A_u16
    LOADR  = 0x1B_u16
    LOADI  = 0x1C_u16
    STORE  = 0x1D_u16
    STORER = 0x1E_u16
    INC    = 0x1F_u16
    DEC    = 0x20_u16

    # Memory
    READ   = 0x21_u16
    READR  = 0x22_u16
    WRITE  = 0x23_u16
    WRITER = 0x24_u16
    COPY   = 0x25_u16
    COPYR  = 0x26_u16

    # Jumps
    JZ     = 0x27_u16
    JZR    = 0x28_u16
    JNZ    = 0x29_u16
    JNZR   = 0x2A_u16
    JMP    = 0x2B_u16
    JMPR   = 0x2C_u16
    CALL   = 0x2D_u16
    CALLR  = 0x2E_u16
    RET    = 0x2F_u16

    # Miscellaneous
    NOP    = 0x30_u16
    PUTS   = 0x31_u16
    HALT   = 0x32_u16

    # Bitmasks
    M_S    = 0b10000000_00000000_u16
    M_T    = 0b01000000_00000000_u16
    M_B    = 0b00100000_00000000_u16
    M_O    = 0b00011111_11111111_u16
  end

end
