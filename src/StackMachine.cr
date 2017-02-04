require "./StackMachine/machine/*"
require "./StackMachine/bc/*"
require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  # Collect opcodes from a file
  opcodes = BC::Reader.read ARGV[0]?.not_nil!
  program = Program.new opcodes

  # Run the file
  vm = VM.new
  vm.init
  vm.run program
  vm.clean
end
