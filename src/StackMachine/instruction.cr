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
    DATA_FIELDS = 0x3FFFFFFFFFFFFFFF

    property content : UInt64

    def initialize(@content)
    end

    def self.new(header : UInt64, data : UInt64)
      new (header << 62) | (data & DATA_FIELDS)
    end

    def self.new(header, data)
      new header.to_u64, data.to_u64
    end

    def header
      @content >> 62
    end

    def data
      @content & DATA_FIELDS
    end
  end

end
