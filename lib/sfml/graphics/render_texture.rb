module SFML
  # Off-screen rendering target. Anything you can draw on a RenderWindow
  # — sprites, shapes, text, vertex arrays — you can also draw on a
  # RenderTexture and then use its #texture as a Sprite source. Typical
  # uses: minimaps, post-processing, motion-blur trails, custom UIs that
  # composite multiple layers.
  #
  #   rt = SFML::RenderTexture.new(400, 300)
  #   rt.clear(SFML::Color.cornflower_blue)
  #   rt.draw(sprite)
  #   rt.draw(text)
  #   rt.display
  #
  #   sprite = SFML::Sprite.new(rt.texture)
  #   window.draw(sprite)
  #
  # Note: rt.texture returns a *borrowed* reference owned by the
  # RenderTexture. Keep the RenderTexture alive for as long as anything
  # uses its texture.
  class RenderTexture
    include Graphics::RenderTarget
    CSFML_PREFIX = :sfRenderTexture

    def initialize(width, height, smooth: false, repeated: false)
      size = C::System::Vector2u.new
      size[:x] = Integer(width)
      size[:y] = Integer(height)

      ptr = C::Graphics.sfRenderTexture_create(size, nil)
      raise Error, "sfRenderTexture_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfRenderTexture_destroy))

      self.smooth   = smooth
      self.repeated = repeated
    end

    def size
      v = C::Graphics.sfRenderTexture_getSize(@handle)
      Vector2.new(v[:x], v[:y])
    end

    def smooth?  = C::Graphics.sfRenderTexture_isSmooth(@handle)

    def smooth=(value)
      C::Graphics.sfRenderTexture_setSmooth(@handle, !!value)
    end

    def repeated? = C::Graphics.sfRenderTexture_isRepeated(@handle)

    def repeated=(value)
      C::Graphics.sfRenderTexture_setRepeated(@handle, !!value)
    end

    # The Texture this RenderTexture is rendering into. Borrowed — its
    # lifetime is bounded by `self`. Memoised so repeated calls return
    # the same Ruby wrapper.
    def texture
      @texture ||= begin
        ptr = C::Graphics.sfRenderTexture_getTexture(@handle)
        raise Error, "sfRenderTexture_getTexture returned NULL" if ptr.null?
        # Borrowed — RenderTexture owns the underlying sf::Texture, so
        # we wrap with a raw pointer (no AutoPointer / no destructor).
        # Sprite.new(@texture) will still get a valid handle through it.
        tex = Texture.allocate
        tex.instance_variable_set(:@handle, ptr)
        tex
      end
    end

    attr_reader :handle # :nodoc:
  end
end
