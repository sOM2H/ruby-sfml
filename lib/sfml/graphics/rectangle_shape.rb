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
    include Graphics::ShapeInspectable
    CSFML_PREFIX = :sfRectangleShape

    # Build a RectangleShape. Required: `size:` (Vector2 or `[w, h]`).
    # All other styling/transform kwargs match CircleShape.
    def initialize(size:, **opts)
      ptr = C::Graphics.sfRectangleShape_create
      raise GraphicsError, "sfRectangleShape_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfRectangleShape_destroy))

      self.size = size
      self.fill_color         = opts[:fill_color]         if opts.key?(:fill_color)
      self.outline_color      = opts[:outline_color]      if opts.key?(:outline_color)
      self.outline_thickness  = opts[:outline_thickness]  if opts.key?(:outline_thickness)
      self.texture            = opts[:texture]            if opts.key?(:texture)
      self.texture_rect       = opts[:texture_rect]       if opts.key?(:texture_rect)
      self.position           = opts[:position]           if opts.key?(:position)
      self.origin             = opts[:origin]             if opts.key?(:origin)
      self.rotation           = opts[:rotation]           if opts.key?(:rotation)
      self.scale              = opts[:scale]              if opts.key?(:scale)
    end

    # Always 4 — the four corners.
    def point_count = C::Graphics.sfRectangleShape_getPointCount(@handle)

    # Current size as a Vector2.
    def size
      Vector2.from_native(C::Graphics.sfRectangleShape_getSize(@handle))
    end

    # Set the size — accepts Vector2 or `[w, h]`.
    def size=(value)
      vec = value.is_a?(Vector2) ? value : Vector2.new(*value)
      C::Graphics.sfRectangleShape_setSize(@handle, vec.to_native_f)
    end

    # Interior fill color.
    def fill_color = Color.from_native(C::Graphics.sfRectangleShape_getFillColor(@handle))

    # Set the fill color.
    def fill_color=(c)
      C::Graphics.sfRectangleShape_setFillColor(@handle, c.to_native)
    end

    # Outline color (only visible when `#outline_thickness > 0`).
    def outline_color = Color.from_native(C::Graphics.sfRectangleShape_getOutlineColor(@handle))

    # Set the outline color.
    def outline_color=(c)
      C::Graphics.sfRectangleShape_setOutlineColor(@handle, c.to_native)
    end

    # Outline thickness in pixels — negative draws inward.
    def outline_thickness = C::Graphics.sfRectangleShape_getOutlineThickness(@handle)

    # Set the outline thickness.
    def outline_thickness=(t)
      C::Graphics.sfRectangleShape_setOutlineThickness(@handle, t.to_f)
    end

    # Returns the draw on.
    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:RectangleShape, @handle, states_ptr)
    end

    attr_reader :handle # :nodoc:
  end
end
