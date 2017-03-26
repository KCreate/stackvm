module StackVM::Machine

  class Error < Exception
    property code : UInt8

    def self.new(code, message)
      super message
      @code = code.to_u8
    end
  end

end
