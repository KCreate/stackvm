require "./spec_helper"

describe StackMachine::Instruction do

  it "creates instructions from two numbers" do
    inst1 = StackMachine::Instruction.new false, true, 200
    inst2 = StackMachine::Instruction.new false, true, 300
    inst3 = StackMachine::Instruction.new false, true, 400
    inst4 = StackMachine::Instruction.new false, true, 500
    inst5 = StackMachine::Instruction.new false, true, 100_000_000_000_000
    inst6 = StackMachine::Instruction.new false, true, 200_000_000_000_000

    inst1.instruction?.should eq(false)
    inst2.instruction?.should eq(false)
    inst3.instruction?.should eq(false)
    inst4.instruction?.should eq(false)
    inst5.instruction?.should eq(false)
    inst6.instruction?.should eq(false)

    inst1.signed?.should eq(true)
    inst2.signed?.should eq(true)
    inst3.signed?.should eq(true)
    inst4.signed?.should eq(true)
    inst5.signed?.should eq(true)
    inst6.signed?.should eq(true)

    inst1.data.should eq(200)
    inst2.data.should eq(300)
    inst3.data.should eq(400)
    inst4.data.should eq(500)
    inst5.data.should eq(100_000_000_000_000)
    inst6.data.should eq(200_000_000_000_000)
  end

  it "can create instructions from numbers" do
    nums = [0, 1, 2, 3, 4, 5, 6]
    types = [
      StackMachine::InstructionType::Add,
      StackMachine::InstructionType::Sub,
      StackMachine::InstructionType::Mul,
      StackMachine::InstructionType::Div,
      StackMachine::InstructionType::Load,
      StackMachine::InstructionType::Write,
      StackMachine::InstructionType::Print
    ]

    equal = [] of Bool
    nums.each_with_index do |num, index|
      equal << (StackMachine::InstructionType.new(num) == types[index])
    end
    equal.should eq([true, true, true, true, true, true, true])
  end

  it "can encode negative numbers" do
    inst = StackMachine::Instruction.new false, true, -200
    inst.data.should eq(-200)
  end

end
