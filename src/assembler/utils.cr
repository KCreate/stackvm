module Assembler::Utils
  extend self

  # Encodable values
  alias InstructionLiterals = Array(UInt8 | UInt16 | UInt32 | UInt64 | Float32 | Float64 | String)

  # Converts an array of 8 - 64 bit numbers to a UInt8 slice
  def convert_opcodes(data : InstructionLiterals)
    bc = 0 # byte offset counter
    binary = Slice(UInt8).new data.size * 8

    data.each do |num|
      case num
      when .is_a? UInt8
        binary[bc] = num
        bc += 1
      when .is_a? UInt16
        val = Slice(UInt16).new 1, num
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 1 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 2
      when .is_a? UInt32
        val = Slice(UInt32).new 1, num
        bytes = Pointer(UInt8).new val.to_unsafe.address

        0.upto 3 do |i|
          binary[bc + i] = bytes[i]
        end

        bc += 4
      when .is_a? UInt64
        val = Slice(UInt64).new 1, num
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
      end
    end

    # Trim off unneeded bytes
    binary = binary.to_unsafe.realloc bc
    binary = binary.to_slice bc
    binary
  end

end
