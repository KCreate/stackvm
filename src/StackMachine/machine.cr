require "./register.cr"
require "./opcode.cr"
require "./program.cr"

module StackMachine
  include OP
  include Reg
  include Error

  # Virtual Machine
  class VM
    property regs : Slice(Int32) # registers
    property memory : Slice(Int32) # stack
    property data : Slice(Int32) # code memory

    # Initialize an empty VM
    def initialize
      @regs = Slice(Int32).new(REGISTER_COUNT, 0) # amount of registers defined in register.cr
      @memory = Slice(Int32).empty
      @data = Slice(Int32).empty
    end

    # Initialize with given amount of memory
    def init(memory_size : Int32 = 1024)
      @memory = Slice(Int32).new(memory_size, 0)
    end

    # Clean up
    def clean
      @regs = Slice(Int32).new(REGISTER_COUNT, 0) # amount of registers defined in register.cr
      @memory = Slice(Int32).empty
      @data = Slice(Int32).empty
    end

    # Runs a Program
    def run(program : Program)

      # initialize code memory
      @data = Slice(Int32).new(program.data.size, NOP)

      # load the program into code memory
      program.data.each_with_index  do |opcode, index|
        @data[index] = opcode
      end

      # initialize stack and frame pointers
      @regs[SP] = -1
      @regs[FP] = -1

      # begin executing the program
      return main_loop
    end

    # Begins executing the program
    @[AlwaysInline]
    private def main_loop
      while @regs[RUN] == 0
        execute
      end

      return @regs[EXT]
    end

    # Executes the current instruction
    @[AlwaysInline]
    private def execute

      # load the current instruction
      instruction = @data[@regs[IP]]
      @regs[IP] += 1

      # check if this is a known instruction
      unless OP.valid instruction
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_INSTRUCTION
        return
      end

      case instruction
      when ADD
        return op_add
      when SUB
        return op_sub
      when MUL
        return op_mul
      when DIV
        return op_div
      when POW
        return op_pow
      when REM
        return op_rem
      when LOADR
        return op_loadr
      when PUSH
        return op_push
      when PTOP
        return op_ptop
      when HALT
        return op_halt
      else
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_INSTRUCTION
        return
      end
    end

    # pop method for internal use
    @[AlwaysInline]
    private def i_pop
      value = i_peek
      @regs[SP] -= 1
      return value
    end

    # peek method for internal use
    @[AlwaysInline]
    private def i_peek

      # check for a stack underflow
      if @regs[SP] < 0
        @regs[RUN] = 1
        @regs[EXT] = STACK_UNDERFLOW
        return nil
      end

      return @memory[@regs[SP]]
    end

    # Executes a ADD instruction
    #
    # Pops off the top two values on the stack
    # and pushes their sum
    @[AlwaysInline]
    private def op_add

      # pop off two values
      left = i_pop
      right = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)

      # load the value onto the stack
      @memory[@regs[SP] + 1] = left + right
      @regs[SP] += 1
    end

    # Executes a SUB instruction
    #
    # Pops off the top two values on the stack
    # and pushes their difference (left - right)
    @[AlwaysInline]
    private def op_sub

      # pop off two values
      left = i_pop
      right = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)

      # load the value onto the stack
      @memory[@regs[SP] + 1] = left - right
      @regs[SP] += 1
    end

    # Executes a MUL instruction
    #
    # Pops off the top two values on the stack
    # and pushes their product
    @[AlwaysInline]
    private def op_mul

      # pop off two values
      left = i_pop
      right = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)

      # load the value onto the stack
      @memory[@regs[SP] + 1] = left * right
      @regs[SP] += 1
    end

    # Executes a DIV instruction
    #
    # Pops off the top two values on the stack
    # and pushes their quotient
    @[AlwaysInline]
    private def op_div

      # pop off two values
      left = i_pop
      right = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)

      # load the value onto the stack
      @memory[@regs[SP] + 1] = left / right
      @regs[SP] += 1
    end

    # Executes a POW instruction
    #
    # Pops off the top two values on the stack
    # and pushes their power
    @[AlwaysInline]
    private def op_pow

      # pop off two values
      left = i_pop
      right = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)

      # load the value onto the stack
      @memory[@regs[SP] + 1] = left ** right
      @regs[SP] += 1
    end

    # Executes a REM instruction
    #
    # Pops off the top two values on the stack
    # and pushes their remainder
    @[AlwaysInline]
    private def op_rem

      # pop off two values
      left = i_pop
      right = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)

      # load the value onto the stack
      @memory[@regs[SP] + 1] = left % right
      @regs[SP] += 1
    end

    # Executes a LOADR instruction
    # Loads a given value into a given register
    @[AlwaysInline]
    private def op_loadr
      register_address = @regs[IP]
      value_address = @regs[IP] + 1
      @regs[IP] += 2

      # make sure there are enough arguments
      if value_address < 0 || value_address >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      register = @data[register_address]
      value = @data[value_address]

      # check that if this is a valid register identifier
      unless Reg.valid register
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      @regs[register] = value
    end

    # Executes a PUSH instruction
    # Pushes a value onto the stack
    @[AlwaysInline]
    private def op_push
      arg_address = @regs[IP]

      # check if there is an argument
      if arg_address < 0 || arg_address >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      argument = @data[arg_address]
      @regs[IP] += 1

      # check if there is space on the stack
      target_address = @regs[SP] + 1
      if target_address >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = STACK_OVERFLOW
        return
      end

      @memory[target_address] = argument
      @regs[SP] += 1
    end

    # Executes a PTOP instruction
    #
    # Prints the top of the stack
    @[AlwaysInline]
    private def op_ptop
      value = i_peek
      return unless value.is_a?(Int32)
      puts value
    end

    # Executes a HALT instruction
    #
    # Halts the machine
    #
    # Sets the RUN register to 1
    # Set the EXT register to a given exit code
    @[AlwaysInline]
    private def op_halt
      arg_address = @regs[IP]
      @regs[IP] += 1

      # check if there is an argument
      if arg_address < 0 || arg_address >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      @regs[RUN] = 1
      @regs[EXT] = @data[arg_address]
    end
  end

end
