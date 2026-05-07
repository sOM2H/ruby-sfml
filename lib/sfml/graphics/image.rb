module SFML
  # CPU-side bitmap. Lives in main memory and supports per-pixel reads /
  # writes — handy for procedural generation, screenshots, masks, and
  # anything that needs to inspect or modify pixel data before upload.
  #
  #   img = SFML::Image.new(800, 600, fill: SFML::Color.cornflower_blue)
  #   img = SFML::Image.load("assets/hero.png")
  #
  #   img[10, 20] = SFML::Color.red
  #   img[10, 20]                       #=> Color(255, 0, 0, 255)
  #
  #   img.flip_vertically
  #   img.save("out.png")
  #
  # Convert to a GPU-side texture for drawing:
  #
  #   tex = SFML::Texture.from_image(img)
  #   sprite = SFML::Sprite.new(tex)
  class Image
    # Create a blank image of the given size. With `fill:` it's filled
    # with that colour; without, with transparent black.
    def initialize(width, height, fill: nil)
      size = C::System::Vector2u.new
      size[:x] = Integer(width)
      size[:y] = Integer(height)

      ptr = if fill
              C::Graphics.sfImage_createFromColor(size, fill.to_native)
            else
              C::Graphics.sfImage_create(size)
            end
      raise Error, "sfImage_create returned NULL" if ptr.null?
      _take_ownership(ptr)
    end

    def self.load(path)
      ptr = C::Graphics.sfImage_createFromFile(path.to_s)
      raise Error, "Could not load image from #{path.inspect}" if ptr.null?
      img = allocate
      img.send(:_take_ownership, ptr)
      img
    end

    # Build an image from a raw RGBA byte string. `pixels` must be
    # exactly width*height*4 bytes, row-major from the top-left.
    def self.from_pixels(width, height, pixels)
      expected = Integer(width) * Integer(height) * 4
      raise ArgumentError, "expected #{expected} bytes, got #{pixels.bytesize}" if pixels.bytesize != expected

      buf = FFI::MemoryPointer.new(:uint8, expected)
      buf.write_bytes(pixels)

      size = C::System::Vector2u.new
      size[:x] = Integer(width)
      size[:y] = Integer(height)
      ptr = C::Graphics.sfImage_createFromPixels(size, buf)
      raise Error, "sfImage_createFromPixels returned NULL" if ptr.null?

      img = allocate
      img.send(:_take_ownership, ptr)
      img
    end

    def size
      Vector2.from_native(C::Graphics.sfImage_getSize(@handle))
    end

    def width  = size.x
    def height = size.y

    # Read the colour of a single pixel.
    def [](x, y)
      coord = C::System::Vector2u.new
      coord[:x] = Integer(x); coord[:y] = Integer(y)
      Color.from_native(C::Graphics.sfImage_getPixel(@handle, coord))
    end

    # Write a single pixel.
    def []=(x, y, color)
      coord = C::System::Vector2u.new
      coord[:x] = Integer(x); coord[:y] = Integer(y)
      C::Graphics.sfImage_setPixel(@handle, coord, color.to_native)
    end

    # Write the entire pixel buffer back as a Ruby String. Useful for
    # piping to image-processing libraries or writing custom file formats.
    # Format: width*height*4 bytes, RGBA, row-major from top-left.
    def pixels
      ptr = C::Graphics.sfImage_getPixelsPtr(@handle)
      ptr.read_bytes(width * height * 4)
    end

    def save(path)
      ok = C::Graphics.sfImage_saveToFile(@handle, path.to_s)
      raise Error, "Could not save image to #{path.inspect}" unless ok
      path
    end

    # Replace any pixel matching `color` with that colour at `alpha`
    # opacity — typical use is to turn a fixed background colour
    # transparent: img.mask_color!(SFML::Color.magenta, alpha: 0).
    def mask_color!(color, alpha: 0)
      C::Graphics.sfImage_createMaskFromColor(@handle, color.to_native, Integer(alpha))
      self
    end

    def flip_horizontally
      C::Graphics.sfImage_flipHorizontally(@handle)
      self
    end

    def flip_vertically
      C::Graphics.sfImage_flipVertically(@handle)
      self
    end

    attr_reader :handle # :nodoc:

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfImage_destroy))
    end
  end
end
