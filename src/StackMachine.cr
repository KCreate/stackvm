require "./StackMachine/*"

module StackMachine
  include OP
  include Reg

  STDOUT.sync = true
  STDIN.sync = true
  STDERR.sync = true

  # read in a program from the filesystem
  if ARGV.size < 1
    puts "Missing filename"
    exit 1
  end

  filename = ARGV[0]
  content = File.read filename
  data = [] of Int32
  content.bytes.each do |byte|
    data << byte.to_i32
  end

  vm = VM.new
  program = Program.new data

  vm.init(memory_size: 64) # 64 Int32 values
  vm.run program
  exit_code = vm.regs[EXT]
  puts "Exited with #{exit_code}"
  vm.clean
  exit exit_code

end
