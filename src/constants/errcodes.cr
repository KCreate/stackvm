module Constants
  class Error < Exception
    property code : ErrorCode

    def initialize(@code, message)
      super(message)
    end
  end

  enum ErrorCode : UInt8
    REGULAR_EXIT          = 0x0
    ILLEGAL_MEMORY_ACCESS = 0x1
    INVALID_INSTRUCTION   = 0x2
    INVALID_REGISTER      = 0x3
    INVALID_SYSCALL       = 0x4
    EXECUTABLE_TOO_BIG    = 0x5
    INVALID_EXECUTABLE    = 0x6
    ALLOCATION_FAILURE    = 0x7
    INTERNAL_FAILURE      = 0x8
  end
end
