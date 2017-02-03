module StackMachine
  module Reg
    R0 = 0x00
    R1 = 0x01
    R2 = 0x02
    R3 = 0x03
    R4 = 0x04
    R5 = 0x05
    R6 = 0x06
    R7 = 0x07
    R8 = 0x08
    R9 = 0x09

    AX = 0x0A
    IP = 0x0B
    SP = 0x0C
    FP = 0x0D

    RUN = 0x0E
    EXT = 0x0F

    REGISTER_COUNT = 16 # amount of registers declared

    def self.valid(register : Int32)
      register >= 0 && register < REGISTER_COUNT
    end
  end
end
