require "../semantic/opcode.cr"
require "../semantic/register.cr"
require "../semantic/meta.cr"
require "colorize"
require "readline"

module StackVM::Machine::Utils
  include Semantic

  # Allows stepping through the virtual machines
  class Debugger
    property machine : Machine
    property output : IO

    def initialize(@machine, @output)
    end

    # Starts the main loop
    def start
      loop do
        ip = @machine.regs[Reg::IP]
        address = render_hex @machine.regs[Reg::IP], 8, :red

        command = Readline.readline "[#{address}]> ", true

        case command
        when "h", "help"
          print_help
        when "q", "quit"
          break
        when "m", "machine"
          machine_info
        when "r", "register"
          register_info
        when "s", "stack"
          stack_info
        when "c", "cycle"
          @machine.cycle
        when "i", "instruction"
          instruction_info
          print "\n"
        else
          print_help
        end
      end
    end

    private def print_help
      puts <<-HELP
        StackVM Debugger 0.1.0

        Available commands:

        h, help             : Show this help page
        q, quit             : Quit
        m, machine          : Show machine state
        r, register         : Show register state
        s, stack            : Show stack state
        c, cycle            : Run a single CPU cycle
        i, instruction      : Show info about the current instruction
      HELP
    end

    # Pretty print a number in hexadecimal
    private def render_hex(num, length, color)
      num = num.to_s(16).rjust(length, '0')
      num = ("0x" + num).colorize(color)
    end

    # Shows information about the current instruction
    private def instruction_info
      instruction = @machine.fetch
      opcode = render_hex instruction.opcode, 4, :red
      h1 = render_hex instruction.flag_s ? 1 : 0, 1, :green
      h2 = render_hex instruction.flag_t ? 1 : 0, 1, :green
      h3 = render_hex instruction.flag_b ? 1 : 0, 1, :green

      @output.puts "Opcode: #{Meta::Opcodes[instruction.opcode]}"
      @output.puts "Header: #{h1} #{h2} #{h3}"
      @output.puts "Description:"
      @output.puts <<-DESC
        #{Meta::Descriptions[instruction.opcode]}
      DESC
    end

    # Prints information about the machine
    private def machine_info
      memory_size = render_hex @machine.memory.size, 8, :magenta
      executable_size = render_hex @machine.executable_size, 8, :magenta

      @output.puts "Memory-size: #{memory_size}"
      @output.puts "Executable-size: #{executable_size}"
    end

    # Prints information about registers
    private def register_info
      regs = [
        render_hex(@machine.regs[Reg::R0], 16, :yellow),
        render_hex(@machine.regs[Reg::R1], 16, :yellow),
        render_hex(@machine.regs[Reg::R2], 16, :yellow),
        render_hex(@machine.regs[Reg::R3], 16, :yellow),
        render_hex(@machine.regs[Reg::R4], 16, :yellow),
        render_hex(@machine.regs[Reg::R5], 16, :yellow),
        render_hex(@machine.regs[Reg::R6], 16, :yellow),
        render_hex(@machine.regs[Reg::R7], 16, :yellow),
        render_hex(@machine.regs[Reg::R8], 16, :yellow),
        render_hex(@machine.regs[Reg::R9], 16, :yellow),
        render_hex(@machine.regs[Reg::R10], 16, :yellow),
        render_hex(@machine.regs[Reg::R11], 16, :yellow),
        render_hex(@machine.regs[Reg::R12], 16, :yellow),
        render_hex(@machine.regs[Reg::R13], 16, :yellow),
        render_hex(@machine.regs[Reg::R14], 16, :yellow),
        render_hex(@machine.regs[Reg::R15], 16, :yellow),

        render_hex(@machine.regs[Reg::IP], 16, :yellow),
        render_hex(@machine.regs[Reg::SP], 16, :yellow),
        render_hex(@machine.regs[Reg::FP], 16, :yellow)
      ]

      @output.puts <<-REGS
        r0: #{regs[0]}    r8:  #{regs[8]}
        r1: #{regs[1]}    r9:  #{regs[9]}
        r2: #{regs[2]}    r10: #{regs[10]}
        r3: #{regs[3]}    r11: #{regs[11]}
        r4: #{regs[4]}    r12: #{regs[12]}
        r5: #{regs[5]}    r13: #{regs[13]}
        r6: #{regs[6]}    r14: #{regs[14]}
        r7: #{regs[7]}    r15: #{regs[15]}

        ip: #{regs[16]}    sp:  #{regs[17]}
        fp: #{regs[18]}

      REGS
    end

    # Prints information about the stack
    private def stack_info
      @output.puts "Stack size: #{@machine.regs[Reg::SP] - @machine.executable_size} bytes"
      stack_memory = @machine.memory_read(
        @machine.executable_size,
        @machine.regs[Reg::SP] - @machine.executable_size
      )
      @output.puts stack_memory.hexdump
    end
  end

end
