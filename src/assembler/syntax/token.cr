require "./location.cr"

module Assembler
  class Token
    property type : Symbol
    property value : String
    property location : Location?

    def initialize(@type, @value)
      @location = nil
    end

    def to_s(io)
      io << "["
      io << type.to_s.ljust(20, ' ') << " "
      io << value.to_s.ljust(20, ' ') << " " << location
      io << "]"
    end
  end
end
