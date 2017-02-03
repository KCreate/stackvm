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
      when SHR
        return op_shr
      when SHL
        return op_shl
      when NOT
        return op_not
      when XOR
        return op_xor
      when OR
        return op_or
      when AND
        return op_and
      when INCR
        return op_incr
      when DECR
        return op_decr
      when INC
        return op_inc
      when DEC
        return op_dec
      when LOADR
        return op_loadr
      when LOAD
        return op_load
      when STORE
        return op_store
      when STORER
        return op_storer
      when MOV
        return op_mov
      when PUSHR
        return op_pushr
      when PUSH
        return op_push
      when POP
        return op_pop
      when CMP
        return op_cmp
      when LT
        return op_lt
      when GT
        return op_gt
      when PTOP
        return op_ptop
      when HALT
        return op_halt
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

    # internal method to push something onto the stack
    @[AlwaysInline]
    private def i_push(value : Int32)

      # check that there is space on the stack
      if @regs[SP] + 1 >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = STACK_OVERFLOW
        return nil
      end

      @memory[@regs[SP] + 1] = value
      @regs[SP] += 1
    end

    # Executes a ADD instruction
    #
    # Pops off the top two values on the stack
    # and pushes their sum
    @[AlwaysInline]
    private def op_add
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left + right
    end

    # Executes a SUB instruction
    #
    # Pops off the top two values on the stack
    # and pushes their difference (left - right)
    @[AlwaysInline]
    private def op_sub
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left - right
    end

    # Executes a MUL instruction
    #
    # Pops off the top two values on the stack
    # and pushes their product
    @[AlwaysInline]
    private def op_mul
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left * right
    end

    # Executes a DIV instruction
    #
    # Pops off the top two values on the stack
    # and pushes their quotient
    @[AlwaysInline]
    private def op_div
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left / right
    end

    # Executes a POW instruction
    #
    # Pops off the top two values on the stack
    # and pushes their power
    @[AlwaysInline]
    private def op_pow
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left ** right
    end

    # Executes a REM instruction
    #
    # Pops off the top two values on the stack
    # and pushes their remainder
    @[AlwaysInline]
    private def op_rem
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left % right
    end

    # Executes a SHR instruction
    #
    # Pops of a value from the stack and right-shifts by the second-highest value
    @[AlwaysInline]
    private def op_shr
      amount = i_pop
      value = i_pop
      return unless amount.is_a?(Int32) && value.is_a?(Int32)
      i_push value >> amount
    end

    # Executes a SHL instruction
    #
    # Pops of a value from the stack and left-shifts by the second-highest value
    @[AlwaysInline]
    private def op_shl
      amount = i_pop
      value = i_pop
      return unless amount.is_a?(Int32) && value.is_a?(Int32)
      i_push value << amount
    end

    # Executes a NOT instruction
    #
    # Pops of a value from the stack and pushes the bitwise NOT onto the stack
    @[AlwaysInline]
    private def op_not
      value = i_pop
      return unless value.is_a?(Int32)
      i_push ~value
    end

    # Executes a XOR instruction
    #
    # Pops of two values from the stack and pushes the bitwise XOR onto the stack
    @[AlwaysInline]
    private def op_xor
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left ^ right
    end

    # Executes a OR instruction
    #
    # Pops of two values from the stack and pushes the bitwise OR onto the stack
    @[AlwaysInline]
    private def op_or
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left | right
    end

    # Executes a AND instruction
    #
    # Pops of two values from the stack and pushes the bitwise AND onto the stack
    @[AlwaysInline]
    private def op_and
      right = i_pop
      left = i_pop
      return unless left.is_a?(Int32) && right.is_a?(Int32)
      i_push left & right
    end

    # Executes a INCR instruction
    #
    # Increments a value in a given register
    private def op_incr
      reg_address = @regs[IP]
      @regs[IP] += 1

      # make sure there are enough arguments
      if reg_address < 0 || reg_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      register = @data[reg_address]

      # check if this is a valid register
      unless Reg.valid register
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      @regs[register] += 1
    end

    # Executes a DECR instruction
    #
    # Decrements a value in a given register
    private def op_decr
      reg_address = @regs[IP]
      @regs[IP] += 1

      # make sure there are enough arguments
      if reg_address < 0 || reg_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      register = @data[reg_address]

      # check if this is a valid register
      unless Reg.valid register
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      @regs[register] -= 1
    end

    # Executes a INC instruction
    #
    # Increments the top of the stack
    @[AlwaysInline]
    private def op_inc
      value = i_pop
      return unless value.is_a? Int32
      i_push value + 1
    end

    # Executes a DEC instruction
    #
    # Decrements the top of the stack
    @[AlwaysInline]
    private def op_dec
      value = i_pop
      return unless value.is_a? Int32
      i_push value - 1
    end

    # Executes a LOADR instruction
    # Loads a given value into a given register
    @[AlwaysInline]
    private def op_loadr
      register_address = @regs[IP]
      value_address = @regs[IP] + 1
      @regs[IP] += 2

      # make sure there are enough arguments
      if register_address < 0 || value_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      register = @data[register_address]
      value = @data[value_address]

      # check if this is a valid register
      unless Reg.valid register
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      @regs[register] = value
    end

    # Executes a LOAD instruction
    #
    # Loads the value at fp + diff onto the stack
    @[AlwaysInline]
    private def op_load
      diff_address = @regs[IP]
      @regs[IP] += 1

      # make sure there are enough arguments
      if diff_address < 0 || diff_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      address = @regs[FP] + @data[diff_address]

      # check for out-of-bounds
      if address < 0 || address >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = ILLEGAL_MEMORY_ACCESS
        return
      end

      i_push @memory[address]
    end

    # Executes a STORE instruction
    #
    # Stores a value at location fp + diff
    @[AlwaysInline]
    private def op_store
      value_address = @regs[IP]
      diff_address = @regs[IP] + 1
      @regs[IP] += 2

      # check for out of bounds
      if value_address < 0 || diff_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      value = @data[value_address]
      diff = @regs[FP] + @data[diff_address]

      # make sure the stack index is inside the memory area
      if diff < 0 || diff >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = ILLEGAL_MEMORY_ACCESS
        return
      end

      @memory[diff] = value
    end

    # Executes a STORER instruction
    #
    # Stores value in register at location fp + diff
    private def op_storer
      register_address = @regs[IP]
      diff_address = @regs[IP] + 1
      @regs[IP] += 2

      # check out of bounds
      if register_address < 0 || diff_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      register = @data[register_address]
      diff = @regs[FP] + @data[diff_address]

      # make sure the stack index is inside the memory
      if diff < 0 || diff >= @memory.size
        @regs[RUN] = 1
        @regs[EXT] = ILLEGAL_MEMORY_ACCESS
        return
      end

      # check if register is valid
      unless Reg.valid register
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      @memory[diff] = @regs[register]
    end

    # Executes a MOV instruction
    # Copies a value from a register into another
    @[AlwaysInline]
    private def op_mov
      target_address = @regs[IP]
      source_address = @regs[IP] + 1
      @regs[IP] += 2

      # make sure there are enough arguments
      if target_address < 0 || source_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      target = @data[target_address]
      source = @data[source_address]

      # check that they are valid registers
      unless Reg.valid(target) && Reg.valid(source)
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      @regs[target] = @regs[source]
    end

    # Executes a PUSHR instruction
    # Pushes a value from a register onto the stack
    @[AlwaysInline]
    private def op_pushr
      source_address = @regs[IP]
      @regs[IP] += 1

      # make sure there are enough arguments
      if source_address < 0 || source_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      source = @data[source_address]

      # check that it is a valid register
      unless Reg.valid source
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      i_push @regs[source]
    end

    # Executes a PUSH instruction
    # Pushes a value onto the stack
    @[AlwaysInline]
    private def op_push
      arg_address = @regs[IP]
      @regs[IP] += 1

      # check if there is an argument
      if arg_address < 0 || arg_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      i_push @data[arg_address]
    end

    # Executes a POP instruction
    # Pops a value from the stack into a given register
    @[AlwaysInline]
    private def op_pop
      target_address = @regs[IP]
      @regs[IP] += 1

      # check if there is an argument
      if target_address < 0 || target_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      # load the value from code memory
      target = @data[target_address]

      # check if it's a valid register
      unless Reg.valid target
        @regs[RUN] = 1
        @regs[EXT] = UNKNOWN_REGISTER
        return
      end

      value = i_pop
      return unless value.is_a? Int32

      @regs[target] = value
    end

    # Executes a CMP instruction
    #
    # Pops off two values from the stack and pushes 0 if they are equal
    @[AlwaysInline]
    private def op_cmp
      first = i_pop
      second = i_pop
      return unless first.is_a?(Int32) && second.is_a?(Int32)
      i_push first == second ? 0 : 1
    end

    # Executes a LT instruction
    #
    # Pops off two values from the stack and pushes 0 if lower < top
    @[AlwaysInline]
    private def op_lt
      upper = i_pop
      lower = i_pop
      return unless upper.is_a?(Int32) && lower.is_a?(Int32)
      i_push lower < upper ? 0 : 1
    end

    # Executes a GT instruction
    #
    # Pops off two values from the stack and pushes 0 if lower > top
    @[AlwaysInline]
    private def op_gt
      upper = i_pop
      lower = i_pop
      return unless upper.is_a?(Int32) && lower.is_a?(Int32)
      i_push lower > upper ? 0 : 1
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
      if arg_address < 0 || arg_address >= @data.size
        @regs[RUN] = 1
        @regs[EXT] = MISSING_ARGUMENTS
        return
      end

      @regs[RUN] = 1
      @regs[EXT] = @data[arg_address]
    end
  end

end
