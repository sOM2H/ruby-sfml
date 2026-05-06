module SFML
  # A textured rectangle. SFML 3 requires a Texture at construction time
  # (no default-constructible Sprite anymore), so we keep the texture
  # reference alive inside the Ruby Sprite to prevent the GC from freeing
  # the GPU resource while it's still being drawn.
  #
  #   tex    = SFML::Texture.load("hero.png")
  #   sprite = SFML::Sprite.new(tex, position: [100, 100])
  #   window.draw(sprite)
  class Sprite
    include Graphics::Transformable
    CSFML_PREFIX = :sfSprite

    def initialize(texture, **opts)
      raise ArgumentError, "Sprite requires a SFML::Texture" unless texture.is_a?(Texture)

      ptr = C::Graphics.sfSprite_create(texture.handle)
      raise Error, "sfSprite_create returned NULL" if ptr.null?
      @handle  = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfSprite_destroy))
      @texture = texture # keep alive for GC

      self.color    = opts[:color]    if opts.key?(:color)
      self.position = opts[:position] if opts.key?(:position)
      self.origin   = opts[:origin]   if opts.key?(:origin)
      self.rotation = opts[:rotation] if opts.key?(:rotation)
      self.scale    = opts[:scale]    if opts.key?(:scale)
    end

    attr_reader :texture

    def texture=(new_texture)
      raise ArgumentError, "Sprite#texture= requires a SFML::Texture" unless new_texture.is_a?(Texture)
      C::Graphics.sfSprite_setTexture(@handle, new_texture.handle, false)
      @texture = new_texture
    end

    def color = Color.from_native(C::Graphics.sfSprite_getColor(@handle))

    def color=(c)
      C::Graphics.sfSprite_setColor(@handle, c.to_native)
    end

    # Sub-region of the texture this sprite shows. Returns a SFML::Rect
    # of integer pixel coordinates. Use it for sprite-sheet animation:
    #
    #   sprite.texture_rect = SFML::Rect.new([frame * 32, 0], [32, 32])
    def texture_rect
      Rect.from_native(C::Graphics.sfSprite_getTextureRect(@handle))
    end

    def texture_rect=(rect)
      raise ArgumentError, "Sprite#texture_rect= requires a SFML::Rect" unless rect.is_a?(Rect)
      native = C::Graphics::IntRect.new
      native[:position][:x] = Integer(rect.x)
      native[:position][:y] = Integer(rect.y)
      native[:size][:x]     = Integer(rect.width)
      native[:size][:y]     = Integer(rect.height)
      C::Graphics.sfSprite_setTextureRect(@handle, native)
    end

    def local_bounds
      Rect.from_native(C::Graphics.sfSprite_getLocalBounds(@handle))
    end

    def global_bounds
      Rect.from_native(C::Graphics.sfSprite_getGlobalBounds(@handle))
    end

    def draw_on(window_handle) # :nodoc:
      C::Graphics.sfRenderWindow_drawSprite(window_handle, @handle, nil)
    end

    attr_reader :handle # :nodoc:
  end
end
