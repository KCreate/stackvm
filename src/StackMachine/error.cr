module StackMachine
  module Error
    PROGRAM_WONT_FIT = 0 # the program won't fit into memory
    STACK_OVERFLOW = 1 # stack overflow
    STACK_UNDERFLOW = 2 # stack underflow
    UNKNOWN_INSTRUCTION = 3 # unknown instruction being processed
    MISSING_ARGUMENTS = 4 # missing arguments to an instruction
    UNKNOWN_REGISTER = 5 # unknown register id
    ILLEGAL_MEMORY_ACCESS = 6 # illegal memory read or write
  end
end
