require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  vm = VM.new

  program = Program{

    # this is the bytecode representation of the following
    # pseudo-code
    #
    # print(1 + 2 + add(3, 4))
    # func add(a, b) { return a + b }

    # calculate the left part
    PUSH, 1,
    PUSH, 2,
    ADD,

    # push arguments
    PUSH, 3,
    PUSH, 4,
    PUSH, 2,

    # call the method
    CALL, 19,
    PUSHR, AX,
    ADD,
    PTOP,
    HALT, 0,

    # add function code
    LOAD, -4,
    LOAD, -3,
    ADD,
    POP, AX,
    RET
  }

  vm.init(memory_size: 64) # 64 Int32 values
  vm.run program
  exit_code = vm.regs[EXT]
  puts "Exited with #{exit_code}"
  vm.clean
  exit exit_code

end
