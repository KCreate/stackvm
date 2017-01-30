require "./StackMachine/*"

module StackMachine
  vm = VM.new

  instructions = [
    Instruction.new(false),
    Instruction.new(6),
    Instruction.new(InstructionType::Jump),

    Instruction.new(200),
    Instruction.new(0),
    Instruction.new(InstructionType::Print),

    Instruction.new(300),
    Instruction.new(0),
    Instruction.new(InstructionType::Print),

    Instruction.new(InstructionType::Halt)
  ]

  vm.run instructions

end
