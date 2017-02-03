module StackMachine
  # Opcodes
  module OP
    ADD = 0x00
    SUB = 0x01
    MUL = 0x02
    DIV = 0x03
    POW = 0x04
    REM = 0x05

    SHR = 0x08
    SHL = 0x09
    NOT = 0x0A
    XOR = 0x0B
    OR = 0x0C
    AND = 0x0D

    INCR = 0x0E
    DECR = 0x0F
    INC = 0x10
    DEC = 0x11

    LOADR = 0x12
    LOAD = 0x13
    STORE = 0x14
    STORER = 0x15
    MOV = 0x16

    PUSHR = 0x17
    PUSH = 0x18
    POP = 0x19

    CMP = 0x1A
    LT = 0x1B
    GT = 0x1C

    JZ = 0x1D
    JNZ = 0x1F
    JMP = 0x21
    CALL = 0x23
    RET = 0x24

    PREG = 0x25
    PTOP = 0x26

    HALT = 0x27
    NOP = 0x28

    @[AlwaysInline]
    def self.valid(instruction : Int32)
      instruction >= 0 && instruction <= 0x28
    end
  end
end
