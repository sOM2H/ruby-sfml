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
