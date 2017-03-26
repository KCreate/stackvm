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
      new_memory = Slice(UInt8).new(size, 0_u8)
      @memory.move_to new_memory
      @memory = new_memory

      self
    end

    # Starts the execution of the machine
    def start
      @regs[Reg::IP] = 0
      @regs[Reg::SP] = 0
      @regs[Reg::FP] = 0

      self
    end
  end

end
