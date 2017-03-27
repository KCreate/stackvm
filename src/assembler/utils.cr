module Assembler::Utils
  extend self

  # Converts an array of 8 - 64 bit numbers to a UInt8 slice
  def convert_opcodes(data : Array(UInt8 | UInt16 | UInt32 | UInt64))
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
      end
    end

    binary
  end

end
