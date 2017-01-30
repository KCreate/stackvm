require "./StackMachine/*"

module StackMachine
  vm = VM.new

  instructions = [
    Instruction.new(200),
    Instruction.new(20),
    Instruction.new(InstructionType::Write),

    Instruction.new(20),
    Instruction.new(InstructionType::Read),
    Instruction.new(0),
    Instruction.new(InstructionType::Print),

    Instruction.new(InstructionType::Halt)
  ]

  vm.run instructions

end
