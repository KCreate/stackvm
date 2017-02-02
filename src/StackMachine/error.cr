module StackMachine
  module Error
    STACK_OVERFLOW = 0 # stack overflow
    STACK_UNDERFLOW = 1 # stack underflow
    UNKNOWN_INSTRUCTION = 2 # unknown instruction being processed
    MISSING_ARGUMENTS = 3 # missing arguments to an instruction
    UNKNOWN_REGISTER = 4 # unknown register id
    ILLEGAL_MEMORY_ACCESS = 5 # illegal memory read or write
  end
end
