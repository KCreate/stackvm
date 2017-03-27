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

    # 64 bit signed int
    LOADI, QWORD, 25_u64,
    LOADI, QWORD, 25_u64,
    ADD | M_B,

    # 32 bit signed int
    LOADI, DWORD, 25_u32,
    LOADI, DWORD, 25_u32,
    ADD,

    # 64 bit unsigned int
    LOADI, QWORD, 25_u64,
    LOADI, QWORD, 25_u64,
    ADD | M_B | M_S,

    # 32 bit unsigned int
    LOADI, DWORD, -1.to_u32,
    LOADI, DWORD, 25_u32,
    ADD | M_S,

    # 64 bit float
    LOADI, QWORD, 25_f64,
    LOADI, QWORD, 25_f64,
    ADD | M_B | M_T,

    # 32 bit float
    LOADI, DWORD, 25_f32,
    LOADI, DWORD, 25_f32,
    ADD | M_T,

    HALT
  }

  # Create and flash the virtual machine
  machine = Machine::Machine.new
  machine.flash binary

  # Starts the machine debugger
  debugger = Debugger.new machine, STDOUT
  debugger.start
end
