require "./instruction.cr"
require "./program.cr"
require "readline"

module StackMachine

  # Base class of all exceptions thrown by the VM
  class VMError < Exception
  end

  # Virtual Machine
  class VM
    DEFAULT_MEMORY_SIZE = 1024

    property running : Bool # status
    property stack : Array(BaseType)
    property memory : Array(BaseType | Instruction) # heap memory also including the instructions
    property sp : Int64 # stack pointer
    property ip : Int64 # instruction pointer

    property std_out : IO # standard output
    property std_in : IO # standard input
    property std_err : IO # standard err

    def initialize(memory_size = DEFAULT_MEMORY_SIZE, @std_out = STDOUT, @std_in = STDIN, @std_err = STDERR)
      @running = true
      @stack = [] of BaseType
      @memory = Array(BaseType | Instruction).new(memory_size, nil)
      @sp = 0_i64
      @ip = 0_i64

      # Initialize the callstack
      @memory[memory_size - 1] = 0_f64
    end

    # Run a given sequence of instructions
    def run(instructions : Array(Instruction))

      # Load the instructions into memory
      instructions.each_with_index do |inst, index|
        @memory[index] = inst
      end

      last = 0

      while @running
        inst = @memory[@ip]

        unless inst.is_a? Instruction
          raise VMError.new "Expected instruction at memory address #{@ip}"
        end

        @ip += 1
        last = execute inst
      end

      return last
    end

    # Executes a single instruction
    def execute(instruction : Instruction)

      data = instruction.data

      # Push to the stack if this is not an instruction
      unless instruction.instruction?
        if data.is_a? BaseType
          return load data
        else
          raise VMError.new "Expected instruction data to be a base type, not an instruction identifier"
        end
      end

      # Make sure the data of the instruction is a Float64
      unless data.is_a? InstructionType
        raise VMError.new "Invalid instruction data"
      end

      case type = InstructionType.new data
      when InstructionType::Equal
        return equal
      when InstructionType::Jump
        return jump
      when InstructionType::Write
        return write
      when InstructionType::Read
        return read
      when InstructionType::Print
        return print
      when InstructionType::Halt
        @running = false
      else
        raise VMError.new "Unknown instruction #{type}"
      end
    end

    # Invokes the print instruction
    def print
      target = pop
      value = pop

      # Make sure the target is a Float64
      unless target.is_a? Float64
        raise VMError.new "Expected file handle to be a Numeric"
      end

      target = target.to_i32

      case target
      when 0
        @std_out.print value
      when 1
        @std_in.print value
      when 2
        @std_err.print value
      else
        raise VMError.new "Unknown handle #{target}"
      end
    end

    # Writes a value to heap memory
    def write
      target = pop
      value = pop

      # Make sure the target is a Float64
      unless target.is_a? Float64
        raise VMError.new "Expected target address to be a Numeric"
      end

      target = target.to_i32

      # Check for out-of-bounds write
      if target < 0 || target > @memory.size - 1
        raise VMError.new "Illegal memory write at #{target}"
      end

      @memory[target] = value
    end

    # Writes a value from heap memory
    def read
      target = pop

      # Make sure the target is a Float64
      unless target.is_a? Float64
        raise VMError.new "Expected target address to be a Numeric"
      end

      target = target.to_i32

      # Check for out-of-bounds write
      if target < 0 || target > @memory.size - 1
        raise VMError.new "Illegal memory read at #{target}"
      end

      value = @memory[target]

      if value.is_a? Instruction
        value = value.data

        if value.is_a? InstructionType
          value = value.to_f64
        end
      end

      load value
    end

    # Compares the top two values on the stack
    def equal
      right = pop
      left = pop

      unless left.class == right.class
        load false
      end

      load left == right
    end

    # Jumps to a given location in memory
    def jump
      target = pop
      should_jump = pop

      unless should_jump.is_a? Bool
        raise VMError.new "Expected jump switch to be a bool"
      end

      # Don't jump if should_jump is set to false
      # and increment the instruction pointer to hop over the jump
      unless should_jump
        return
      end

      # Make sure the target is a Float64
      unless target.is_a? Float64
        raise VMError.new "Expected target address to be a Numeric"
      end

      target = target.to_i64

      # Check for out-of-bounds write
      if target < 0 || target > @memory.size - 1
        raise VMError.new "Illegal memory read at #{target}"
      end

      @ip = target
    end

    # Loads a value onto the stack
    def load(value : BaseType)
      @stack << value
      @sp += 1
    end

    # Returns and removes the top of the stack
    # Decrements the stack pointer
    def pop
      value = @stack.pop()
      @sp -= 1
      value
    end
  end

end
