require "./syntax/**"
require "../constants/constants.cr"

module Assembler
  include Constants

  alias LoadTableEntry = NamedTuple(offset: Int32, size: Int32, address: Int32)

  class Builder

    # Output to which the generated executable is written
    property output : IO::Memory

    # Maintains a mapping from labels to offsets in the
    # generated executable
    property offsets : Hash(String, Int32)

    # Maintains a mapping from labels to ast nodes
    property aliases : Hash(String, ASTNode)

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
      tokens = Lexer.analyse filename, source
      tree = Parser.parse tokens

      puts tree

      yield nil, Bytes.new 0
    end

    def initialize
      @output = IO::Memory.new
      @offsets = {} of String => Int32
      @aliases = {} of String => ASTNode
      @load_table = [] of LoadTableEntry
      @entry_adr = -1

      # Default load entry
      add_load_entry 0x00
    end

    # Registers a new label in the offset table
    def register_label(label : Label)
      if @offsets.has_key?(label) || @aliases.has_key?(label)
        label.raise "Can't redefine #{label.value}"
      end

      @offsets[label.value] = @output.pos
    end

    # Register a new alias
    def register_alias(label : Label, node : ASTNode)
      if @offsets.has_key?(label) || @aliases.has_key?(label)
        label.raise "Can't redefine #{label.value}"
      end

      @aliases[label.value] = node
    end

    # Add a new entry to the load table
    def add_load_entry(address)
      @load_table << {offset: @output.pos, size: 0, address: address}
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
      executable = Bytes.new @output.size + header.bytesize
      header.copy_to executable
      @output.to_slice.copy_to executable[header_bytes.size, -1]
      executable
    end
  end

end
