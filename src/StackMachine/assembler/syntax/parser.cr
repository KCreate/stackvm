require "./ast.cr"

module StackMachine::Assembler

  class SyntaxError < Exception
  end

  class Parser

    def self.parse(source : String)
      mod = Module.new
      current_block : Block? = nil

      index = 0
      source.each_line do |line|

        # skip empty lines
        next if line.size == 0

        # strip comments and divide into tokens
        parts = line.split(";").first.split
        next if parts.size == 0

        # create a node from the line
        node = parse_parts parts, line, index

        # append to the current block
        case node
        when .is_a? Instruction
          if current_block.is_a? Nil
            raise SyntaxError.new "Unexpected instruction on line #{index}: #{line}"
          end

          current_block.instructions << node
        when .is_a? Label
          current_block = Block.new node.name
          mod.blocks << current_block
        else
          raise SyntaxError.new "Unexpected token on line #{index}: #{line}"
        end

        index += 1
      end

      mod
    end

    private def self.parse_parts(parts : Array(String), line : String, index : Int32)
      case parts.size
      when 1
        token = parts[0]

        # labels
        if token[-1] == ':'
          return Label.new token[0..-2]
        end

        return Instruction.new token
      when 2
        argument = parse_argument parts[1], line, index
        return Instruction.new parts[0], [argument]
      when 3
        argument1 = parse_argument parts[1], line, index
        argument2 = parse_argument parts[2], line, index
        return Instruction.new parts[0], [argument1, argument2]
      else
        raise SyntaxError.new "Too many tokens on line #{index}: \"#{line}\""
      end
    end

    def self.parse_argument(source : String, line : String, index : Int32)
      case source[0]
      when '@'
        return Label.new source[1..-1]
      when '%'
        return Register.new source[1..-1]
      when '0'
        if source.size < 3
          if source.size == 1
            return Number.new source.to_i32(10)
          end

          raise SyntaxError.new "Unclosed numeric literal on line #{index}: #{line}"
        end

        literal = source.to_i32?(underscore: true, prefix: true)

        if literal.is_a? Int32
          return Number.new literal
        end

        raise SyntaxError.new "Unexpected token on line #{index}: #{line}"
      else
        literal = source.to_i32?(10, underscore: true)

        if literal.is_a? Int32
          return Number.new literal
        end

        raise SyntaxError.new "Unexpected token on line #{index}: #{line}"
      end
    end
  end

end
