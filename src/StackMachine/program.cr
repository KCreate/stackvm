module StackMachine
  class Program
    property data : Array(Int32)

    def initialize(@data = [] of Int32)
    end

    def <<(value : Int32)
      @data << value
    end
  end
end
