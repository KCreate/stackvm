module StackMachine

  # Instruction Types
  enum InstructionType : UInt16
    Add
    Sub
    Mul
    Div
    Load
    Write
    Print

    def self.new(num : Int32)
      new num.to_u16
    end
  end

  # Instruction
  #
  # Contains two methods #header and #data
  #
  # The header identifies the content of the data part
  # - header
  #   0 - Signed 62-bit number
  #   1 - Instruction
  #   2 - Unsigned 62-bit number
  #   3 - Undefined
  struct Instruction
    @header : Tuple(Bool, Bool, Int64)

    def initialize(instruction, signed, data : Int64)
      @header = {instruction, signed, data}
    end

    def self.new(instruction, signed, data)
      new instruction, signed, data.to_i64
    end

    def instruction?
      @header[0]
    end

    def signed?
      @header[1]
    end

    def data
      @header[2]
    end
  end

end
