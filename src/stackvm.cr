require "./stackvm/**"
require "./assembler/utils.cr"

module StackVM
  include Semantic::OP
  include Semantic::Size
  include Semantic::Reg
  include Machine
  include Utils

  debug_program = Array(UInt8 | UInt16 | UInt32 | UInt64){
    LOADI, DWORD, 0xff_u32,
    LOADI, DWORD, 0xff_u32,
    RPOP, R0 | M_C,
    RPOP, R0 | M_C | M_H,
    HALT
  }

  # Compile the above program to bytes
  binary = Assembler::Utils.convert_opcodes debug_program

  # Create and flash the virtual machine
  machine = Machine::Machine.new
  machine.flash binary

  # Starts the machine debugger
  debugger = Debugger.new machine, STDOUT
  debugger.start
end
