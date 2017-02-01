module StackMachine
  # Opcodes
  module OP
    ADD = 0 # integer addition
    SUB = 1 # integer subtraction
    MUL = 2 # multiplication
    DIV = 3 # division
    POW = 4 # exponentation
    REM = 5 # remainder

    SHR = 8 # shift right
    SHL = 9 # shift left
    NOT = 10 # bitwise NOT
    XOR = 11 # bitwise XOR
    OR = 12 # bitwise OR
    AND = 13 # bitwise AND

    INCR = 14 # increment value in register
    DECR = 15 # decrement value in register
    INC = 16 # increment top of stack
    DEC = 17 # decrement top of stack

    LOADR = 18 # loads given value into given register
    LOAD = 19 # loads value at fp + diff in the stack
    STORE = 20 # stores value at location fp + diff
    MOV = 21 # copies contents of src register into dst register

    PUSHR = 22 # pushes value in given register
    PUSH = 23 # push a given value
    POP = 24 # pops a value from the stack into given register

    CMP = 25 # pops top two values and pushes 0 if they are equal
    LT = 26 # pops top two values and pushes 0 if lower < upper
    GT = 27 # pops top two values and pushes 0 if lower > upper

    JZ = 28 # jumps to absolute address if top of the stack is 0
    RJZ = 29 # adds differential to ip if top of the stack is 0
    JNZ = 30 # jumps to absolute address if top of the stack is not 0
    RJNZ = 31 # adds differential to ip if top of the stack is not 0
    JMP = 32 # jumps to absolute address unconditionally
    RJMP = 33 # adds differential to ip unconditionally
    CALL = 34 # pushes current ip and unconditionally jumps to given address
    RET = 35 # put top of the stack into ax and jump to address at the (now) top of stack

    PREG = 36 # prints the contents of given register
    PTOP = 37 # prints top of stack (doesn't pop)

    HALT = 38 # sets ext to given code and halts the machine
    NOP = 39 # does nothing

    @[AlwaysInline]
    def self.valid(instruction : Int32)
      instruction >= 0 && instruction <= 39
    end
  end
end
