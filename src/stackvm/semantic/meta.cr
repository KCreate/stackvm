require "./opcode.cr"

module StackVM::Semantic::Meta

  # Hash of descriptions for all opcodes
  Descriptions = {

    # Registers
    RPUSH => "Pushes the value of a register onto the stack",
    RPOP => "Pops the top of the stack into a register",
    INCR => "Increments the value inside a register by 1",
    DECR => "Decrements the value inside a register by 1",
    MOV => "Copies the contents of the source register into the target register",

    # Arithmetic
    ADD => "Pushes the sum of the top two values",
    SUB => "Pushes the difference of the top two values (lower - upper)",
    MUL => "Pushes the product of the top two values",
    DIV => "Pushes the quotient of the top two values (lower / upper)",
    REM => "Pushes the remainder of the top two values (lower % upper)",
    EXP => "Pushes the power of the top two values (lower ** upper)",

    # Comparisons
    CMP => "Pushes 0 if the top two values are equal",
    LT => "Pushes 0 if the second-highest value is less than the top",
    GT => "Pushes 0 if the second-highest value is greater than the top",
    LTE => "Pushes 0 if the second-highest value is less or equal than the top",
    GTE => "Pushes 0 if the second-highest value is greater or equal than the top",

    # Bitwise operations
    SHR => "Shifts the bits of the top value to the right n times (lower >> upper)",
    SHL => "Shifts the bits of the top value to the left n times (lower << upper)",
    AND => "Pushes bitwise AND of the top two values",
    XOR => "Pushes bitwise XOR of the top two values",
    NAND => "Pushes bitwise NAND of the top two values",
    OR => "Pushes bitwise OR of the top two values",
    NOT => "Pushes bitwise NOT of the top two values",

    # Casting instructions
    TRUNC => "Truncates a value from type1 to type2",
    SE => "Sign-extends a value from type1 to type2",
    ZE => "Zero-extends a value from type1 to type2",

    # Stack instructions
    LOAD => "Loads a type value located at (fp + offset)",
    LOADR => "Loads a type value located at (fp + [reg])",
    LOADI => "Loads an immediate type value",
    STORE => "Pop a type value and save at (fp + offset)",
    STORER=> "Pop a type value and save at (fp + [reg])",
    INC => "Increment a type value at (fp + offset)",
    DEC => "Decrement a type value at (fp + offset)",

    # Memory
    READ => "Reads a type value from address and pushes it onto the stack",
    READR => "Reads a type value from [reg] and pushes it onto the stack",
    WRITE => "Read a type value from the stack and write it to address",
    WRITER => "Read a type value from the stack and write it to [reg]",
    COPY => "Read a type value from source and write it to address",
    COPYR => "Read a type value from [reg1] and write it to [reg2]",

    # Jumps
    JZ => "Relative or absolute jump to the given offset if top of the stack is 0",
    JZR => "Relative or absolute jump to [reg] if top of the stack is 0",
    JNZ => "Relative or absolute jump to given offset if top of the stack is not 0",
    JNZR => "Relative or absolute jump to [reg] if top of the stack is not 0",
    JMP => "Unconditional relative or absolute jump to given offset",
    JMPR => "Unconditional relative or absolute jump to [reg]",
    CALL => "Relative or absolute jump to given offset, pushing a stack frame",
    CALLR => "Relative or absolute jump to [reg], pushing a stack frame",
    RET => "Returns from the current stack frame",

    # Miscellaneous
    NOP => "Does nothing",
    PUTS => "Copies a type value from the stack into stdout",
    HALT => "Halts the machine",
  } of UInt16 => String

  # Hash of string opcodes
  Opcodes = {} of UInt16 => String
  {% for name in OP.constants %}
    Opcodes[OP::{{name}}] = "{{name}}"
  {% end %}
end
