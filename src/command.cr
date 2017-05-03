require "colorize"
require "option_parser"

require "./assembler/builder.cr"
require "./machine/vm.cr"
require "./machine/debugger.cr"
require "./monitor.cr"
require "./constants/constants.cr"

module StackVM
  include Assembler

  # Command-line interface to the assembler
  class Command
    def initialize(arguments : Array(String))
      if arguments.size == 0
        help
        return
      end

      case command = arguments.shift
      when "run"     then run arguments
      when "build"   then build arguments
      when "monitor" then monitor arguments
      when "help"    then help
      when "version" then version
      else
        error "unknown command: #{command}"
      end
    end

    # Runs an executable
    def run(arguments : Array(String))
      filename = ""
      debug_mode = false

      should_run = true
      OptionParser.parse arguments do |parser|
        parser.banner = "Usage: run filename [switches]"
        parser.on "-h", "--help", "show help" { puts parser; should_run = false }
        parser.on "-d", "--debugger", "enable debugger" { debug_mode = true }
        parser.invalid_option { |opt| error "unknown option: #{opt}"; should_run = false }
        parser.unknown_args do |args|
          filename = args.shift? || ""
          if args.size > 0
            error "unknown arguments: #{args.join ", "}"
            should_run = false
          end
        end
      end

      return unless should_run

      # Make sure we were given a file
      if filename == ""
        return error "missing filename"
      end

      # Check that the file exists and is readable
      unless File.readable?(filename) && File.file?(filename)
        return error "could not open #{filename}"
      end

      size = File.size filename
      bytes = Bytes.new size
      File.open filename do |io|
        io.read_fully bytes
      end

      machine = VM::Machine.new
      machine.flash bytes

      if debug_mode
        dbg = VM::Debugger.new machine
        dbg.start
      else
        machine.start
        machine.clean
      end
    end

    # Runs the build command
    def build(arguments : Array(String))
      filename = ""
      output = "out.bc"
      stats = false

      should_run = true
      OptionParser.parse arguments do |parser|
        parser.banner = "Usage: build filename [switches]"
        parser.on "-o PATH", "--out=PATH", "set name of output file" { |name| output = name }
        parser.on "-h", "--help", "show help" { puts parser; should_run = false }
        parser.on "-s", "--stats", "show stats" { stats = true }
        parser.invalid_option { |opt| error("unknown option: #{opt}"); should_run = false }
        parser.unknown_args do |args|
          filename = args.shift? || ""
          if args.size > 0
            error "unknown arguments: #{args.join ", "}"
            should_run = false
          end
        end
      end

      unless should_run
        return
      end

      if filename == ""
        error "missing filename"
        return
      end

      unless File.readable?(filename) && File.file?(filename)
        error "could not open #{filename}"
        return
      end

      path = File.expand_path filename
      content = File.read filename
      content = IO::Memory.new content

      Builder.build path, content do |err, result, builder|
        if err
          error err
          return
        end

        if stats
          success "Built", "#{output} #{result.size} bytes"

          entry_addr = builder.offsets["entry_addr"]? || 0
          success "Entry Address", render_hex entry_addr, 8, :yellow
          success "Offset Table", "#{builder.offsets.size} entries"

          offsets = {} of Int32 => Array(String)
          builder.offsets.each do |key, value|
            (offsets[value] ||= [] of String) << key
          end

          offsets.each_key.to_a.sort.each do |key|
            labels = offsets[key]
            offset = render_hex key, 8, :yellow
            puts "  #{offset}: #{labels.join ", "}"
          end

          puts "\n"

          success "Load Table", "#{builder.load_table.size} entries"

          puts "  Offset      Size        Address"
          builder.load_table.each do |entry|
            offset = render_hex entry.offset, 8, :yellow
            size = render_hex entry.size, 8, :yellow
            address = render_hex entry.address, 8, :yellow

            puts "  #{offset}  #{size}  #{address}"
          end

          overlapping_segments = [] of {LoadTableEntry, LoadTableEntry}
          segments = [] of LoadTableEntry
          builder.load_table.each do |entry|
            adr_start = entry.address
            adr_end = adr_start + entry.size

            segments.each do |segment|
              seg_start = segment.address
              seg_end = seg_start + segment.size
              if adr_end > seg_start && adr_start < seg_end
                overlapping_segments << {entry, segment}
              end
            end

            segments << entry
          end

          if overlapping_segments.size > 0
            puts "\n"
            warning "There are overlapping segments!"

            overlapping_segments.each do |(left, right)|
              left_start = left.address
              left_end = left_start + left.size

              right_start = right.address
              right_end = right_start + right.size

              left_start = render_hex left_start, 8, :yellow
              left_end = render_hex left_end, 8, :yellow
              right_start = render_hex right_start, 8, :yellow
              right_end = render_hex right_end, 8, :yellow

              warning <<-TEXT
              Overlap:
                Lower Segment:
                Start: #{left_start}
                End:   #{left_end}
                Labels: #{offsets[left.address]?.try &.join ", "}

                Upper Segment:
                Start: #{right_start}
                End:   #{right_end}
                Labels: #{offsets[right.address]?.try &.join ", "}
              TEXT
            end
          end
        end

        bytes = result.to_slice

        File.open output, "w" do |fd|
          fd.write bytes
        end
      end
    end

    # Start the virtual monitor
    def monitor(arguments : Array(String))
      filename = ""
      scaling = 2

      parser = OptionParser.parse(arguments) do |parser|
        parser.banner = "Usage: monitor filename [switches]"
        parser.on("-s FACTOR", "--scale=FACTOR", "set scaling factor") { |factor|
          scaling = factor.to_i32
        }
        parser.unknown_args do |args|
          arg = args.shift?

          unless arg
            error "missing filename"
            puts parser
            exit 1
          end

          filename = arg
        end
      end

      if filename == ""
        error "missing filename"
        puts parser
        exit 1
      end

      unless File.exists?(filename) && File.readable?(filename)
        error "Can't open file #{filename}"
        puts parser
        exit 1
      end

      file = File.open filename, "r+"

      unless file.size == Constants::MEMORY_SIZE
        error "Input file needs to be exactly #{Constants::MEMORY_SIZE} bytes"
        exit 1
      end

      prot = LibC::PROT_READ | LibC::PROT_WRITE
      ptr = LibC.mmap(nil, Constants::MEMORY_SIZE, prot, LibC::MAP_SHARED, file.fd, 0)

      if ptr == Pointer(Void).new -1
        error "Errno(#{Errno.value}): Could not mmap #{filename} into memory"
        exit 1
      end

      monitor_input = Bytes.new(ptr.as(UInt8*), MEMORY_SIZE)

      puts "memory monitor at #{ptr}"

      monitor = VM::Monitor.new "Main Monitor", monitor_input
      monitor.start

      LibC.munmap(ptr, Constants::MEMORY_SIZE)
    end

    def help
      puts <<-HELP
        Usage: asm [command]

        Commands:
            run                 run a file
            build               assemble a file
            monitor             start the virtual monitor
            version             show version
            help                show this help
      HELP
    end

    def version
      puts "Virtual Machine 0.1.0"
    end

    # Pretty print a number in hexadecimal
    private def render_hex(num, length, color)
      num = num.to_s(16).rjust(length, '0')
      num = ("0x" + num).colorize(color)
    end

    private def error(message)
      STDOUT.puts "#{"Error:".colorize(:red).bold} #{message}"
    end

    private def warning(message)
      STDOUT.puts "#{"Warning:".colorize(:yellow).bold} #{message}"
    end

    private def success(status, message)
      STDOUT.puts "#{"#{status}:".colorize(:green).bold} #{message}"
    end
  end
end
