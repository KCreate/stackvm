require "./spec_helper.cr"

describe StackVM::Machine do

  it "creates a new machine" do
    machine = StackVM::Machine::Machine.new 16

    machine.regs.size.should be 19
    machine.regs.bytesize.should be 76

    machine.memory.size should be 16
    machine.memory.bytesize.should be 16
  end

  it "reset's memory" do
    machine = StackVM::Machine::Machine.new 16

    machine.memory[0] = 25_u8
    machine.memory[0].should be 25_u8

    machine.reset_memory

    machine.memory[0].should be 0_u8
  end

  it "flashes data into the machine" do
    machine = StackVM::Machine::Machine.new 16

    machine.flash Slice(UInt8)[25, 25, 25, 25]

    machine.memory[0].should be 25
    machine.memory[1].should be 25
    machine.memory[2].should be 25
    machine.memory[3].should be 25
  end

  it "grows the machines memory section" do
    machine = StackVM::Machine::Machine.new 16

    machine.memory[0] = 25

    machine.memory.size.should be 16
    machine.memory[0].should be 25

    machine.grow 64

    machine.memory.size.should be 64
    machine.memory[0].should be 25
  end

end
