require "./spec_helper"

describe StackMachine::Instruction do

  it "creates instructions from 32bit integers" do
    raw = 13_835_058_055_282_167_891
    instruction = StackMachine::Instruction.new raw

    instruction.header.should eq(3)
    instruction.data.should eq(4179)
  end

  it "creates instructions from two numbers" do
    inst1 = StackMachine::Instruction.new 0, 200
    inst2 = StackMachine::Instruction.new 1, 300
    inst3 = StackMachine::Instruction.new 2, 400
    inst4 = StackMachine::Instruction.new 3, 500
    inst5 = StackMachine::Instruction.new 4, 100_000_000_000_000
    inst6 = StackMachine::Instruction.new 5, 200_000_000_000_000

    inst1.header.should eq(0)
    inst2.header.should eq(1)
    inst3.header.should eq(2)
    inst4.header.should eq(3)
    inst5.header.should eq(0)
    inst6.header.should eq(1)

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

end
