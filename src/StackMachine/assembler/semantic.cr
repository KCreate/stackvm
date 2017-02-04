require "./syntax/ast.cr"

module StackMachine::Assembler
  INSTRUCTION_SIGNATURES = {
    "add" => [] of ASTNode.class,
    "sub" => [] of ASTNode.class,
    "mul" => [] of ASTNode.class,
    "div" => [] of ASTNode.class,
    "pow" => [] of ASTNode.class,
    "rem" => [] of ASTNode.class,
    "shr" => [] of ASTNode.class,
    "shl" => [] of ASTNode.class,
    "not" => [] of ASTNode.class,
    "xor" => [] of ASTNode.class,
    "or" => [] of ASTNode.class,
    "and" => [] of ASTNode.class,
    "incr" => [Register],
    "decr" => [Register],
    "inc" => [] of ASTNode.class,
    "dec" => [] of ASTNode.class,
    "loadr" => [Register, Number],
    "load" => [Number],
    "store" => [Number, Number],
    "storer" => [Register, Number],
    "mov" => [Register, Register],
    "pushr" => [Register],
    "push" => [Number],
    "pop" => [Register],
    "cmp" => [] of ASTNode.class,
    "lt" => [] of ASTNode.class,
    "gt" => [] of ASTNode.class,
    "jz" => [Label],
    "jnz" => [Label],
    "jmp" => [Label],
    "call" => [Label],
    "ret" => [] of ASTNode.class,
    "preg" => [Register],
    "ptop" => [] of ASTNode.class,
    "halt" => [] of ASTNode.class,
    "nop" => [] of ASTNode.class
  }

  REGISTER_NAMES = [
    "r0",
    "r1",
    "r2",
    "r3",
    "r4",
    "r5",
    "r6",
    "r7",
    "r8",
    "r9",
    "ip",
    "sp",
    "fp",
    "ax",
    "ext",
    "run"
  ]

  class SemanticError < Exception
  end

  class Semantic
    property block_names : Array(String)
    property mod : Module

    def initialize(@mod)
      @block_names = mod.blocks.map &.name
    end

    def analyse
      valid?
      @mod
    end

    def valid?
      @mod.blocks.each do |block|
        block.instructions.each do |instruction|
          unless INSTRUCTION_SIGNATURES.keys.includes? instruction.name
            raise SemanticError.new "#{instruction.name} is not a valid instruction name"
          end

          expected_count = INSTRUCTION_SIGNATURES[instruction.name.downcase].size
          unless INSTRUCTION_SIGNATURES[instruction.name.downcase].size == instruction.arguments.size
            raise SemanticError.new "Wrong amount of arguments for #{instruction.name}, \
            expected #{expected_count}, got #{instruction.arguments.size}"
          end

          instruction.arguments.each_with_index do |argument, index|
            types = INSTRUCTION_SIGNATURES[instruction.name.downcase]
            type = types[index]

            unless type == argument.class
              raise SemanticError.new "Wrong argument types for #{instruction.name}, \
              expected #{type}, got #{argument.class}"
            end

            case argument
            when .is_a? Register
              unless REGISTER_NAMES.includes? argument.name.downcase
                raise SemanticError.new "Unknown register name #{argument.name}"
              end
            when .is_a? Label
              unless @block_names.includes? argument.name
                raise SemanticError.new "Unknown block label #{argument.name}"
              end
            end
          end

        end
      end
    end
  end

end
