module SFML
  # A mouse cursor — either a built-in system shape, or a custom bitmap.
  # Apply it with `window.cursor = cursor`.
  #
  #   window.cursor = SFML::Cursor.system(:hand)
  #   window.cursor = SFML::Cursor.system(:not_allowed)
  #
  #   pixels = "..." # 32×32 RGBA bytes
  #   window.cursor = SFML::Cursor.from_pixels(32, 32, pixels, hotspot: [16, 16])
  #
  # See SFML::Cursor::TYPES for the full list of system shapes.
  class Cursor
    # Order matches sfCursorType in CSFML/Window/Cursor.h.
    TYPES = %i[
      arrow arrow_wait wait text hand
      size_horizontal size_vertical
      size_top_left_bottom_right size_bottom_left_top_right
      size_left size_right size_top size_bottom
      size_top_left size_bottom_right size_bottom_left size_top_right
      size_all cross help not_allowed
    ].freeze
    # Type symbol → integer index Hash.
    TYPE_INDEX = TYPES.each_with_index.to_h.freeze

    # Build a cursor matching one of the OS-supplied shapes. Some types
    # (the directional `size_*` family beyond Horizontal/Vertical) only
    # render distinct shapes on Linux — on macOS / Windows they fall
    # back to the closest equivalent.
    def self.system(type)
      code = TYPE_INDEX.fetch(type) do
        raise ArgumentError, "Unknown cursor type: #{type.inspect}. " \
                             "Expected one of: #{TYPES.inspect}"
      end
      ptr = C::Window.sfCursor_createFromSystem(code)
      raise WindowError, "sfCursor_createFromSystem returned NULL for #{type.inspect}" if ptr.null?
      _wrap(ptr)
    end

    # Build a cursor from raw RGBA pixels. `pixels` must be exactly
    # width*height*4 bytes. `hotspot:` is the [x, y] within the cursor
    # image that maps to the actual click point (e.g. tip of an arrow).
    def self.from_pixels(width, height, pixels, hotspot: [0, 0])
      expected = Integer(width) * Integer(height) * 4
      raise ArgumentError, "pixels must be #{expected} bytes, got #{pixels.bytesize}" if pixels.bytesize != expected

      buf = FFI::MemoryPointer.new(:uint8, expected)
      buf.write_bytes(pixels)

      size = C::System::Vector2u.new
      size[:x] = Integer(width); size[:y] = Integer(height)

      hot = C::System::Vector2u.new
      hot[:x] = Integer(hotspot[0]); hot[:y] = Integer(hotspot[1])

      ptr = C::Window.sfCursor_createFromPixels(buf, size, hot)
      raise WindowError, "sfCursor_createFromPixels returned NULL" if ptr.null?
      _wrap(ptr)
    end

    attr_reader :handle # :nodoc:

    # @!visibility private
    def self._wrap(ptr)
      cursor = allocate
      cursor.instance_variable_set(:@handle, FFI::AutoPointer.new(ptr, C::Window.method(:sfCursor_destroy)))
      cursor
    end
  end
end
