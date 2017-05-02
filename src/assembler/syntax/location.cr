module Assembler
  class Location
    getter row : Int32
    getter column : Int32
    getter filename : String

    def initialize(@row, @column, @filename)
    end

    def to_s(io)
      io << filename << ":" << row << ":" << column
    end
  end
end
