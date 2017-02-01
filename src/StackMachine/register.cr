module StackMachine
  module Reg
    # general purpose
    R0 = 0
    R1 = 1
    R2 = 2
    R3 = 3
    R4 = 4
    R5 = 5
    R6 = 6
    R7 = 7
    R8 = 8
    R9 = 9

    AX = 10 # return value
    IP = 11 # instruction pointer
    SP = 12 # stack pointer
    FP = 13 # frame pointer
    RO = 14 # read-only memory from the end to the start

    RUN = 15 # machine state
    EXT = 16 # exit code

    REGISTER_COUNT = 17 # amount of registers declared

    def self.valid(register : Int32)
      register >= 0 && register < REGISTER_COUNT
    end
  end
end
