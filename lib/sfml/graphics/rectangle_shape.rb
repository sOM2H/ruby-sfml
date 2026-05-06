module SFML
  # An axis-aligned filled rectangle.
  #
  #   wall = SFML::RectangleShape.new(
  #     size: [200, 40],
  #     position: [100, 500],
  #     fill_color: SFML::Color["#444"],
  #   )
  #   window.draw(wall)
  class RectangleShape
    include Graphics::Transformable
    CSFML_PREFIX = :sfRectangleShape

    def initialize(size:, **opts)
      ptr = C::Graphics.sfRectangleShape_create
      raise Error, "sfRectangleShape_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfRectangleShape_destroy))

      self.size = size
      self.fill_color         = opts[:fill_color]         if opts.key?(:fill_color)
      self.outline_color      = opts[:outline_color]      if opts.key?(:outline_color)
      self.outline_thickness  = opts[:outline_thickness]  if opts.key?(:outline_thickness)
      self.position           = opts[:position]           if opts.key?(:position)
      self.origin             = opts[:origin]             if opts.key?(:origin)
      self.rotation           = opts[:rotation]           if opts.key?(:rotation)
      self.scale              = opts[:scale]              if opts.key?(:scale)
    end

    def size
      Vector2.from_native(C::Graphics.sfRectangleShape_getSize(@handle))
    end

    def size=(value)
      vec = value.is_a?(Vector2) ? value : Vector2.new(*value)
      C::Graphics.sfRectangleShape_setSize(@handle, vec.to_native_f)
    end

    def fill_color = Color.from_native(C::Graphics.sfRectangleShape_getFillColor(@handle))

    def fill_color=(c)
      C::Graphics.sfRectangleShape_setFillColor(@handle, c.to_native)
    end

    def outline_color = Color.from_native(C::Graphics.sfRectangleShape_getOutlineColor(@handle))

    def outline_color=(c)
      C::Graphics.sfRectangleShape_setOutlineColor(@handle, c.to_native)
    end

    def outline_thickness = C::Graphics.sfRectangleShape_getOutlineThickness(@handle)

    def outline_thickness=(t)
      C::Graphics.sfRectangleShape_setOutlineThickness(@handle, t.to_f)
    end

    def draw_on(window_handle) # :nodoc:
      C::Graphics.sfRenderWindow_drawRectangleShape(window_handle, @handle, nil)
    end

    attr_reader :handle # :nodoc:
  end
end
