require "./reader.cr"
require "./token.cr"

module Assembler
  class Lexer < Reader
    property token : Token
    property tokens : Array(Token)
    property filename : String

    def self.analyse(filename, io)
      lexer = Lexer.new filename, io
      lexer.analyse
    end

    def initialize(@filename, io)
      super(io)
      @token = Token.new :undefined, ""
      @tokens = [] of Token
    end

    def analyse
      until (token = read_token).type == :eof
        @tokens << token
      end

      @tokens
    end

    def read_token
      reset_token

      case current_char
      when '\0'
        @token.type = :eof
      when ' ', '\t'
        consume_whitespace
      when '\n'
        read :newline
      when '@'
        read :atsign
      when '.'
        read :dot
      when ','
        read :comma
      when ';'
        consume_comment
      when '+'
        read :plus
      when '-'
        read :minus
      when '*'
        read :mul
      when '/'
        case read
        when '/'
          consume_comment
        when '*'
          read
          consume_multiline_comment
        else
          @token.type = :div
        end
      when '('
        read :leftparen
      when ')'
        read :rightparen
      when '0'..'9'
        consume_numeric
      when '"'
        consume_string
      when '\r'
        if read == '\n'
          read :newline
        else
          unexpected_char
        end
      else
        if ident_start current_char
          consume_ident
        else
          unexpected_char
        end
      end

      @token.dup
    end

    private def read(type)
      @token.type = type
      super()
    end

    private def reset_token
      @token.type = :undefined
      @token.value = ""
      @token.location = Location.new @row, @column, @filename

      @frame.clear
      @frame << current_char
    end

    # Consumes a numeric value
    private def consume_numeric
      passed_dot = false

      loop do
        char = read

        unless ('0'..'9') === char || ('a'..'f') === char || char == 'x' || char == 'b' ||
               char == '.' || char == '_'
          break
        end

        if char == '.'
          passed_dot = true
        end
      end

      value = @frame.to_s[0..-2]

      # Validate the number
      if passed_dot
        num = value.to_f64?
        unless num
          raise "Could not parse #{value} as a floating-point number at #{@token.location}"
        end

        @token.type = :numeric_float
      else
        unless value == "0"
          num = value.to_i64?(underscore: true, prefix: true)
          unless num
            raise "Could not parse #{value} as a integer number at #{@token.location}"
          end
        end

        @token.type = :numeric_int
      end

      @token.value = value
    end

    # Consumes a string literal
    private def consume_string
      io = IO::Memory.new

      loop do
        char = read

        case char
        when '"'
          break
        when '\\'
          case read
          when 'b'
            io << "\u{8}"
          when 'n'
            io << "\n"
          when 'r'
            io << "\r"
          when 't'
            io << "\t"
          when 'v'
            io << "\v"
          when 'e'
            io << "\e"
          when '\n'
            io << "\n"
          when '"'
            io << "\""
          when '\\'
            io << "\\"
          when '\0'
            raise "Unclosed string at #{@token.location}"
          end
        when '\0'
          raise "Unclosed string at #{@token.location}"
        else
          io << char
        end
      end

      @token.type = :string
      @token.value = io.to_s
      io.clear
      read
    end

    # Consumes whitespace
    private def consume_whitespace
      loop do
        char = read

        unless char == ' ' || char == '\t'
          break
        end
      end

      @token.type = :whitespace
      @token.value = @frame.to_s[0..-2]
    end

    # Consumes a comment
    private def consume_comment
      loop do
        char = read

        case char
        when '\n', '\r'
          break
        else
          # nothing to do
        end
      end

      @token.type = :comment
      @token.value = @frame.to_s[0..-3]
    end

    # Consumes a multiline comment
    private def consume_multiline_comment
      loop do
        case current_char
        when '*'
          case read
          when '/'
            read
            break
          end
        else
          read
        end
      end

      @token.type = :comment
      @token.value = @frame.to_s[2..-4]
    end

    # Consumes an identifier
    private def consume_ident
      while ident_part read
      end

      @token.type = :ident
      @token.value = @frame.to_s[0..-2]
    end

    # Checks if *char* can be the starting character of an identifier
    private def ident_start(char)
      char.letter? || char == '_' || char == '$' || char == '%'
    end

    private def ident_part(char)
      ident_start(char) || char.number?
    end

    private def unexpected_char
      raise "Unexpected char \"#{current_char}\" at #{@token.location}"
    end
  end
end
