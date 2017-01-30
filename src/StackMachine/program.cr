require "./instruction.cr"

module StackMachine

  class Program
    include Indexable(Instruction)

    property instructions : Array(Instruction)

    def initialize(@instructions)
    end

    delegate :unsafe_at, to: @instructions
    delegate :size, to: @instructions
  end

end
