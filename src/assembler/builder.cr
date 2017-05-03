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
    # to unresolved expressions
    # This allows you to use labels which are defined later on in
    # the file
    property unresolved_expressions : Hash(Int32, {Int32, Atomic})

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
        builder.resolve_unresolved_expressions
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
      @unresolved_expressions = {} of Int32 => {Int32, Atomic}

      add_load_entry 0x00

      # Default size specifiers
      @aliases["byte"] = IntegerLiteral.new 1
      @aliases["word"] = IntegerLiteral.new 2
      @aliases["dword"] = IntegerLiteral.new 4
      @aliases["qword"] = IntegerLiteral.new 8
      @aliases["float"] = IntegerLiteral.new 8
      @aliases["bool"] = IntegerLiteral.new 1
      @aliases["t_opcode"] = IntegerLiteral.new 1
      @aliases["t_register"] = IntegerLiteral.new 1
      @aliases["t_address"] = IntegerLiteral.new 4
      @aliases["t_offset"] = IntegerLiteral.new 4
      @aliases["t_size"] = IntegerLiteral.new 4
      @aliases["t_syscall"] = IntegerLiteral.new 2

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
      @aliases["interrupt_keyboard"] = IntegerLiteral.new VRAM_HEIGHT
      @aliases["interrupt_keyboard_sym"] = IntegerLiteral.new INTERRUPT_KEYBOARD_SYM
      @aliases["interrupt_keyboard_mod"] = IntegerLiteral.new INTERRUPT_KEYBOARD_MOD
      @aliases["interrupt_keyboard_keydown"] = IntegerLiteral.new INTERRUPT_KEYBOARD_KEYDOWN
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
          value = resolve_expression stat.address
          case value
          when Int64
            add_load_entry value
          when Float64
            stat.raise "Address resolved to a float, only integers are allowed"
          when String
            stat.raise "Address resolved to a string, only integers are allowed"
          end
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
          size = resolve_expression stat.size

          unless size.is_a? Int64
            stat.size.raise "Expression resolved to a #{size.class}, expected an integer"
          end

          register_label stat.name
          add_unresolved_expression size.to_i32, stat.value
          write Bytes.new(size: size)
        when Instruction
          write_instruction stat
        end
      end
    end

    # Tries to resolve all unresolved expressions
    def resolve_unresolved_expressions
      @unresolved_expressions.each do |offset, (size, node)|
        target = @output.to_slice[offset, size]
        value = resolve_expression node
        bytes = encode_to_bytes value
        trimmed = trim_bytes size, bytes
        target.copy_from trimmed
      end
    end

    # Adds an entry to the unresolved expressions table
    def add_unresolved_expression(size, node)
      @unresolved_expressions[@output.pos] = {size, node}
    end

    # Resolves an expression to either an Int64, Float64 or a String
    def resolve_expression(node : Atomic)
      case node
      when BinaryExpression
        left = resolve_expression node.left
        right = resolve_expression node.right
        operator = node.operator

        if left.is_a?(String) && right.is_a?(String)
          case operator
          when :plus
            return left + right
          else
            node.raise "Unexpected operator #{node.operator}"
          end
        end

        if left.is_a?(Int64) && right.is_a?(Int64)
          case operator
          when :plus
            return left + right
          when :minus
            return left - right
          when :mul
            return left * right
          when :div
            return left / right
          else
            node.raise "Unexpected operator #{node.operator}"
          end
        end

        if left.is_a?(Float64) && right.is_a?(Float64)
          case operator
          when :plus
            return left + right
          when :minus
            return left - right
          when :mul
            return left * right
          when :div
            return left / right
          else
            node.raise "Unexpected operator #{node.operator}"
          end
        end

        node.raise "Can't perform #{left.class} #{operator} #{right.class}"
      when UnaryExpression
        value = resolve_expression node.expression

        case value
        when Int64
          case operator = node.operator
          when :plus
            return value.abs
          when :minus
            return -(value)
          else
            node.raise "Unexpected operator: #{operator}"
          end
        when Float64
          case operator = node.operator
          when :plus
            return value.abs
          when :minus
            return -(value)
          else
            node.raise "Unexpected operator: #{operator}"
          end
        when String
          node.raise "Can't perform unary operation on string"
        else
          node.raise "Could not resolve node into valid type, got #{value.class}"
        end
      when Label
        if @offsets.has_key? node.value
          return @offsets[node.value].to_i64
        end

        if @aliases.has_key? node.value
          return resolve_expression @aliases[node.value]
        end

        node.raise "Undefined label #{node.value}"
      when StringLiteral
        return node.value
      when IntegerLiteral
        return node.value
      when FloatLiteral
        return node.value
      else
        node.raise "Unknown node type #{node.class}"
      end
    end

    # :nodoc:
    private def assert_count(node, count)
      name = node.name
      arg_count = node.arguments.size
      node.raise "#{name} expected #{count} arguments, got #{arg_count}" if arg_count != count
    end

    # :nodoc:
    private macro write_args(bytecounts = [] of Int32)
      assert_count node, {{bytecounts.size}}

      {% for size, index in bytecounts %}
        add_unresolved_expression {{size}}, node.arguments[{{index}}]
        write Bytes.new {{size}}
      {% end %}
    end

    # Reserves space for instruction arguments
    def write_instruction(node)
      opcode = resolve_expression node.name

      case opcode
      when Int64
        bytes = to_bytes opcode
        trimmed = trim_bytes 1, bytes
        write trimmed
      else
        node.name.raise "Expected mnemonic to resolve to an integer, got #{opcode.class}"
      end

      opcode = Opcode.new opcode.to_u8

      case opcode
      when RPUSH                               then write_args [1]
      when RPOP                                then write_args [1]
      when MOV                                 then write_args [1, 1]
      when RST                                 then write_args [1]
      when ADD, SUB, MUL, DIV, IDIV, REM, IREM then write_args [1, 1]
      when FADD, FSUB, FMUL, FDIV, FREM, FEXP  then write_args [1, 1]
      when FLT, FGT                            then write_args [1, 1]
      when CMP, LT, GT, ULT, UGT               then write_args [1, 1]
      when SHR, SHL, AND, XOR, OR              then write_args [1, 1]
      when NOT                                 then write_args [1]
      when INTTOFP, SINTTOFP, FPTOINT          then write_args [1]
      when LOAD                                then write_args [1, 4]
      when LOADR                               then write_args [1, 1]
      when LOADS                               then write_args [4, 4]
      when LOADSR                              then write_args [4, 1]
      when STORE                               then write_args [4, 1]
      when READ                                then write_args [1, 1]
      when READC                               then write_args [1, 4]
      when READS                               then write_args [4, 1]
      when READCS                              then write_args [4, 4]
      when WRITE                               then write_args [1, 1]
      when WRITEC                              then write_args [4, 1]
      when WRITES                              then write_args [1, 4]
      when WRITECS                             then write_args [4, 4]
      when COPY                                then write_args [1, 4, 1]
      when COPYC                               then write_args [4, 4, 4]
      when JZ                                  then write_args [4]
      when JZR                                 then write_args [1]
      when JMP                                 then write_args [4]
      when JMPR                                then write_args [1]
      when CALL                                then write_args [4]
      when CALLR                               then write_args [1]
      when RET                                 then write_args
      when NOP                                 then write_args
      when SYSCALL                             then write_args
      when PUSH
        assert_count node, 2

        size = resolve_expression node.arguments[0]

        case size
        when Int64
          size_bytes = to_bytes size
          trimmed = trim_bytes 4, size_bytes
          write trimmed
          add_unresolved_expression size.to_i32, node.arguments[1]
          write Bytes.new size
        else
          node.arguments[0].raise "Expected expression to resolve to an integer, got #{size.class}"
        end
      when LOADI
        assert_count node, 2

        reg_expression = resolve_expression node.arguments[0]

        case reg_expression
        when Int64
          reg = Register.new reg_expression.to_u8
          write Bytes.new 1 { reg_expression.to_u8 }
          add_unresolved_expression reg.bytecount, node.arguments[1]
          write Bytes.new reg.bytecount
        else
          node.arguments[0].raise "Expected expression to resolve to an integer, got #{reg_expression.class}"
        end
      end
    end

    # :nodoc:
    def to_bytes(data : T) forall T
      {% if T.union? %}
        {% for typ in T.union_types %}
          if data.is_a?({{typ}})
            slice = Slice({{typ}}).new 1, data
            ptr = slice.to_unsafe.as(UInt8*)
            size = sizeof({{typ}})
            bytes = Bytes.new ptr, size
            return bytes
          end
        {% end %}

        # This should never happen, it's just here to make
        # the compiler happy
        return Bytes.new 0
      {% else %}
        slice = Slice(T).new 1, data
        ptr = slice.to_unsafe.as(UInt8*)
        size = sizeof(T)
        bytes = Bytes.new ptr, size
        return bytes
      {% end %}
    end

    def encode_to_bytes(data : T) forall T
      case data
      when String
        return data.to_slice
      else
        return to_bytes data
      end
    end

    # Trims or zero-extends *bytes* to *size*
    def trim_bytes(size, bytes : Bytes)
      if size > bytes.size
        encoded = Bytes.new size
        encoded.copy_from bytes
        return encoded
      end

      return bytes[0, size]
    end

    # Return a *T* value created from *source*
    def cast_bytes(x : T.class, source : Bytes) forall T
      bytes = get_trimmed_bytes sizeof(T), source
      ptr = Pointer(T).new bytes.to_unsafe.address
      ptr[0]
    end

    # Registers a new label in the offset table
    def register_label(label : Label)
      if @offsets.has_key?(label.value) || @aliases.has_key?(label.value)
        label.raise "Can't redefine #{label.value}"
      end

      if @load_table.size == 0
        @offsets[label.value] = @output.pos
        return
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

    # Write bytes into the output
    def write(bytes : Bytes)
      @output.write bytes

      if @load_table.size > 0
        last_offset = @load_table[-1].offset
        @load_table[-1].size = @output.pos - last_offset
      end
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
