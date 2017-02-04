require "./machine/*"
require "./assembler/assembler.cr"
require "./bc/*"

module StackMachine

  module CLI
    include OP
    include Reg

    HELP = <<-HELP
    Usage: vm [command] [filename]

    Available commands:
    - run       Runs [filename]
    - asm       Writes the assembled binary into STDOUT
    - help      Shows this help page

    HELP

    # Handles CLI input
    def self.handle(arguments = ARGV)
      if arguments.size == 0
        return puts HELP
      end

      command = arguments.shift

      case command
      when "run"
        if arguments.size == 0
          puts "Missing filename"
          return puts HELP
        end

        return run arguments.shift
      when "asm"
        if arguments.size == 0
          puts "Missing filename"
          return puts HELP
        end

        return assemble arguments.shift
      else
        return puts HELP
      end
    end

    def self.run(filename : String)
      opcodes = BC::Reader.read filename
      program = Program.new opcodes

      vm = VM.new
      vm.init
      exit_code = vm.run program
      vm.clean
      exit exit_code
    end

    def self.assemble(filename : String)
      source = File.read filename
      bytecode = Assembler::Assembler.new.build source
      bytecode.each do |code|
        p1 = Pointer(Int32).malloc 1
        p1.value = code
        bytes = Pointer(UInt8).new p1.address
        bytes = Slice.new bytes, 4
        bytes.reverse!

        STDOUT.write bytes
      end
    end

  end

end
