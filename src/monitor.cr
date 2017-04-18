require "sdl"
require "./constants/constants.cr"

module VM

  class Monitor
    include SDL
    include Constants

    property memory : Bytes
    property title : String
    property scaling : Int32

    def initialize(@title, @scaling)
      @memory = Bytes.new 0
    end

    def start
      SDL.init Init::VIDEO

      window = Window.new @title, VRAM_WIDTH * @scaling, VRAM_HEIGHT * @scaling
      renderer = Renderer.new window
      renderer.scale = {@scaling, @scaling}

      loop do
        break if Event.poll.is_a? Event::Quit
        Monitor.refresh window, renderer, @memory
      end

      SDL.quit
    end

    def self.refresh(window : Window, renderer : Renderer, memory)
      VRAM_HEIGHT.times do |y|
        offset = y * VRAM_WIDTH
        VRAM_WIDTH.times do |x|
          address = offset + x
          byte = memory[address]

          r = ((byte & 0b11100000) >> 5) * 32
          g = ((byte & 0b00011100) >> 2) * 32
          b = ((byte & 0b00000011)) * 64

          renderer.draw_color = {r, g, b, 255}
          renderer.draw_point x, y
        end
      end
      renderer.present
    end

  end

end
