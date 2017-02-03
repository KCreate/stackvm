module StackMachine
  # Opcodes
  module OP
    ADD = 0x00 # integer addition
    SUB = 0x01 # integer subtraction
    MUL = 0x02 # multiplication
    DIV = 0x03 # division
    POW = 0x04 # exponentation
    REM = 0x05 # remainder

    SHR = 0x08 # shift right
    SHL = 0x09 # shift left
    NOT = 0x0A # bitwise NOT
    XOR = 0x0B # bitwise XOR
    OR = 0x0C # bitwise OR
    AND = 0x0D # bitwise AND

    INCR = 0x0E # increment value in register
    DECR = 0x0F # decrement value in register
    INC = 0x10 # increment top of stack
    DEC = 0x11 # decrement top of stack

    LOADR = 0x12 # loads given value into given register
    LOAD = 0x13 # loads value at fp + diff in the stack
    STORE = 0x14 # stores value at location fp + diff
    STORER = 0x15 # stores value in register at location fp + diff
    MOV = 0x16 # copies contents of src register into dst register

    PUSHR = 0x17 # pushes value in given register
    PUSH = 0x18 # push a given value
    POP = 0x19 # pops a value from the stack into given register

    CMP = 0x1A # pops top two values and pushes 0 if they are equal
    LT = 0x1B # pops top two values and pushes 0 if lower < upper
    GT = 0x1C # pops top two values and pushes 0 if lower > upper

    JZ = 0x1D # jumps to absolute address if top of the stack is 0
    JNZ = 0x1F # jumps to absolute address if top of the stack is not 0
    JMP = 0x21 # jumps to absolute address unconditionally
    CALL = 0x23 # creates a new stack frame and jumps
    RET = 0x24 # put top of the stack into ax and jumps to return address

    PREG = 0x25 # prints the contents of given register
    PTOP = 0x26 # prints top of stack (doesn't pop)

    HALT = 0x27 # sets ext to given code and halts the machine
    NOP = 0x28 # does nothing

    @[AlwaysInline]
    def self.valid(instruction : Int32)
      instruction >= 0 && instruction <= 0x28
    end
  end
end
