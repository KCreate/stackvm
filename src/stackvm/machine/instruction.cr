require "../semantic/opcode.cr"

module StackVM::Machine
  include Semantic

  # Represents a single instruction
  struct Instruction
    property value : UInt16

    def initialize(@value)
    end

    # Returns the value of the S flag
    #
    # The S flag tells the machine wether the operation will be signed
    # or not
    def flag_s
      @value & OP::M_S == OP::M_S
    end

    # Returns the value of the T flag
    #
    # The T flag tells the machine wether the operation will be a integer
    # or floating-point operation
    #
    # For jump instructions, the T flag tells wether the jump is
    # to an absolute offset (default) or relative to the current
    # instruction pointer.
    def flag_t
      @value & OP::M_T == OP::M_T
    end

    # Returns the value of the B flag
    #
    # The B flag tells the machine wether the operation will perform in
    # 32-bit or 64-bit mode
    def flag_b
      @value & OP::M_B == OP::M_B
    end

    # Returns the opcode of this instruction
    def opcode
      @value & OP::M_O
    end
  end

end
