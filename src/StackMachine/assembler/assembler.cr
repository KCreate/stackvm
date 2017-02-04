require "./syntax/ast.cr"
require "./syntax/parser.cr"
require "./semantic.cr"

module StackMachine::Assembler

  class Assembler

    def build(source : String)
      mod = Parser.parse source
      mod = Semantic.new(mod).analyse
      mod
    end

  end

end
