require "./spec_helper"

describe StackMachine::Program do

  it "creates a program" do
    data = [
      StackMachine::Instruction.new(false, true, 200),
      StackMachine::Instruction.new(false, true, 200),
      StackMachine::Instruction.new(true, false, StackMachine::InstructionType::Add),
      StackMachine::Instruction.new(true, false, StackMachine::InstructionType::Print)
    ]

    program = StackMachine::Program.new data

    program.size.should eq(4)

    program[0].instruction?.should eq(false)
    program[1].instruction?.should eq(false)
    program[2].instruction?.should eq(true)
    program[3].instruction?.should eq(true)

    program[0].signed?.should eq(true)
    program[1].signed?.should eq(true)
    program[2].signed?.should eq(false)
    program[3].signed?.should eq(false)

    program[0].data.should eq(200)
    program[1].data.should eq(200)
    program[2].data.should eq(0)
    program[3].data.should eq(6)
  end

end
