module Assembler::Utils
  extend self

  # Encodable values
  alias InstructionLiterals = (
    UInt8 | Int8 |
    UInt16 | Int16 |
    UInt32 | Int32 |
    UInt64 | Int64 |
    Float32 | Float64 |
    Bool | String)
  alias EXE = Array(InstructionLiterals)

  # Encodes Crystal primitive values
  def convert_opcodes(data : EXE)
    bc = 0 # byte offset counter
    binary = Slice(UInt8).new data.size * 8

    data.each do |num|
      case num
      when .is_a?(UInt8), .is_a?(Int8)
        binary[bc] = num.to_u8
        bc += 1
      when .is_a?(UInt16), .is_a?(Int16)
        val = Slice(UInt16).new 1, num.to_u16
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 1 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 2
      when .is_a?(UInt32), .is_a?(Int32)
        val = Slice(UInt32).new 1, num.to_u32
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 3 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 4
      when .is_a?(UInt64), .is_a?(Int64)
        val = Slice(UInt64).new 1, num.to_u64
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 7 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 8
      when .is_a? Float32
        val = Slice(Float32).new 1, num
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 3 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 4
      when .is_a? Float64
        val = Slice(Float64).new 1, num
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 7 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 8
      when .is_a? String
        bytes = num.to_slice

        0.upto bytes.size - 1 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += bytes.size
      when .is_a? Bool
        binary[bc] = num ? 1_u8 : 0_u8
        bc += 1
      else
        puts "Skipped #{num.class}"
      end
    end

    # Trim off unneeded bytes
    binary = binary.to_unsafe.realloc bc
    binary = binary.to_slice bc
    binary
  end

end
