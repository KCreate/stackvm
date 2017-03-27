require "./stackvm/**"

module StackVM
  include Semantic
  include Machine

  DEBUG_PROGRAM = Slice[

    # LOADI BYTE "hello world"
    0b00011100_u8, 0b00000000_u8,
    0b00001011_u8, 0b00000000_u8, 0b00000000_u8, 0b00000000_u8,
    0b01101000_u8, 0b01100101_u8, 0b01101100_u8, 0b01101100_u8,
    0b01101111_u8, 0b00100000_u8, 0b01110111_u8, 0b01101111_u8,
    0b01110010_u8, 0b01101100_u8, 0b01100100_u8,

    # HALT
    0b00110010_u8, 0b00000000_u8
  ]

  machine = Machine::Machine.new
  machine.flash DEBUG_PROGRAM

  machine.start

  machine.status STDOUT
end
