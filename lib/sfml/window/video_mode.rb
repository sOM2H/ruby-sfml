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

    # All video modes the current display supports for true-fullscreen
    # window creation, sorted from most to least pixels. Filter by
    # bpp or aspect ratio in Ruby as needed.
    def self.fullscreen_modes
      count_buf = FFI::MemoryPointer.new(:size_t)
      array_ptr = C::Window.sfVideoMode_getFullscreenModes(count_buf)
      n = count_buf.read(:size_t)
      return [] if array_ptr.null? || n.zero?

      stride = C::Window::VideoMode.size
      Array.new(n) do |i|
        from_native(C::Window::VideoMode.new(array_ptr + i * stride))
      end
    end

    # Does the display actually support this mode at fullscreen?
    # Always `true` for windowed-mode use (only fullscreen is constrained
    # to the OS's allowed mode list).
    def valid?
      C::Window.sfVideoMode_isValid(to_native)
    end

    # Returns the size.
    def size = Vector2.new(@width, @height)

    # String representation for debugging.
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
