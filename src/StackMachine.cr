require "./StackMachine/*"

module StackMachine

  STDOUT.sync = true
  STDIN.sync = true
  STDERR.sync = true

  vm = VM.new

  instructions = [
    Instruction.new(true),
    Instruction.new(9),
    Instruction.new(InstructionType::Jump),

    Instruction.new("hello world"),
    Instruction.new(0),
    Instruction.new(InstructionType::Print),

    Instruction.new(true),
    Instruction.new(14),
    Instruction.new(InstructionType::Jump),

    Instruction.new(1023),
    Instruction.new(InstructionType::Read),
    Instruction.new(0),
    Instruction.new(InstructionType::Print),
    Instruction.new(InstructionType::Ret),

    Instruction.new(InstructionType::Halt)
  ]

  vm.run instructions

end
