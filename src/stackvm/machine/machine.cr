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
      @regs = Slice(UInt64).new(20, 0_u64)
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
      when OP::RPUSH
        return op_rpush
      when OP::RPOP
        return op_rpop
      when OP::LOADI
        return op_loadi
      when OP::HALT
        return op_halt
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

      opcode = IO::ByteFormat::LittleEndian.decode UInt16, bytes
      Instruction.new opcode
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
          type = memory_read address, 4
        rescue e : IndexError
          raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not fetch type argument at #{address.to_s(16)}"
        end

        value_bytes = IO::ByteFormat::LittleEndian.decode UInt32, type

        return 2 + 4 + value_bytes # instruction + argument + value
      else
        raise Error.new Err::INVALID_INSTRUCTION, "#{instruction.opcode.to_s(16)} is not a valid instruction"
      end
    end

    # Outputs human-readable debug information to *output*
    def status(output : IO)
      output.puts "Memory-size: #{@memory.size}"
      output.puts "Executable-size: #{@executable_size}"
      output.puts "Registers:"
      output.puts "
  r0: 0x#{@regs[Reg::R0].to_s(16).rjust(16, '0')}    r8:  0x#{@regs[Reg::R8].to_s(16).rjust(16, '0')}
  r1: 0x#{@regs[Reg::R1].to_s(16).rjust(16, '0')}    r9:  0x#{@regs[Reg::R9].to_s(16).rjust(16, '0')}
  r2: 0x#{@regs[Reg::R2].to_s(16).rjust(16, '0')}    r10: 0x#{@regs[Reg::R10].to_s(16).rjust(16, '0')}
  r3: 0x#{@regs[Reg::R3].to_s(16).rjust(16, '0')}    r11: 0x#{@regs[Reg::R11].to_s(16).rjust(16, '0')}
  r4: 0x#{@regs[Reg::R4].to_s(16).rjust(16, '0')}    r12: 0x#{@regs[Reg::R12].to_s(16).rjust(16, '0')}
  r5: 0x#{@regs[Reg::R5].to_s(16).rjust(16, '0')}    r13: 0x#{@regs[Reg::R13].to_s(16).rjust(16, '0')}
  r6: 0x#{@regs[Reg::R6].to_s(16).rjust(16, '0')}    r14: 0x#{@regs[Reg::R14].to_s(16).rjust(16, '0')}
  r7: 0x#{@regs[Reg::R7].to_s(16).rjust(16, '0')}    r15: 0x#{@regs[Reg::R15].to_s(16).rjust(16, '0')}

  ip: 0x#{@regs[Reg::IP].to_s(16).rjust(16, '0')}    sp:  0x#{@regs[Reg::SP].to_s(16).rjust(16, '0')}
  fp: 0x#{@regs[Reg::FP].to_s(16).rjust(16, '0')}
      "
      output.puts "Stack: #{@regs[Reg::SP] - @executable_size} bytes"

      stack_memory = memory_read(@executable_size, @regs[Reg::SP] - @executable_size)
      output.puts stack_memory.hexdump
    end

    # Reads *amount* of bytes starting at *address*
    def memory_read(address, amount)
      begin
        return @memory[address, amount]
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not read #{amount} bytes at #{address}"
      end
    end

    # Reads a *type* value from *address*
    def memory_read_value(address, type : Number.class)
      bytes = memory_read address, amount
      IO::ByteFormat::LittleEndian.decode type, bytes
    end

    # Writes *value* to *address*
    def memory_write(address, value : Slice(UInt8))
      begin
        target = @memory + address
        value.copy_to target
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not write #{value.size} bytes to #{address}"
      end

      self
    end

    # Pops *amount* of bytes from the stack
    def stack_pop(amount)
      value = memory_read @regs[Reg::SP] - amount, amount
      @regs[Reg::SP] -= amount
      value
    end

    # Writes *value* onto the stack
    def stack_push(value : Slice(UInt8))
      memory_write @regs[Reg::SP], value
      @regs[Reg::SP] += value.size
      self
    end

    # Reads the contents of *reg*
    def reg_read(reg : Register)

      # Check for invalid register
      if reg.regcode < 0 || reg.regcode > 20
        raise Error.new Err::INVALID_REGISTER, "#{reg.regcode.to_s(16)} is not a valid register"
      end

      # Complete or sub portion
      unless reg.subportion
        bytes = @regs + reg.regcode
        bytes = Slice(UInt8).new(Pointer(UInt8).new(bytes.to_unsafe.address), 8)
        return bytes
      else
        unless reg.higher
          bytes = @regs + reg.regcode
          bytes = Slice(UInt8).new(Pointer(UInt8).new(bytes.to_unsafe.address), 4)
          return bytes
        else
          bytes = @regs + reg.regcode
          bytes = Slice(UInt8).new(Pointer(UInt8).new(bytes.to_unsafe.address + 4), 4)
          return bytes
        end
      end
    end

    # Writes *value* to *reg*
    def reg_write(reg : Register, value : Slice(UInt8))

      # Check for invalid register
      if reg.regcode < 0 || reg.regcode > 20
        raise Error.new Err::INVALID_INSTRUCTION, "#{reg.regcode.to_s(16)} is not a valid register"
      end

      target : Slice(UInt8)

      # Complete or sub portion
      unless reg.subportion
        bytes = @regs + reg.regcode
        target = Slice(UInt8).new(Pointer(UInt8).new(bytes.to_unsafe.address), 8)
      else
        unless reg.higher
          bytes = @regs + reg.regcode
          target = Slice(UInt8).new(Pointer(UInt8).new(bytes.to_unsafe.address), 4)
        else
          bytes = @regs + reg.regcode
          target = Slice(UInt8).new(Pointer(UInt8).new(bytes.to_unsafe.address + 4), 4)
        end
      end

      # Overwrite the old data in the register with zeros
      unless reg.subportion
        Slice[0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8].copy_to target
      else
        Slice[0_u8, 0_u8, 0_u8, 0_u8].copy_to target
      end

      value.copy_to target

      self
    end

    # Executes a RPUSH instruction
    #
    # ```
    # LOADI QWORD 25
    # RPOP %r0
    # RPUSH %r0 # => 25
    # ```
    def op_rpush
      reg = memory_read(@regs[Reg::IP] + 2, 1)
      reg = Register.new reg[0]
      stack_push reg_read reg
      return false
    end

    # Executes a RPOP instruction
    #
    # ```
    # LOADI QWORD 25
    # RPOP %r0 # pops 25 into r0
    # ```
    def op_rpop
      reg = memory_read(@regs[Reg::IP] + 2, 1)
      reg = Register.new reg[0]

      if reg.subportion
        reg_write reg, stack_pop 4
      else
        reg_write reg, stack_pop 8
      end

      return false
    end

    # Executes a LOADI instruction
    #
    # ```
    # LOADI WORD 25 # => 8 bytes
    # LOADI QWORD 30 # => 14
    # ```
    def op_loadi

      # Decodes the amount of bytes that are being pushed
      type = memory_read(@regs[Reg::IP] + 2, 2)
      type = Pointer(UInt32).new type.to_unsafe.address
      amount_of_bytes = type[0]

      # Reads *type* bytes
      value = memory_read(@regs[Reg::IP] + 6, amount_of_bytes)
      stack_push value

      return false
    end

    # Executes a HALT instruction
    #
    # ```
    # HALT
    # ```
    def op_halt
      return false
    end
  end

end
