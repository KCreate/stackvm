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

          renderer.draw_color = {byte, byte, byte, 255}
          renderer.draw_point x, y
        end
      end
      renderer.present
    end

  end

end
