require "./types.cr"

module StackMachine

  # Instruction Types
  enum InstructionType : UInt16
    Halt
    Equal
    Jump
    Ret
    Write
    Read
    Print

    def self.new(num)
      new num.to_u16
    end
  end

  # Instruction
  struct Instruction
    property instruction : Bool
    property data : BaseType | InstructionType

    def initialize(@instruction, @data)
    end

    def self.new(type : InstructionType)
      new true, type
    end

    def self.new(value)
      new false, value
    end

    def self.new(value : Int32)
      new false, value.to_f64
    end

    def instruction?
      @instruction
    end
  end

end
