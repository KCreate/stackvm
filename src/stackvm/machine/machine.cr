require "./errors.cr"
require "../semantic/error.cr"

module StackVM::Machine
  include Semantic

  DEFAULT_MEMORY_SIZE = 65536

  class Machine
    property regs : Slice(UInt64)
    property memory : Slice(UInt8)
    property instruction : Instruction
    property executable_size : UInt64

    def initialize(memory_size = DEFAULT_MEMORY_SIZE)
      @regs = Slice(UInt64).new(19, 0_u64)
      @memory = Slice(UInt8).new(memory_size, 0_u8)
      @instruction = Instruction.new 0b00000000_00110000_u16
      @executable_size = 0_u64
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

      @executable_size = data.bytesize.to_u64

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
      @regs[Reg::IP] = 0_u64
      @regs[Reg::SP] = @executable_size
      @regs[Reg::FP] = @executable_size

      while @instruction.opcode != OP::HALT
        cycle
      end

      self
    end

    # Runs a single CPU cycle
    #
    # Fetches a new instruction, executes it and unless the instruction changed the IP,
    # sets the IP to the address of the next instruction in memory
    def cycle
      @instruction = fetch
      did_jump = execute

      unless did_jump
        instruction_length = decode_instruction_length @instruction
        @regs[Reg::IP] += instruction_length
      end
    end

    # Executes the current instruction
    #
    # Returns true if the instruction changed the IP
    def execute
      case @instruction.opcode
      when OP::LOADI
        return op_loadi
      when OP::HALT
        return false
      else
        raise Error.new Err::INVALID_INSTRUCTION, "#{@instruction.opcode.to_s(16)} is not a valid instruction"
      end
    end

    # Fetches the instruction at the current IP
    #
    # Returns a Instruction struct
    def fetch
      address = @regs[Reg::IP]
      bytes : Slice(UInt8)

      begin
        bytes = @memory[address, 2]
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

    # Outputs human-readable debug information to *output*
    def status(output : IO)
      output.puts "Memory-size: #{@memory.size}"
      output.puts "Executable-size: #{@executable_size}"
      output.puts ""
      output.puts "Registers:"
      output.puts "
        r0: 0x#{@regs[Reg::R0].to_s(16)}    r8:  0x#{@regs[Reg::R8].to_s(16)}
        r1: 0x#{@regs[Reg::R1].to_s(16)}    r9:  0x#{@regs[Reg::R9].to_s(16)}
        r2: 0x#{@regs[Reg::R2].to_s(16)}    r10: 0x#{@regs[Reg::R10].to_s(16)}
        r3: 0x#{@regs[Reg::R3].to_s(16)}    r11: 0x#{@regs[Reg::R11].to_s(16)}
        r4: 0x#{@regs[Reg::R4].to_s(16)}    r12: 0x#{@regs[Reg::R12].to_s(16)}
        r5: 0x#{@regs[Reg::R5].to_s(16)}    r13: 0x#{@regs[Reg::R13].to_s(16)}
        r6: 0x#{@regs[Reg::R6].to_s(16)}    r14: 0x#{@regs[Reg::R14].to_s(16)}
        r7: 0x#{@regs[Reg::R7].to_s(16)}    r15: 0x#{@regs[Reg::R15].to_s(16)}

        ip: 0x#{@regs[Reg::IP].to_s(16)}    sp:  0x#{@regs[Reg::SP].to_s(16)}
        fp: 0x#{@regs[Reg::FP].to_s(16)}
      "
      output.puts ""
      output.puts "Memory:"

      stack_memory = read_memory(@executable_size, @regs[Reg::SP] - @executable_size)
      output.puts stack_memory.hexdump
    end

    # Reads *amount* of bytes starting at *address*
    def read_memory(address, amount)
      begin
        return @memory[address, amount]
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not read #{amount} bytes at #{address}"
      end
    end

    # Writes *value* to *address*
    def write_memory(address, value : Slice(UInt8))
      begin
        target = @memory + address
        value.copy_to target
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not write #{value.size} bytes to #{address}"
      end
    end

    # Executes a LOADI instruction
    def op_loadi

      # Decodes the amount of bytes that are being pushed
      type = read_memory(@regs[Reg::IP] + 2, 2)
      type = Pointer(UInt32).new type.to_unsafe.address
      amount_of_bytes = type[0]

      # Reads *type* bytes
      value = read_memory(@regs[Reg::IP] + 6, amount_of_bytes)

      # Writes those values onto the stack
      write_memory @regs[Reg::SP], value

      # Increments the stack pointer
      @regs[Reg::SP] += amount_of_bytes

      return false
    end
  end

end
