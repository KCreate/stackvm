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
      mod = Module.new.at @current.location

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
      location_start = @current.location

      case @current.value
      when "label"
        case (token = read).type
        when :ident
          expect :newline
          advance
          label = Label.new(token.value).at(token.location)
          return LabelDefinition.new(label).at(location_start, label.location_end)
        when :atsign
          token = expect :string
          expect :newline
          advance
          label = Label.new(token.value).at(token.location)
          return LabelDefinition.new(label).at location_start, token.location
        else
          unexpected_token token, "Expected label or '@'"
        end
      when "def"
        token = expect :ident
        label = Label.new(token.value).at(token.location)
        advance
        atomic = parse_atomic
        skip :newline
        return Definition.new(label, atomic).at(location_start, atomic.location_end)
      when "org"
        case (token = read).type
        when :ident
          expect :newline
          advance
          label = Label.new(token.value).at(token.location)
          return Organize.new(label).at(location_start, token.location)
        else
          atomic = parse_atomic
          skip :newline
          return Organize.new(atomic).at(location_start, atomic.location_end)
        end
      when "db"
        token = expect :ident
        advance
        label = Label.new(token.value).at(token.location)
        size = parse_atomic
        value = parse_atomic
        skip :newline
        return Constant.new(label, size, value).at(location_start, value.location_end)
      when "include"
        token = expect :string
        string = StringLiteral.new(token.value).at(token.location)
        expect :newline
        advance
        return Include.new(string).at(location_start, token.location)
      else
        raise "Unknown assembler directive at #{@current.location}"
      end
    end

    private def parse_instruction
      location_start = @current.location

      label = Label.new(@current.value).at(location_start)
      instr = Instruction.new(label)

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

      instr.at(location_start, @current.location)

      advance
      instr
    end

    private def parse_atomic
      location_start = @current.location

      case @current.type
      when :numeric_int
        int = IntegerLiteral.new(parse_int @current.value).at(location_start)
        advance
        return int
      when :numeric_float
        float = FloatLiteral.new(@current.value.to_f64).at(location_start)
        advance
        return float
      when :string
        string = StringLiteral.new(@current.value).at(location_start)
        advance
        return string
      when :ident
        label = Label.new(@current.value).at(location_start)
        advance
        return label
      when :atsign
        token = expect :string
        label = Label.new(token.value).at(location_start, @current.location)
        advance
        return label
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
