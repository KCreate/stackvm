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
      @regs[Reg::IP] = 0_u64
      @regs[Reg::SP] = @executable_size
      @regs[Reg::FP] = @executable_size

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

      self
    end

    # Runs *amount* CPU cycles
    #
    # Same as calling cycle *amount* times
    def cycle(amount)
      amount.times do
        cycle
      end

      self
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
      when OP::ADD
        return op_add
      when OP::SUB
        return op_sub
      when OP::MUL
        return op_mul
      when OP::DIV
        return op_div
      when OP::REM
        return op_rem
      when OP::EXP
        return op_exp
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

    # Reads *amount* of bytes starting at *address*
    def memory_read(address, amount)
      begin
        return @memory[address, amount]
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not read #{amount} bytes at #{address}"
      end
    end

    # Yields a slice starting at *address*
    def memory_read(address)
      begin
        target = @memory + address
        yield target
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not read at #{address}"
      end

      self
    end

    # Reads a *type* value from *address*
    def memory_read_value(address, type : Number.class)
      memory_read address do |source|
        return IO::ByteFormat::LittleEndian.decode type, source
      end
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

    # Yields a slice to write a value to
    def memory_write(address)
      begin
        target = @memory + address
        yield target
      rescue e : IndexError
        raise Error.new Err::ILLEGAL_MEMORY_ACCESS, "Could not write to #{address}"
      end

      self
    end

    # Pops *amount* of bytes from the stack
    def stack_pop(amount)
      value = memory_read @regs[Reg::SP] - amount, amount
      @regs[Reg::SP] -= amount
      value
    end

    # Pops a *type* value from the stack
    def stack_read_value(type : Number.class)
      memory_read_value @regs[Reg::SP] - sizeof(typeof(type)), type
    end

    # Writes *value* onto the stack
    def stack_push(value : Slice(UInt8))
      memory_write @regs[Reg::SP], value
      @regs[Reg::SP] += value.size
      self
    end

    # Yields a slice to write a value to
    def stack_push
      memory_write @regs[Reg::SP] do |target|
        bytes_written = yield target
        @regs[Reg::SP] += bytes_written
      end

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

    # Generates arithmetic instructions
    private macro implement_operator(name, operator)
      def op_{{name}}
        operand_length = @instruction.flag_b ? 8 : 4
        unsigned = @instruction.flag_s
        fpop = @instruction.flag_t

        # Pop the necessary bytes off the stack
        op2 = stack_pop operand_length
        op1 = stack_pop operand_length

        # Branch for different types
        if fpop
          if operand_length == 8
            op1 = IO::ByteFormat::LittleEndian.decode(Float64, op1)
            op2 = IO::ByteFormat::LittleEndian.decode(Float64, op2)
          else
            op1 = IO::ByteFormat::LittleEndian.decode(Float32, op1)
            op2 = IO::ByteFormat::LittleEndian.decode(Float32, op2)
          end

          # Write the result of the calculation onto the stack
          stack_push do |target|

            # Check for stack overflow
            if target.size < operand_length
              raise Error.new Err::STACKOVERFLOW, "Stack overflow"
            end

            IO::ByteFormat::LittleEndian.encode(op1 {{operator.id}} op2, target)
            next operand_length
          end
        else
          if operand_length == 8
            if unsigned
              op1 = IO::ByteFormat::LittleEndian.decode(UInt64, op1)
              op2 = IO::ByteFormat::LittleEndian.decode(UInt64, op2)
            else
              op1 = IO::ByteFormat::LittleEndian.decode(Int64, op1)
              op2 = IO::ByteFormat::LittleEndian.decode(Int64, op2)
            end
          else
            if unsigned
              op1 = IO::ByteFormat::LittleEndian.decode(UInt32, op1)
              op2 = IO::ByteFormat::LittleEndian.decode(UInt32, op2)
            else
              op1 = IO::ByteFormat::LittleEndian.decode(Int32, op1)
              op2 = IO::ByteFormat::LittleEndian.decode(Int32, op2)
            end
          end

          # Write the result of the calculation onto the stack
          stack_push do |target|

            # Check for stack overflow
            if target.size < operand_length
              raise Error.new Err::STACKOVERFLOW, "Stack overflow"
            end

            IO::ByteFormat::LittleEndian.encode(op1 {{operator.id}} op2, target)
            next operand_length
          end
        end

        return false
      end
    end

    # Executes a ADD instruction
    #
    # ```
    # LOADI DWORD 25
    # LOADI DWORD 25
    # ADD # => 50
    # ```
    implement_operator add, :+

    # Executes a SUB instruction
    #
    # ```
    # LOADI DWORD 50
    # LOADI DWORD 25
    # SUB # => 25
    # ```
    implement_operator sub, :-

    # Executes a MUL instruction
    #
    # ```
    # LOADI DWORD 25
    # LOADI DWORD 4
    # MUL # => 100
    # ```
    implement_operator mul, :*

    # Executes a DIV instruction
    #
    # ```
    # LOADI DWORD 25
    # LOADI DWORD 5
    # DIV # => 5
    # ```
    implement_operator div, :/

    # Executes a REM instruction
    #
    # ```
    # LOADI DWORD 25
    # LOADI DWORD 20
    # REM # => 5
    # ```
    implement_operator rem, :%

    # Executes a EXP instruction
    #
    # ```
    # LOADI DWORD 2
    # LOADI DWORD 4
    # EXP # => 16
    # ```
    implement_operator exp, :**

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
