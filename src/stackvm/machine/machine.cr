require "./errors.cr"
require "../semantic/error.cr"

module StackVM::Machine
  include Semantic

  DEFAULT_MEMORY_SIZE = 65536_u64

  class Machine
    property regs : Slice(UInt64)
    property memory : Slice(UInt8)

    def initialize(memory_size = DEFAULT_MEMORY_SIZE)
      @regs = Slice(UInt64).new(19, 0_u64)
      @memory = Slice(UInt8).new(memory_size, 0_u8)
    end

    # Resets and copies *data* into the machine's memory
    #
    # Raises if *data* is bigger than the machine's
    # memory capacity
    def flash(data : Slice(UInt8))
      if data.bytesize > @memory.bytesize
        raise Error.new Err::OUT_OF_MEMORY, "Trying to write more data than machine capacity"
      end

      reset_memory
      data.copy_to @memory

      self
    end

    # Writes 0 to all memory locations
    def reset_memory
      0.upto(@memory.bytesize - 1) do |i|
        @memory[i] = 0_u8
      end

      self
    end

    # Grows the machine's memory capacity to a given size
    #
    # Does nothing if *size* is smaller than the machine's
    # memory capacity
    def grow(size)
      return self if size <= @memory.bytesize

      # Creates a new slice of size *size*
      # and writes the old memory into it
      @memory = Slice(UInt8).new(size, 0_u8).tap do |new_memory|
        @memory.move_to new_memory
      end

      self
    end

    # Starts the execution of the machine
    def start
      @regs[Reg::IP] = 0
      @regs[Reg::SP] = 0
      @regs[Reg::FP] = 0

      self
    end

    # Fetches the instruction at the current IP
    #
    # Returns a Instruction struct
    def fetch
      address = @regs[Reg::IP]
      bytes : Slice(UInt8)

      begin
        bytes = @memory[address, 2]
        bytes.reverse! # flip because of endianness
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not fetch instruction at #{address.to_s(16)}"
      end

      p1 = Pointer(UInt16).new bytes.to_unsafe.address
      Instruction.new p1[0]
    end

    # Returns the amount of bytes the current instruction takes up
    #
    # This reads type arguments from memory and returns the length of
    # variable-length instructions
    #
    # Example:
    # `LOADI BYTE 25` would use 7 bytes
    # `LOADI WORD 25` would use 8 bytes
    # `LOADI DWORD 25` would use 10 bytes
    # `LOADI QWORD 25` would use 14 bytes
    def decode_instruction_length(instruction : Instruction)

      # Check for fixed length instructions first
      case instruction.opcode
      when OP::ADD, OP::SUB, OP::MUL, OP::DIV, OP::REM,
           OP::EXP, OP::CMP, OP::LT, OP::GT, OP::LTE, OP::GTE, OP::SHR,
           OP::SHL, OP::AND, OP::XOR, OP::NAND, OP::OR, OP::NOT, OP::RET, OP::NOP, OP::HALT
        return 2
      when OP::RPUSH, OP::RPOP, OP::INCR, OP::DECR, OP::JZR, OP::JNZR, OP::JMPR, OP::CALLR
        return 3
      when OP::MOV
        return 4
      when OP::PUTS
        return 6
      when OP::LOADR, OP::STORER, OP::READR, OP::WRITER
        return 7
      when OP::COPY, OP::COPYR
        return 8
      when OP::TRUNC, OP::SE, OP::ZE, OP::JZ, OP::JNZ, OP::JMP, OP::CALL
        return 10
      when OP::LOAD, OP::STORE, OP::INC, OP::DEC, OP::READ, OP::WRITE
        return 14
      when OP::LOADI
        address = @regs[Reg::IP] + 2
        type : Slice(UInt8)

        begin
          type = @memory[address, 4]
          type.reverse! # flip because of endianness
        rescue e : IndexError
          raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not fetch type argument at #{address.to_s(16)}"
        end

        p1 = Pointer(UInt32).new type.to_unsafe.address
        value_bytes = p1[0]

        return 2 + 4 + value_bytes # instruction + argument + value
      else
        raise Error.new Err::INVALID_INSTRUCTION, "#{instruction.opcode.to_s(16)} is not a valid instruction"
      end
    end
  end

end
