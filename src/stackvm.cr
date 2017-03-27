require "./stackvm/**"
require "./assembler/utils.cr"

module StackVM
  include Semantic::OP
  include Semantic::Size
  include Semantic::Reg
  include Machine
  include Utils
  include Assembler::Utils

  # Compile the above program to bytes
  binary = Assembler::Utils.convert_opcodes EXE{
    LOADI, 11_u32, "hello world",
    HALT
  }

  # Create and flash the virtual machine
  machine = Machine::Machine.new
  machine.flash binary

  # Starts the machine debugger
  debugger = Debugger.new machine, STDOUT
  debugger.start
end
