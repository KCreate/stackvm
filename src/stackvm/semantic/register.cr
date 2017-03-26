module StackVM::Semantic

  # Registers of the machine
  enum Reg : UInt8

    # General purpose registers
    R0  = 0x00
    R1  = 0x01
    R2  = 0x02
    R3  = 0x03
    R4  = 0x04
    R5  = 0x05
    R6  = 0x06
    R7  = 0x07
    R8  = 0x08
    R9  = 0x09
    R10 = 0x0A
    R11 = 0x0B
    R12 = 0x0C
    R13 = 0x0D
    R14 = 0x0E
    R15 = 0x0F

    # Machine managed
    IP  = 0x10 # Instruction pointer
    SP  = 0x11 # Stack pointer
    FP  = 0x12 # Frame pointer

    # Bitmasks
    M_C = 0b10000000 # Complete or sub-portion
    M_H = 0b01000000 # Left or right half
    M_R = 0b00111111 # Register code
  end

end
