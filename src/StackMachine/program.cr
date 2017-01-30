require "./instruction.cr"

module StackMachine

  class Program
    include Indexable(Instruction)

    property instructions : Array(Instruction)

    def initialize(@instructions)
    end

    def self.new(instructions : Array(UInt64))
      set = [] of Instruction
      instructions.each do |inst|
        set << Instruction.new inst
      end
      new set
    end

    delegate :unsafe_at, to: @instructions
    delegate :size, to: @instructions
  end

end
