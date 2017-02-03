require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  vm = VM.new

  program = Program{
    PUSH, 25,
    PTOP,
    JMP, 7,

    HALT, 0,

    PUSH, 50,
    PTOP,
    JMP, 5
  }

  vm.init(memory_size: 64) # 64 Int32 values
  vm.run program
  exit_code = vm.regs[EXT]
  puts "Exited with #{exit_code}"
  vm.clean
  exit exit_code

end
