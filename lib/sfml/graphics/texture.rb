module SFML
  # A 2D image stored on the GPU. Used by Sprite (and shapes) to draw textured
  # geometry. Build one with .load:
  #
  #   tex = SFML::Texture.load("assets/hero.png")
  #   tex = SFML::Texture.load("assets/tile.png", smooth: true, repeated: true)
  class Texture
    def self.load(path, smooth: false, repeated: false)
      ptr = C::Graphics.sfTexture_createFromFile(path.to_s, nil)
      raise Error, "Could not load texture from #{path.inspect}" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex.smooth   = smooth
      tex.repeated = repeated
      tex
    end

    # Upload a CPU-side SFML::Image to the GPU as a new Texture. Keeps
    # the RGBA byte order and dimensions of the source image.
    def self.from_image(image, smooth: false, repeated: false)
      raise ArgumentError, "Texture.from_image needs a SFML::Image" unless image.is_a?(Image)

      ptr = C::Graphics.sfTexture_createFromImage(image.handle, nil)
      raise Error, "sfTexture_createFromImage returned NULL" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex.smooth   = smooth
      tex.repeated = repeated
      tex
    end

    # Re-upload an Image's pixels to this texture in place. The image
    # must match the texture's size — use this for animated procedural
    # textures (paint-buffer style) without re-allocating GPU memory.
    def update(image)
      raise ArgumentError, "Texture#update needs a SFML::Image" unless image.is_a?(Image)
      offset = C::System::Vector2u.new
      offset[:x] = 0; offset[:y] = 0
      C::Graphics.sfTexture_updateFromImage(@handle, image.handle, offset)
      self
    end

    # Read the texture back from the GPU into a fresh SFML::Image. Slow
    # — useful for screenshots or post-processing inspection.
    def to_image
      ptr = C::Graphics.sfTexture_copyToImage(@handle)
      raise Error, "sfTexture_copyToImage returned NULL" if ptr.null?
      img = Image.allocate
      img.send(:_take_ownership, ptr)
      img
    end

    def size
      Vector2.from_native(C::Graphics.sfTexture_getSize(@handle))
    end

    def smooth?  = C::Graphics.sfTexture_isSmooth(@handle)

    def smooth=(value)
      C::Graphics.sfTexture_setSmooth(@handle, !!value)
    end

    def repeated? = C::Graphics.sfTexture_isRepeated(@handle)

    def repeated=(value)
      C::Graphics.sfTexture_setRepeated(@handle, !!value)
    end

    attr_reader :handle # :nodoc:

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfTexture_destroy))
    end
  end
end
