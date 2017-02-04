module StackMachine::BC

  # Consumes a bc file and converts it to an Array(Int32)
  class Reader

    # returns an Array(Int32) containing opcodes from a given file
    def self.read(filename : String)
      opcodes = [] of Int32
      File.open(filename) do |file|
        while file.pos < file.size
          opcodes << file.read_bytes(Int32, IO::ByteFormat::BigEndian)
        end
      end
      opcodes
    end

  end

end
