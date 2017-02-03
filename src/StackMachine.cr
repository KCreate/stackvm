require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  vm = VM.new

  program = Program{
    # prepare data that will be overwritten
    PUSH, 0,

    # pop the value into R0
    PUSH, 25,
    POP, R0,

    # write to memory index 0
    STORER, R0, 1,

    # print
    PTOP,
    HALT, 0
  }

  vm.init(memory_size: 64) # 64 Int32 values
  vm.run program
  exit_code = vm.regs[EXT]
  puts "Exited with #{exit_code}"
  vm.clean
  exit exit_code

end
