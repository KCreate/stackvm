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

    # The address which is written into the *entry_addr* field
    # of the executables header section
    property entry_adr : Int32

    # Builds *source*
    def self.build(filename, source)
      builder = Builder.new

      begin
        tokens = Lexer.analyse filename, source
        tree = Parser.parse tokens

        # Encode all statements in the module
        tree.statements.each do |stat|
          case stat
          when Definition
            builder.register_alias stat.name, stat.node
          when LabelDefinition
            builder.register_label stat.label
          when Constant
            builder.register_label stat.name
            size = builder.encode_size stat.size
            value = builder.encode_value size, stat.value
            builder.write value
          end
        end
      rescue e : Exception
        yield e, Bytes.new 0
      end

      yield nil, builder.encode_full
    end

    def initialize
      @output = IO::Memory.new
      @offsets = {} of String => Int32
      @aliases = {} of String => Atomic
      @load_table = [] of LoadTableEntry
      @entry_adr = -1

      # Default load entry
      add_load_entry 0x00
    end

    # Returns the amount of bytes *size* represents
    def encode_size(size : Atomic)
      case size
      when IntegerLiteral
        return size.value.to_u32
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
    def encode_value(size : UInt32, value : Atomic)
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
    private def get_bytes(data : T) forall T
      slice = Slice(T).new 1, data
      pointer = Pointer(UInt8).new slice.to_unsafe.address
      size = sizeof(T)
      bytes = Bytes.new pointer, size
      bytes
    end

    # Trims or zero-extends *bytes* to *size*
    private def get_trimmed_bytes(size : UInt32, bytes : Bytes)
      if size > bytes.size
        encoded = Bytes.new size
        encoded.copy_from bytes
        return encoded
      end

      return bytes[0, size]
    end

    # Registers a new label in the offset table
    def register_label(label : Label)
      if @offsets.has_key?(label) || @aliases.has_key?(label)
        label.raise "Can't redefine #{label.value}"
      end

      # Get the current load entry
      entry = @load_table[-1]
      offset = entry.offset + entry.size
      @offsets[label.value] = offset
    end

    # Register a new alias
    def register_alias(label : Label, node : Atomic)
      if @offsets.has_key?(label) || @aliases.has_key?(label)
        label.raise "Can't redefine #{label.value}"
      end

      @aliases[label.value] = node
    end

    # Add a new entry to the load table
    def add_load_entry(address)
      @load_table << LoadTableEntry.new @output.pos, 0, address
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
