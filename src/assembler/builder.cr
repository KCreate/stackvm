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

    # Maintains a mapping from labels to atomic values
    property aliases : Hash(String, Atomic)

    # The load table which gets embedded into the final executable
    #
    # Each table entry contains three 32-bit unsigned integers.
    # 0 - Offset in the executable
    # 1 - Length of the segment
    # 2 - Address to which it should be loaded in memory
    property load_table : Array(LoadTableEntry)

    # Builds *source*
    def self.build(filename, source)
      builder = Builder.new

      begin
        builder.build filename, source
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

      # Default load entry
      add_load_entry 0x00

      # Default size specifiers
      @aliases["byte"] = IntegerLiteral.new 1
      @aliases["word"] = IntegerLiteral.new 2
      @aliases["dword"] = IntegerLiteral.new 4
      @aliases["qword"] = IntegerLiteral.new 8
      @aliases["float32"] = IntegerLiteral.new 4
      @aliases["float64"] = IntegerLiteral.new 8
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
        @aliases["{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}

      # Syscalls
      {% for name, code in Syscall.constants %}
        @aliases["{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}

      # Different flags for some values
      {% for name, code in Flag.constants %}
        @aliases["f_{{name.downcase}}"] = IntegerLiteral.new {{code}}
      {% end %}
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
          value = encode_value size, stat.value
          write value
        when Instruction
          write_instruction stat
        end
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

        size.raise "Expected label to be a definition"
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
        if size == 4
          value = value.value.to_i32
        else
          value = value.value
        end

        bytes = get_bytes value
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

        value.raise "Bug: Unknown label #{value.value}"
      else
        value.raise "Bug: Unknown node type #{value.class}"
      end
    end

    # :nodoc:
    private macro check_args(bytecounts = [] of Int32)
      assert_count instruction, {{bytecounts.size}}

      {% for size, index in bytecounts %}
        write encode_value {{size}}, instruction.arguments[{{index}}]
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
      when RPUSH    then check_args [1]
      when RPOP     then check_args [1]
      when MOV      then check_args [1, 1]
      when RST      then check_args [1]
      when ADD, SUB, MUL, DIV, IDIV, REM, IREM  then check_args [1, 1, 1]
      when FADD, FSUB, FMUL, FDIV, FREM, FEXP   then check_args [1, 1, 1]
      when CMP, LT, GT, ULT, UGT                then check_args [1, 1, 1]
      when SHR, SHL, AND, XOR, NAND, OR         then check_args [1, 1, 1]
      when NOT      then check_args [1, 1]
      when LOAD     then check_args [1, 4]
      when LOADR    then check_args [1, 1]
      when LOADS    then check_args [4, 4]
      when LOADSR   then check_args [4, 1]
      when STORE    then check_args [4, 1]
      when READ     then check_args [1, 1]
      when READC    then check_args [1, 4]
      when READS    then check_args [4, 1]
      when READCS   then check_args [4, 4]
      when WRITE    then check_args [1, 1]
      when WRITEC   then check_args [4, 1]
      when WRITES   then check_args [1, 4]
      when WRITECS  then check_args [4, 4]
      when COPY     then check_args [1, 4, 1]
      when COPYC    then check_args [4, 4, 4]
      when JZ       then check_args [4]
      when JZR      then check_args [1]
      when JMP      then check_args [4]
      when JMPR     then check_args [1]
      when CALL     then check_args [4]
      when CALLR    then check_args [1]
      when RET      then check_args
      when NOP      then check_args
      when SYSCALL  then check_args
      when PUSH
        assert_count instruction, 2

        size = instruction.arguments[0]
        value = instruction.arguments[1]

        size_bytes = encode_size size
        value_bytes = encode_value size_bytes, value

        write encode_value 4, size
        write value_bytes
      when LOADI
        assert_count instruction, 2

        reg_bytes = encode_value 1, instruction.arguments[0]
        reg = Register.new get_casted_bytes UInt8, reg_bytes
        value = encode_value reg.bytecount, instruction.arguments[1]

        write reg_bytes
        write value
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
