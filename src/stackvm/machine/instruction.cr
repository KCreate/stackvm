require "../semantic/opcode.cr"

module StackVM::Machine
  include Semantic

  # Represents a single instruction
  struct Instruction
    property value : UInt16

    def initialize(@value)
    end

    # Returns the value of the S flag
    def flag_s
      @value & OP::M_S == OP::M_S
    end

    # Returns the value of the T flag
    def flag_t
      @value & OP::M_T == OP::M_T
    end

    # Returns the value of the B flag
    def flag_b
      @value & OP::M_B == OP::M_B
    end

    # Returns the opcode of this instruction
    def opcode
      @value & OP::M_O
    end
  end

end
