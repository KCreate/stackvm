module StackMachine
  module Reg
    # general purpose
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

    AX = 0x0A # return value
    IP = 0x0B # instruction pointer
    SP = 0x0C # stack pointer
    FP = 0x0D # frame pointer
    RO = 0x0E # read-only memory from the end to the start

    RUN = 0x0F # machine state
    EXT = 0x10 # exit code

    REGISTER_COUNT = 17 # amount of registers declared

    def self.valid(register : Int32)
      register >= 0 && register < REGISTER_COUNT
    end
  end
end
