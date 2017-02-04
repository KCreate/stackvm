require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  vm = VM.new

  program = Program{

    # this is the bytecode representation of the following
    # pseudo-code
    #
    # print(add(5, 5) * sub(20, 10))
    # func add(a, b) { return a + b }
    # func sub(a, b) { return a - b }

    # add(5, 5)
    PUSH, 5,
    PUSH, 5,
    PUSH, 2, # <- argument count
    CALL, 24,
    PUSHR, AX,

    # sub(20, 10)
    PUSH, 20,
    PUSH, 10,
    PUSH, 2, # <- argument count
    CALL, 32,
    PUSHR, AX,

    # add(5, 5) * sub(20, 10)
    MUL,
    PTOP,
    HALT, 0,

    # function code for add
    LOAD, -4,
    LOAD, -3,
    ADD,
    POP, AX,
    RET,

    # function code for sub
    LOAD, -4,
    LOAD, -3,
    SUB,
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
