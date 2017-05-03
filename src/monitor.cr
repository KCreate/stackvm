require "sdl"
require "./constants/constants.cr"

module VM
  class Monitor
    include SDL
    include Constants

    property memory : Bytes
    property window : Window
    property renderer : Renderer

    def initialize(title, @memory)
      SDL.init Init::VIDEO

      @window = Window.new title, VRAM_WIDTH * 2, VRAM_HEIGHT * 2
      @renderer = Renderer.new @window
      @renderer.scale = {2, 2}
    end

    def start
      loop do

        # Read as many events as possible
        while event = Event.poll
          case event
          when Event::Quit
            SDL.quit
            return
          when Event::Keyboard
            interrupt event
          end
        end

        sleep 0.032
        refresh
      end
    end

    def refresh
      VRAM_HEIGHT.times do |y|
        offset = y * VRAM_WIDTH
        VRAM_WIDTH.times do |x|
          address = offset + x
          byte = (@memory + VRAM_ADDRESS)[address]

          r = ((byte & 0b11100000) >> 5) * 32
          g = ((byte & 0b00011100) >> 2) * 32
          b = ((byte & 0b00000011)) * 64

          @renderer.draw_color = {r, g, b, 255}
          @renderer.draw_point x, y
        end
      end
      @renderer.present
    end

    def interrupt(event : Event::Keyboard)
      int_memory_byte  = @memory[INTERRUPT_MEMORY, INTERRUPT_MEMORY_SIZE]
      int_memory_word  = Slice(UInt16).new int_memory_byte.to_unsafe.as(UInt16*), 8
      int_memory_dword = Slice(UInt32).new int_memory_byte.to_unsafe.as(UInt32*), 4

      int_code = @memory[INTERRUPT_CODE, 1]
      int_status = @memory[INTERRUPT_STATUS, 1]

      # Layout for the keyboard interrupt
      #
      # Address : Size : Meaning
      # 0x0     : 4    : Keycode
      # 0x4     : 2    : Keymode
      # 0x6     : 1    : Keydown / Keyup
      int_memory_dword[0] = event.keysym.sym.value
      int_memory_word[2]  = event.keysym.mod.value
      int_memory_byte[6]  = event.keydown? ? 0_u8 : 1_u8

      # Set the interrupt code
      int_code[0] = INTERRUPT_KEYBOARD
      int_status[0] = 1_u8
    end
  end
end
