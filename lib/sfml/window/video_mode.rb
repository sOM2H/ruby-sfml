module SFML
  # Video mode = (width, height, bits-per-pixel). Used when creating windows.
  #
  #   SFML::VideoMode.new(800, 600)
  #   SFML::VideoMode.desktop_mode
  class VideoMode
    attr_reader :width, :height, :bits_per_pixel

    def initialize(width, height, bits_per_pixel = 32)
      @width = Integer(width)
      @height = Integer(height)
      @bits_per_pixel = Integer(bits_per_pixel)
      freeze
    end

    def self.desktop_mode
      from_native(C::Window.sfVideoMode_getDesktopMode)
    end

    def size = Vector2.new(@width, @height)

    def to_s = "#<SFML::VideoMode #{@width}x#{@height}@#{@bits_per_pixel}>"
    alias inspect to_s

    def self.from_native(struct) # :nodoc:
      new(struct[:size][:x], struct[:size][:y], struct[:bits_per_pixel])
    end

    def to_native # :nodoc:
      C::Window::VideoMode.new.tap do |m|
        m[:size][:x] = @width
        m[:size][:y] = @height
        m[:bits_per_pixel] = @bits_per_pixel
      end
    end
  end
end
