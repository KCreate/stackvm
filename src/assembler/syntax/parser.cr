require "./ast.cr"
require "./token.cr"

module Assembler

  class Parser
    getter tokens : Array(Token)
    getter current : Token

    def self.parse(tokens : Array(Token))
      parser = Parser.new tokens
      parser.parse
    end

    def initialize(tokens)
      @tokens = tokens.select { |token|
        token.type != :whitespace && token.type != :comment
      }

      @current = Token.new :eof, ""
    end

    def parse
      if @tokens.size > 0
        read
        return parse_mod
      end

      Module.new
    end

    private def parse_mod
      mod = Module.new

      until @current.type == :eof
        mod.statements << parse_statement
      end

      mod
    end

    private def parse_statement
      while @current.type == :newline; read; end

      case @current.type
      when :dot
        expect :ident
        return parse_directive
      when :ident
        return parse_instruction
      else
        unexpected_token @current, "Expected a '.' or a label"
      end
    end

    private def parse_directive
      case @current.value
      when "label"
        case (token = read).type
        when :ident
          expect :newline
          advance
          label = Label.new token.value
          return LabelDefinition.new label
        when :atsign
          token = expect :string
          expect :newline
          advance
          label = Label.new token.value
          return LabelDefinition.new label
        else
          unexpected_token token, "Expected label or '@'"
        end
      when "def"
        token = expect :ident
        label = Label.new token.value
        advance
        atomic = parse_atomic
        skip :newline
        return Definition.new label, atomic
      when "org"
        case (token = read).type
        when :ident
          expect :newline
          advance
          return Organize.new Label.new token.value
        else
          atomic = parse_atomic
          skip :newline
          return Organize.new atomic
        end
      when "db"
        token = expect :ident
        advance
        label = Label.new token.value
        size = parse_atomic
        value = parse_atomic
        skip :newline
        return Constant.new label, size, value
      when "include"
        token = expect :string
        string = StringLiteral.new token.value
        expect :newline
        advance
        return Include.new string
      else
        raise "Unknown assembler directive at #{@current.location}"
      end
    end

    private def parse_instruction
      label = Label.new @current.value
      instr = Instruction.new label

      advance

      until @current.type == :newline
        instr.arguments << parse_atomic

        case @current.type
        when :comma
          advance
        when :newline
          # nothing to do
        else
          unexpected_token @current, "Expected a comma or newline"
        end
      end

      advance
      instr
    end

    private def parse_atomic
      case @current.type
      when :numeric_int
        int = IntegerLiteral.new parse_int @current.value
        advance
        return int
      when :numeric_float
        float = FloatLiteral.new @current.value.to_f64
        advance
        return float
      when :string
        string = StringLiteral.new @current.value
        advance
        return string
      when :ident
        label = Label.new @current.value
        advance
        return label
      when :atsign
        token = expect :string
        label = Label.new token.value
        advance
        return label
      when :leftbracket
        advance

        array = ArrayLiteral.new

        until @current.type == :rightbracket

          # Consume all newlines since we don't care about them here
          while @current.type == :newline; read; end
          array.items << parse_atomic

          # We also don't care about newlines here
          while @current.type == :newline; read; end

          case @current.type
          when :comma
            advance
          end
        end

        advance

        return array
      else
        unexpected_token @current, "Expected an atomic value"
      end
    end

    private def parse_int(string)
      return 0_i64 if string == "0"
      return string.to_i64(underscore: true, prefix: true)
    end

    private def advance
      read
    end

    private def read
      @current = @tokens.shift? || Token.new :eof, ""
    end

    private def skip(type)
      unless @current.type == type
        unexpected_token @current, "Expected #{type}"
      end

      read
    end

    private def read_ignore_newline
      while read.type == :newline
      end

      @current
    end

    private def expect(type)
      token = read
      unless token.type == type
        unexpected_token token, "Expected #{type}"
      end
      token
    end

    private def unexpected_token(token, message)
      raise <<-ERR
      Unexpected token: #{token.type}
      at: #{token.location}

      #{message}
      ERR
    end

  end

end
