require "./syntax/ast.cr"
require "./syntax/parser.cr"
require "./semantic.cr"

module StackMachine::Assembler

  INSTRUCTION_OPCODES = {
    "add" => 0x00,
    "sub" => 0x01,
    "mul" => 0x02,
    "div" => 0x03,
    "pow" => 0x04,
    "rem" => 0x05,
    "shr" => 0x08,
    "shl" => 0x09,
    "not" => 0x0a,
    "xor" => 0x0b,
    "or" => 0x0c,
    "and" => 0x0d,
    "incr" => 0x0e,
    "decr" => 0x0f,
    "inc" => 0x10,
    "dec" => 0x11,
    "loadr" => 0x12,
    "load" => 0x13,
    "store" => 0x14,
    "storer" => 0x15,
    "mov" => 0x16,
    "pushr" => 0x17,
    "push" => 0x18,
    "pop" => 0x19,
    "cmp" => 0x1a,
    "lt" => 0x1b,
    "gt" => 0x1c,
    "jz" => 0x1d,
    "jnz" => 0x1f,
    "jmp" => 0x21,
    "call" => 0x23,
    "ret" => 0x24,
    "preg" => 0x25,
    "ptop" => 0x26,
    "halt" => 0x27,
    "nop" => 0x28
  }

  REGISTER_CODES = {
    "r0" => 0,
    "r1" => 1,
    "r2" => 2,
    "r3" => 3,
    "r4" => 4,
    "r5" => 5,
    "r6" => 6,
    "r7" => 7,
    "r8" => 8,
    "r9" => 9,
    "ax" => 10,
    "ip" => 11,
    "sp" => 12,
    "fp" => 13,
    "run" => 14,
    "ext" => 15,
  }

  class Assembler
    property label_addresses : Hash(String, Int32)

    def initialize
      @label_addresses = {} of String => Int32
    end

    def build(source : String)
      mod = Parser.parse source
      mod = Semantic.new(mod).analyse
      mod = align mod

      intermediate_opcodes = [] of Int32 | Label

      # codegen all instructions
      mod.blocks.each do |block|
        label_addresses[block.name] = intermediate_opcodes.size
        codegen_block block, intermediate_opcodes
      end

      # now resolve all labels
      final_opcodes = [] of Int32
      intermediate_opcodes.each do |opcode|
        if opcode.is_a? Label
          final_opcodes << label_addresses[opcode.name]
        else
          final_opcodes << opcode
        end
      end

      final_opcodes
    end

    def codegen_block(block : Block, target)
      block.instructions.each do |instruction|
        target << INSTRUCTION_OPCODES[instruction.name]
        instruction.arguments.each do |arg|
          if arg.is_a? Number
            target << arg.value
          end

          if arg.is_a? Register
            target << REGISTER_CODES[arg.name.downcase]
          end

          if arg.is_a? Label
            target << arg
          end
        end
      end
    end

    def align(mod)
      mod.blocks.sort_by! do |block|
        block.name == "entry" ? 0 : 1
      end
      mod
    end

  end

end
