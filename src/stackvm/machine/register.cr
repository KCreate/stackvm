require "../semantic/register.cr"

module StackVM::Machine
  include Semantic

  # Represents a single register
  struct Register
    property value : UInt8

    def initialize(@value)
    end

    # Wether the complete register is meant or a sub-portion
    def subportion
      @value & Reg::M_C == Reg::M_C
    end

    # Wether the first register is meant (only in subportion mode)
    def higher
      @value & Reg::M_H == Reg::M_H
    end

    # Returns the code of this register
    def regcode
      @value & Reg::M_R
    end
  end

end
