require "./spec_helper"

describe StackMachine::Program do

  it "creates a program" do
    data = [
      StackMachine::Instruction.new(0, 200),
      StackMachine::Instruction.new(0, 200),
      StackMachine::Instruction.new(1, StackMachine::InstructionType::Add),
      StackMachine::Instruction.new(1, StackMachine::InstructionType::Print)
    ]

    program = StackMachine::Program.new data

    program.size.should eq(4)

    program[0].header.should eq(0)
    program[1].header.should eq(0)
    program[2].header.should eq(1)
    program[3].header.should eq(1)

    program[0].data.should eq(200)
    program[1].data.should eq(200)
    program[2].data.should eq(0)
    program[3].data.should eq(6)
  end

end
