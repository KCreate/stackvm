require "./stackvm/**"
require "./assembler/utils.cr"

module StackVM
  include Semantic
  include Machine

  debug_program = Array(UInt8 | UInt16 | UInt32 | UInt64){

    # LOADI DWORD 1
    0b00000000_00011100_u16,
    0b00000000_00000000_00000000_00000100_u32,
    0b00000000_00000000_00000000_11111111_u32,

    # LOADI DWORD 1
    0b00000000_00011100_u16,
    0b00000000_00000000_00000000_00000100_u32,
    0b00000000_00000000_00000000_11111111_u32,

    # RPOP
    0b00000000_00000001_u16,
    0b11000000_u8,

    # RPOP
    0b00000000_00000001_u16,
    0b10000000_u8,

    # HALT
    0b00000000_00110010_u16
  }

  binary = Assembler::Utils.convert_opcodes debug_program
  machine = Machine::Machine.new
  machine.flash binary

  machine.start

  machine.status STDOUT
end
