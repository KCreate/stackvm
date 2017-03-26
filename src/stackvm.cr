require "./stackvm/**"

module StackVM
  include Semantic
  include Machine

  DEBUG_PROGRAM = Slice[

    # LOADI WORD 25
    0b00011100_u8, 0b00000000_u8,
    0b00000010_u8, 0b00000000_u8, 0b00000000_u8, 0b00000000_u8,
    0b00011001_u8, 0b00000000_u8,

    # LOADI WORD 25
    0b00011100_u8, 0b00000000_u8,
    0b00000010_u8, 0b00000000_u8, 0b00000000_u8, 0b00000000_u8,
    0b00011001_u8, 0b00000000_u8,

    # LOADI WORD 25
    0b00011100_u8, 0b00000000_u8,
    0b00000010_u8, 0b00000000_u8, 0b00000000_u8, 0b00000000_u8,
    0b00011001_u8, 0b00000000_u8,

    # LOADI WORD 25
    0b00011100_u8, 0b00000000_u8,
    0b00000010_u8, 0b00000000_u8, 0b00000000_u8, 0b00000000_u8,
    0b00011001_u8, 0b00000000_u8,

    # HALT
    0b00110010_u8, 0b00000000_u8
  ]

  machine = Machine::Machine.new
  machine.flash DEBUG_PROGRAM

  machine.start

  machine.status STDOUT
end
