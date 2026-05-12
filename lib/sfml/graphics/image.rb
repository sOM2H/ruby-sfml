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
      raise GraphicsError, "sfImage_create returned NULL" if ptr.null?
      _take_ownership(ptr)
    end

    def self.load(path)
      ptr = C::Graphics.sfImage_createFromFile(path.to_s)
      raise LoadError, "Could not load image from #{path.inspect}" if ptr.null?
      img = allocate
      img.send(:_take_ownership, ptr)
      img
    end

    # Decode an image from a Ruby String of bytes (PNG, JPG, BMP,
    # TGA, GIF, HDR, PSD — whatever stb_image / SFML's loader
    # supports). Mirror of `Image#save_to_memory` for round-trips
    # without touching the disk.
    def self.from_memory(bytes)
      raise ArgumentError, "expected a String, got #{bytes.class}" unless bytes.is_a?(String)

      buf = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
      buf.write_bytes(bytes)
      ptr = C::Graphics.sfImage_createFromMemory(buf, bytes.bytesize)
      raise LoadError, "sfImage_createFromMemory returned NULL — unsupported format?" if ptr.null?

      img = allocate
      img.send(:_take_ownership, ptr)
      img
    end

    # Decode an image from any Ruby IO-like object (File, StringIO,
    # network-backed reader). The stream must support read/seek/pos/size.
    def self.from_stream(io)
      stream = SFML::InputStream.new(io)
      ptr = C::Graphics.sfImage_createFromStream(stream.to_ptr)
      raise LoadError, "sfImage_createFromStream returned NULL — unsupported format?" if ptr.null?

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
      raise LoadError, "sfImage_createFromPixels returned NULL" if ptr.null?

      img = allocate
      img.send(:_take_ownership, ptr)
      img
    end

    def size
      Vector2.from_native(C::Graphics.sfImage_getSize(@handle))
    end

    # Returns the width.
    def width  = size.x
    # Returns the height.
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

    # Copy a rectangular region of `source` into this image. The
    # source region is `source_rect` (a `SFML::Rect` or `[x, y, w,
    # h]` Array; defaults to the entire source); the destination
    # top-left in this image is `at` (`[x, y]`). When `apply_alpha`
    # is true, the source's alpha channel blends with this image's
    # existing pixels; otherwise the copy is opaque.
    #
    # Useful for stamping sprites onto an atlas, blitting one
    # image into a sub-rect of another, or hand-building a
    # composite before uploading to GPU.
    def copy_from(source, at:, source_rect: nil, apply_alpha: false)
      raise ArgumentError, "Image#copy_from needs a SFML::Image" unless source.is_a?(Image)

      dest = C::System::Vector2u.new
      dest[:x] = Integer(at[0]); dest[:y] = Integer(at[1])

      sr_struct = C::Graphics::IntRect.new
      x, y, w, h =
        case source_rect
        when nil   then [0, 0, 0, 0]   # zeroes = "entire source" in CSFML
        when Rect  then [source_rect.x, source_rect.y, source_rect.width, source_rect.height]
        when Array then source_rect
        else raise ArgumentError, "source_rect must be a SFML::Rect or [x, y, w, h]"
        end
      sr_struct[:position][:x] = Integer(x); sr_struct[:position][:y] = Integer(y)
      sr_struct[:size][:x]     = Integer(w); sr_struct[:size][:y]     = Integer(h)
      C::Graphics.sfImage_copyImage(@handle, source.handle, dest, sr_struct, !!apply_alpha)
      self
    end

    def save(path)
      ok = C::Graphics.sfImage_saveToFile(@handle, path.to_s)
      raise LoadError, "Could not save image to #{path.inspect}" unless ok
      path
    end

    # Encode the image as `format` ("png", "jpg", "bmp", or "tga") and
    # return the encoded bytes as a Ruby String. Useful for sending
    # screenshots over the network, generating data: URLs, piping into
    # an image-processing library, etc., without touching the disk.
    #
    #   png_bytes = img.save_to_memory("png")
    #   File.binwrite("out.png", png_bytes)
    def save_to_memory(format)
      buffer = C::System.sfBuffer_create
      raise GraphicsError, "sfBuffer_create returned NULL" if buffer.null?

      begin
        ok = C::Graphics.sfImage_saveToMemory(@handle, buffer, format.to_s)
        raise LoadError, "Could not encode image as #{format.inspect}" unless ok

        size = C::System.sfBuffer_getSize(buffer)
        data = C::System.sfBuffer_getData(buffer)
        data.read_bytes(size)
      ensure
        C::System.sfBuffer_destroy(buffer)
      end
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
