module StackVM::Machine

  class Error < Exception
    property code : UInt8

    def initialize(code, message)
      super message
      @code = code.to_u8
    end
  end

end
