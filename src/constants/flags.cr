module Constants
  enum Flag : UInt8
    ZERO = 0b00000001

    REGCODE = 0b00111111
    REGMODE = 0b11000000
    QWORD   = 0b00000000
    DWORD   = 0b01000000
    WORD    = 0b10000000
    BYTE    = 0b11000000
  end
end
