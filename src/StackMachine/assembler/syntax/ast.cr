module StackMachine::Assembler

  class ASTNode
  end

  class Module < ASTNode
    property blocks : Array(Block)

    def initialize(@blocks = [] of Block)
    end
  end

  class Block < ASTNode
    property name : String
    property instructions : Array(Instruction)

    def initialize(@name, @instructions = [] of Instruction)
    end
  end

  class Instruction < ASTNode
    property name : String
    property arguments : Array(Atomic)

    def initialize(@name, @arguments = [] of Atomic)
    end
  end

  class Atomic < ASTNode
  end

  class Label < Atomic
    property name : String

    def initialize(@name)
    end
  end

  class Register < Atomic
    property name : String

    def initialize(@name)
    end
  end

  class Number < Atomic
    property value : Int32

    def initialize(@value)
    end
  end

end
