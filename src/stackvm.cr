require "./stackvm/**"

module StackVM
  include Semantic
  include Machine

  DEBUG_PROGRAM = Slice[

    # RPUSH %ip
    0b00000000_u8, 0b00000000_u8,
    0b00010000_u8,

    # RPUSH %ip
    0b00000000_u8, 0b00000000_u8,
    0b00010000_u8,

    # RPUSH %ip
    0b00000000_u8, 0b00000000_u8,
    0b00010000_u8,

    # RPUSH %ip
    0b00000000_u8, 0b00000000_u8,
    0b00010000_u8,

    # HALT
    0b00110010_u8, 0b00000000_u8
  ]

  machine = Machine::Machine.new
  machine.flash DEBUG_PROGRAM

  machine.start

  machine.status STDOUT
end
