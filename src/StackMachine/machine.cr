require "./instruction.cr"
require "./program.cr"
require "./tool.cr"
require "readline"

module StackMachine

  # Base class of all exceptions thrown by the VM
  class VMError < Exception
  end

  # Virtual Machine
  class VM
    include Tool(VMError)

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
        assert_type inst, Instruction, "Expected instruction at memory address #{@ip}"
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
        assert_type data, BaseType, "Expected instruction data to be a base type, not an instruction identifier" do
          return load data
        end
      end

      # Make sure the data of the instruction is a Float64
      assert_type data, InstructionType, "Invalid instruction data"

      case type = InstructionType.new data
      when InstructionType::Equal
        return instruction_equal
      when InstructionType::Jump
        return instruction_jump
      when InstructionType::Write
        return instruction_write
      when InstructionType::Read
        return instruction_read
      when InstructionType::Print
        return instruction_print
      when InstructionType::Halt
        @running = false
      else
        raise VMError.new "Unknown instruction #{type}"
      end
    end

    # Invokes the print instruction
    def instruction_print
      target = pop
      value = pop

      assert_type target, Float64, "Expected file handle to be a Numeric" do
        target = target.to_i32
      end

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
    def instruction_write
      target = pop
      value = pop

      assert_type target, Float64, "Expected target address to be a Numeric" do
        target = target.to_i32
      end

      # Check for out-of-bounds write
      if target < 0 || target > @memory.size - 1
        raise VMError.new "Illegal memory write at #{target}"
      end

      @memory[target] = value
    end

    # Writes a value from heap memory
    def instruction_read
      target = pop

      assert_type target, Float64, "Expected target address to be a Numeric" do
        target = target.to_i32
      end

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
    def instruction_equal
      right = pop
      left = pop

      unless left.class == right.class
        load false
      end

      load left == right
    end

    # Jumps to a given location in memory
    def instruction_jump
      target = pop
      should_jump = pop

      assert_type should_jump, Bool, "Expected jump switch to be a bool"

      # Don't jump if should_jump is set to false
      # and increment the instruction pointer to hop over the jump
      unless should_jump
        return
      end

      # Make sure the target is a Float64
      assert_type target, Float64, "Expected target address to be a Numeric"

      target = target.to_i64

      # Check for out-of-bounds write
      if target < 0 || target > @memory.size - 1
        raise VMError.new "Illegal memory read at #{target}"
      end

      # Update the callstack
      height = @memory[@memory.size - 1]
      assert_type height, Float64, "Expected value at address #{@memory.size - 1} to be a Numeric"
      target_offset = (@memory.size - 2) - height
      target_offset = target_offset.to_i64
      @memory[target_offset] = @ip.to_f64 + 1_f64
      @memory[@memory.size - 1] = height + 1_f64

      # Set the instruction pointer
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
