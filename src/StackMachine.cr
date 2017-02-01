require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  STDOUT.sync = true
  STDIN.sync = true
  STDERR.sync = true

  vm = VM.new

  program = Program{
    PUSH, 25,
    PUSH, 25,
    ADD,
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
