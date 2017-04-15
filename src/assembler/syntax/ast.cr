require "../../constants/constants.cr"

module Assembler

  # Base class of all ast nodes
  class ASTNode
    property location_start : Location? = nil
    property location_end : Location? = nil

    def at(location)
      @location_start = location
      @location_end = location
    end

    def at(start, loc_end)
      @location_start = start
      @location_end = loc_end
    end

    def at(node : ASTNode)
      @location_start = node.location_start
      @location_end = node.location_end
    end
  end

  # A module is the container for everyting that's inside
  # an assembly file
  class Module < ASTNode
    getter statements : Array(Statement)

    def initialize
      @statements = [] of Statement
    end

    def to_s(io)
      super
      @statements.each do |stat|
        io << "\n" << stat
      end
    end
  end

  # Base class for all statements
  abstract class Statement < ASTNode
  end

  # An instruction has a name and arguments which
  # are associated with it
  class Instruction < Statement
    getter name : Label
    getter arguments : Array(Atomic)

    def initialize(@name)
      @arguments = [] of Atomic
    end

    def to_s(io)
      io << @name << " "
      io << @arguments.join ", "
    end
  end

  # A definition declares a new alias for another ASTNode
  class Definition < Statement
    getter name : Label
    getter node : ASTNode

    def initialize(@name, @node)
    end

    def to_s(io)
      io << ".def " << @name << " " << @node
    end
  end

  # A constant declaration
  class Constant < Statement
    getter name : Label
    getter size : Atomic
    getter value : Atomic

    def initialize(@name, @size, @value)
    end

    def to_s(io)
      io << ".db " << @name << " " << @size << " " << @value
    end
  end

  # A organize directive
  class Organize < Statement
    getter address : Atomic

    def initialize(@address)
    end

    def to_s(io)
      io << ".org " << address
    end
  end

  # An include directive
  class Include < Statement
    getter path : StringLiteral

    def initialize(@path)
    end

    def to_s(io)
      io << ".include " << @path
    end
  end

  # A label definition
  class LabelDefinition < Statement
    getter label : Label

    def initialize(@label)
    end

    def to_s(io)
      io << ".label #{@label}"
    end
  end

  # Base class for all atomic values
  abstract class Atomic < ASTNode
  end

  class Label < Atomic
    getter value : String

    def initialize(@value)
    end

    def to_s(io)
      io << @value
    end
  end

  class StringLiteral < Atomic
    getter value : String

    def initialize(@value)
    end

    def to_s(io)
      io << "\"#{@value}\""
    end
  end

  class IntegerLiteral < Atomic
    getter value : Int64

    def initialize(@value)
    end

    def to_s(io)
      io << @value
    end
  end

  class FloatLiteral < Atomic
    getter value : Float64

    def initialize(@value)
    end

    def to_s(io)
      io << @value
    end
  end

  class ArrayLiteral < Atomic
    getter items : Array(Atomic)

    def initialize
      @items = [] of Atomic
    end

    def to_s(io)
      io << "["
      io << @items.join ", "
      io << "]"
    end
  end

end
