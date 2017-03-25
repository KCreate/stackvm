module StackVM::Semantic

  # Each size value denotes a specific amount of bytes
  enum Size : UInt64
    BYTE  = 1
    WORD  = 2
    DWORD = 4
    QWORD = 8
    LWORD = 16
  end

end
