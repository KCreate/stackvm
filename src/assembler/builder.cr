require "./syntax/**"
require "../constants/constants.cr"

module Assembler
  include Constants

  class LoadTableEntry
    property offset : Int32
    property size : Int32
    property address : Int32

    def initialize(@offset, @size, @address)
    end
  end

  class Builder

    # Allows short-hand access to opcode values
    include_enum Opcode

    # Output to which the generated executable is written
    property output : IO::Memory

    # Maintains a mapping from labels to offsets in the
    # generated executable
    property offsets : Hash(String, Int32)

    # Maintains a mapping from offsets in the offset table
    # to unresolved labels
    # This allows you to use labels which are defined later on in
    # the file
    property unresolved_labels : Hash(Int32, {Int32, Label})

    # Maintains a mapping from labels to atomic values
    property aliases : Hash(String, Atomic)

    # The load table which gets embedded into the final executable
    #
    # Each table entry contains three 32-bit unsigned integers.
    property load_table : Array(LoadTableEntry)

    # Builds *source*
    def self.build(filename, source)
      builder = Builder.new

      begin
        builder.build filename, source
        builder.resolve_unresolved_labels
      rescue e : Exception
        yield e, Bytes.new(0), builder
      end

      yield nil, builder.encode_full, builder
    end

    def initialize
      @output = IO::Memory.new
      @offsets = {} of String => Int32
      @aliases = {} of String => Atomic
      @load_table = [] of LoadTableEntry
      @unresolved_labels = {} of Int32 => {Int32, Label}

      # Default load entry
      add_load_entry 0x00

      # Default size specifiers
      @aliases["byte"] = IntegerLiteral.new 1
      @aliases["word"] = IntegerLiteral.new 2
      @aliases["dword"] = IntegerLiteral.new 4
      @aliases["qword"] = IntegerLiteral.new 8
      @aliases["float"] = IntegerLiteral.new 8
      @aliases["bool"] = IntegerLiteral.new 1
      @aliases["opcode"] = IntegerLiteral.new 1
      @aliases["regcode"] = IntegerLiteral.new 1
      @aliases["address"] = IntegerLiteral.new 4
      @aliases["offset"] = IntegerLiteral.new 4

      # Default register names
      {% for name, code in Register.constants %}
        %reg = Register::{{name}}
        @aliases["{{name.downcase}}"] = IntegerLiteral.new %reg.dword
        @aliases["{{name.downcase}}q"] = IntegerLiteral.new %reg.qword
        @aliases["{{name.downcase}}d"] = IntegerLiteral.new %reg.dword
        @aliases["{{name.downcase}}w"] = IntegerLiteral.new %reg.word
        @aliases["{{name.downcase}}b"] = IntegerLiteral.new %reg.byte
      {% end %}

      # Register opcodes
      {% for name, code in Opcode.constants %}
        @aliases["{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}

      # Error codes
      {% for name, code in ErrorCode.constants %}
        @aliases["e_{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}

      # Syscalls
      {% for name, code in Syscall.constants %}
        @aliases["sys_{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}

      # Different flags for some values
      {% for name, code in Flag.constants %}
        @aliases["f_{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}

      # Several constants for the machine
      @aliases["memory_size"] = IntegerLiteral.new MEMORY_SIZE
      @aliases["stack_base"] = IntegerLiteral.new STACK_BASE
      @aliases["machine_internals_ptr"] = IntegerLiteral.new MACHINE_INTERNALS_PTR
      @aliases["machine_internals_size"] = IntegerLiteral.new MACHINE_INTERNALS_SIZE
      @aliases["interrupt_handler_address"] = IntegerLiteral.new INTERRUPT_HANDLER_ADDRESS
      @aliases["interrupt_memory"] = IntegerLiteral.new INTERRUPT_MEMORY
      @aliases["interrupt_memory_size"] = IntegerLiteral.new INTERRUPT_MEMORY_SIZE
      @aliases["interrupt_code"] = IntegerLiteral.new INTERRUPT_CODE
      @aliases["interrupt_status"] = IntegerLiteral.new INTERRUPT_STATUS
      @aliases["vram_address"] = IntegerLiteral.new VRAM_ADDRESS
      @aliases["vram_size"] = IntegerLiteral.new VRAM_SIZE
      @aliases["vram_width"] = IntegerLiteral.new VRAM_WIDTH
      @aliases["vram_height"] = IntegerLiteral.new VRAM_HEIGHT
    end

    def build(filename, source)
      tokens = Lexer.analyse filename, source
      tree = Parser.parse tokens

      tree.statements.each do |stat|
        case stat
        when Definition
          register_alias stat.name, stat.node
        when LabelDefinition
          register_label stat.label
        when Organize
          bytes = encode_value 4, stat.address
          address = get_casted_bytes UInt32, bytes
          add_load_entry address
        when Include
          include_filename = stat.path.value
          wd = File.dirname filename
          path = File.expand_path include_filename, wd

          unless File.exists?(path) && File.readable?(path)
            stat.raise "Could not open file #{include_filename}"
          end

          content = File.read path
          content = IO::Memory.new content
          build path, content
        when Constant
          register_label stat.name
          size = encode_size stat.size
          write_value size, stat.value
        when Instruction
          write_instruction stat
        end
      end
    end

    # Try to resolve all unresolved labels
    def resolve_unresolved_labels
      @unresolved_labels.each do |address, (size, label)|

        # Target area in which the value has to be filled in
        target = @output.to_slice[address, size]

        # Check offset table
        if @offsets.has_key? label.value
          offset = @offsets[label.value]
          bytes = get_bytes offset
          target.copy_from get_trimmed_bytes size, bytes
          next
        end

        # Check alias table
        if @aliases.has_key? label.value
          node = @aliases[label.value]
          bytes = encode_value size, node
          target.copy_from get_trimmed_bytes size, bytes
          next
        end

        # The label could not be resolved
        label.raise "Unknown label #{label.value}"
      end
    end

    # Returns the amount of bytes *size* represents
    def encode_size(size : Atomic)
      case size
      when IntegerLiteral
        return size.value.to_i32
      when FloatLiteral
        size.raise "Can't use float literal as size specifier"
      when StringLiteral
        size.raise "Can't use string literal as size specifier"
      when Label

        # Check if this label is a valid alias to something
        if @aliases.has_key? size.value
          node = @aliases[size.value]
          return encode_size node
        end

        if @offsets.has_key? size.value
          size.raise "Expected label to be a definition"
        else
          size.raise "Unknown label #{size.value}"
        end
      else
        size.raise "Bug: Unknwon node type #{size.class}"
      end
    end

    # Encodes *value* into *size* bytes
    def encode_value(size, value : Atomic)
      case value
      when IntegerLiteral
        bytes = get_bytes value.value
        return get_trimmed_bytes size, bytes
      when FloatLiteral
        bytes = get_bytes value.value
        return get_trimmed_bytes size, bytes
      when StringLiteral
        return get_trimmed_bytes size, value.value.to_slice
      when Label

        # Check both the offset table and the alias table
        if @offsets.has_key? value.value
          offset = @offsets[value.value]
          bytes = get_bytes offset
          return get_trimmed_bytes size, bytes
        end

        if @aliases.has_key? value.value
          node = @aliases[value.value]
          return encode_value size, node
        end

        value.raise "Unknown label #{value.value}"
      else
        value.raise "Bug: Unknown node type #{value.class}"
      end
    end

    # Write *value* into the output stream, with a max size to *size*
    def write_value(size, value : Atomic)
      case value
      when IntegerLiteral
        bytes = get_bytes value.value
        write get_trimmed_bytes size, bytes
      when FloatLiteral
        bytes = get_bytes value.value
        write get_trimmed_bytes size, bytes
      when StringLiteral
        write get_trimmed_bytes size, value.value.to_slice
      when Label

        # Check both the offset table and the alias table
        if @offsets.has_key? value.value
          offset = @offsets[value.value]
          bytes = get_bytes offset
          write get_trimmed_bytes size, bytes
          return
        end

        if @aliases.has_key? value.value
          node = @aliases[value.value]
          return write_value size, node
        end

        # The label wasn't encountered before, so we add it to the
        # unresolved labels table.
        #
        # We also reserve enough bytes for the value
        # so another subroutine can later fill in the correct value
        @unresolved_labels[@output.pos] = {size, value}
        write Bytes.new(size)
      else
        value.raise "Bug: Unknown node type #{value.class}"
      end
    end

    # :nodoc:
    private macro check_args(bytecounts = [] of Int32)
      assert_count instruction, {{bytecounts.size}}

      {% for size, index in bytecounts %}
        write_value {{size}}, instruction.arguments[{{index}}]
      {% end %}
    end

    # :nodoc:
    private def assert_count(instruction, count)
      name = instruction.name
      arg_count = instruction.arguments.size
      instruction.raise "#{name} expected #{count} arguments, got #{arg_count}" if arg_count != count
    end

    # Encodes an instruction node
    def write_instruction(instruction : Instruction)
      opcode = instruction.name.value
      opcode = Opcode.parse opcode

      # Write the opcode to the instruction stream
      write Bytes.new 1 { opcode.value }

      # Validate and write all instruction arguments
      case opcode
      when RPUSH                                then check_args [1]
      when RPOP                                 then check_args [1]
      when MOV                                  then check_args [1, 1]
      when RST                                  then check_args [1]
      when ADD, SUB, MUL, DIV, IDIV, REM, IREM  then check_args [1, 1, 1]
      when FADD, FSUB, FMUL, FDIV, FREM, FEXP   then check_args [1, 1, 1]
      when FLT, FGT                             then check_args [1, 1]
      when CMP, LT, GT, ULT, UGT                then check_args [1, 1]
      when SHR, SHL, AND, XOR, OR               then check_args [1, 1, 1]
      when NOT                                  then check_args [1, 1]
      when INTTOFP, SINTTOFP, FPTOINT           then check_args [1, 1]
      when LOAD                                 then check_args [1, 4]
      when LOADR                                then check_args [1, 1]
      when LOADS                                then check_args [4, 4]
      when LOADSR                               then check_args [4, 1]
      when STORE                                then check_args [4, 1]
      when READ                                 then check_args [1, 1]
      when READC                                then check_args [1, 4]
      when READS                                then check_args [4, 1]
      when READCS                               then check_args [4, 4]
      when WRITE                                then check_args [1, 1]
      when WRITEC                               then check_args [4, 1]
      when WRITES                               then check_args [1, 4]
      when WRITECS                              then check_args [4, 4]
      when COPY                                 then check_args [1, 4, 1]
      when COPYC                                then check_args [4, 4, 4]
      when JZ                                   then check_args [4]
      when JZR                                  then check_args [1]
      when JMP                                  then check_args [4]
      when JMPR                                 then check_args [1]
      when CALL                                 then check_args [4]
      when CALLR                                then check_args [1]
      when RET                                  then check_args
      when NOP                                  then check_args
      when SYSCALL                              then check_args
      when PUSH
        assert_count instruction, 2

        size = instruction.arguments[0]
        value = instruction.arguments[1]

        size_bytes = encode_size size
        write_value 4, size
        write_value size_bytes, value
      when LOADI
        assert_count instruction, 2

        reg_arg = instruction.arguments[0]

        reg_bytes = encode_value 1, reg_arg
        reg = Register.new get_casted_bytes UInt8, reg_bytes

        write_value 1, reg_arg
        write_value reg.bytecount, instruction.arguments[1]
      end
    end

    # :nodoc:
    def get_bytes(data : T) forall T
      slice = Slice(T).new 1, data
      pointer = Pointer(UInt8).new slice.to_unsafe.address
      size = sizeof(T)
      bytes = Bytes.new pointer, size
      bytes
    end

    # Trims or zero-extends *bytes* to *size*
    def get_trimmed_bytes(size, bytes : Bytes)
      if size > bytes.size
        encoded = Bytes.new size
        encoded.copy_from bytes
        return encoded
      end

      return bytes[0, size]
    end

    # Return a *T* value created from *source*
    def get_casted_bytes(x : T.class, source : Bytes) forall T
      bytes = get_trimmed_bytes sizeof(T), source
      ptr = Pointer(T).new bytes.to_unsafe.address
      ptr[0]
    end

    # Registers a new label in the offset table
    def register_label(label : Label)
      if @offsets.has_key?(label.value) || @aliases.has_key?(label.value)
        label.raise "Can't redefine #{label.value}"
      end

      # Get the current load entry
      entry = @load_table[-1]
      @offsets[label.value] = entry.address + entry.size
    end

    # Register a new alias
    def register_alias(label : Label, node : Atomic)
      if @offsets.has_key?(label.value) || @aliases.has_key?(label.value)
        label.raise "Can't redefine #{label.value}"
      end

      @aliases[label.value] = node
    end

    # Add a new entry to the load table
    def add_load_entry(address)
      @load_table << LoadTableEntry.new @output.pos, 0, address.to_i32
    end

    # Grows the size of the last load entry by *size*
    def grow_load_entry_size(size)
      if @load_table.size > 0
        last_offset = @load_table[-1].offset
        @load_table[-1].size = @output.pos - last_offset
      end
    end

    # Write bytes into the output
    def write(bytes : Bytes)
      @output.write bytes
      grow_load_entry_size bytes.size
    end

    # Encode the header section of the program
    def encode_header
      #                 +- Magic numbers
      #                 |   +- Entry address
      #                 |   |   +- Load table size
      #                 |   |   |   +- Reserve enough space for all entries
      #                 v   v   v   v
      header = Slice(Int32).new 1 + 1 + 1 + (@load_table.size * 3)
      header[0] = 0x4543494e # bytes are reversed because of endianness
      header[1] = @offsets["entry_addr"]? || 0
      header[2] = @load_table.size
      @load_table.each_with_index do |entry, index|
        header[3 + (index * 3) + 0] = entry.offset
        header[3 + (index * 3) + 1] = entry.size
        header[3 + (index * 3) + 2] = entry.address
      end

      ptr = Pointer(UInt8).new header.to_unsafe.address
      Bytes.new ptr, header.bytesize
    end

    # Encodes the full executable
    def encode_full
      header = encode_header
      body = @output.to_slice
      executable = Bytes.new header.size + body.size
      header.copy_to executable
      body.copy_to executable + header.size
      executable
    end
  end

end
