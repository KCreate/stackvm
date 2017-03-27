require "./spec_helper.cr"

include StackVM::Machine
include StackVM::Semantic
include StackVM::Semantic::OP
include StackVM::Semantic::Reg
include StackVM::Semantic::Size
include Assembler::Utils

describe StackVM::Machine do

  it "creates a new machine" do
    machine = Machine.new 16

    machine.regs.size.should eq 20
    machine.regs.bytesize.should eq 160

    machine.memory.size.should eq 16
    machine.memory.bytesize.should eq 16
  end

  it "reset's memory" do
    machine = Machine.new 16

    machine.memory[0] = 25_u8
    machine.memory[0].should eq 25_u8

    machine.reset_memory

    machine.memory[0].should eq 0_u8
  end

  it "flashes data into the machine" do
    machine = Machine.new 16

    machine.flash Slice[25_u8, 25_u8, 25_u8, 25_u8]

    machine.memory[0].should eq 25
    machine.memory[1].should eq 25
    machine.memory[2].should eq 25
    machine.memory[3].should eq 25
  end

  it "grows the machines memory section" do
    machine = Machine.new 16

    machine.memory[0] = 25_u8

    machine.memory.size.should eq 16
    machine.memory[0].should eq 25

    machine.grow 64

    machine.memory.size.should eq 64
    machine.memory[0].should eq 25
  end

  it "fetches an instruction" do
    machine = Machine.new 16
    machine.flash Assembler::Utils.convert_opcodes EXE{
      LOADI | M_S | M_B
    }

    instruction = machine.fetch

    instruction.should be_a Instruction
    instruction.flag_s.should eq true
    instruction.flag_t.should eq false
    instruction.flag_b.should eq true
    instruction.opcode.should eq LOADI
  end

  it "decodes the length of the LOADI instruction" do
    machine = StackVM::Machine::Machine.new 32
    machine.flash Assembler::Utils.convert_opcodes EXE{
      LOADI, WORD, 25_u16
    }

    instruction = machine.fetch

    instruction.should be_a Instruction
    instruction.flag_s.should eq false
    instruction.flag_t.should eq false
    instruction.flag_b.should eq false
    instruction.opcode.should eq LOADI

    length = machine.decode_instruction_length instruction

    length.should eq 8
  end

  describe "instructions" do

    it "runs RPUSH" do
      machine = Machine.new 32
      machine.flash Assembler::Utils.convert_opcodes EXE{
        RPUSH, R0,
        RPUSH, R0 | M_C,
        RPUSH, R0 | M_C | M_H,
        HALT
      }

      start_sp = machine.regs[StackVM::Semantic::Reg::SP]
      start_sp.should eq 11

      machine.cycle

      sp = machine.regs[StackVM::Semantic::Reg::SP]
      sp.should eq 19

      machine.cycle

      sp = machine.regs[StackVM::Semantic::Reg::SP]
      sp.should eq 23

      machine.cycle

      sp = machine.regs[StackVM::Semantic::Reg::SP]
      sp.should eq 27
    end

  end

end
