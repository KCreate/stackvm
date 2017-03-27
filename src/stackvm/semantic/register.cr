module StackVM::Semantic

  # Registers of the machine
  module Reg

    # General purpose registers
    R0  = 0x00_u8
    R1  = 0x01_u8
    R2  = 0x02_u8
    R3  = 0x03_u8
    R4  = 0x04_u8
    R5  = 0x05_u8
    R6  = 0x06_u8
    R7  = 0x07_u8
    R8  = 0x08_u8
    R9  = 0x09_u8
    R10 = 0x0A_u8
    R11 = 0x0B_u8
    R12 = 0x0C_u8
    R13 = 0x0D_u8
    R14 = 0x0E_u8
    R15 = 0x0F_u8

    # Machine managed
    IP  = 0x10_u8 # Instruction pointer
    SP  = 0x11_u8 # Stack pointer
    FP  = 0x12_u8 # Frame pointer
    EXT = 0x13_u8 # Exit code

    # Bitmasks
    M_C = 0b10000000_u8 # Complete or sub-portion
    M_H = 0b01000000_u8 # Left or right half
    M_R = 0b00111111_u8 # Register code
  end

end
