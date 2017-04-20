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
        break if Event.poll.is_a? Event::Quit
        sleep 0.032
        refresh
      end

      SDL.quit
    end

    def refresh
      VRAM_HEIGHT.times do |y|
        offset = y * VRAM_WIDTH
        VRAM_WIDTH.times do |x|
          address = offset + x
          byte = @memory[address]

          r = ((byte & 0b11100000) >> 5) * 32
          g = ((byte & 0b00011100) >> 2) * 32
          b = ((byte & 0b00000011)) * 64

          @renderer.draw_color = {r, g, b, 255}
          @renderer.draw_point x, y
        end
      end
      @renderer.present
    end

  end

end
