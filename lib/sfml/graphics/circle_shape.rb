module SFML
  # A filled circle (or regular polygon if you set point_count). Cheapest
  # drawable that requires no asset file — perfect for placeholders.
  #
  #   ball = SFML::CircleShape.new(
  #     radius: 20,
  #     position: [400, 300],
  #     fill_color: SFML::Color.red,
  #   )
  #   window.draw(ball)
  class CircleShape
    include Graphics::Transformable
    include Graphics::ShapeInspectable
    CSFML_PREFIX = :sfCircleShape

    # Build a CircleShape. `radius` defaults to 10 px. Any of the
    # standard styling / transform kwargs can be passed (`fill_color`,
    # `outline_color`, `outline_thickness`, `texture`, `texture_rect`,
    # `position`, `origin`, `rotation`, `scale`, `point_count`).
    def initialize(radius: 10.0, **opts)
      ptr = C::Graphics.sfCircleShape_create
      raise GraphicsError, "sfCircleShape_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfCircleShape_destroy))

      self.radius = radius
      self.point_count        = opts[:point_count]        if opts[:point_count]
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

    # Radius in pixels.
    def radius = C::Graphics.sfCircleShape_getRadius(@handle)

    # Set the radius.
    def radius=(value)
      C::Graphics.sfCircleShape_setRadius(@handle, value.to_f)
    end

    # Number of points used to approximate the circle. Default 30
    # (smooth); set to 3-8 for a regular polygon (triangle, square, ...).
    def point_count = C::Graphics.sfCircleShape_getPointCount(@handle)

    # Set the point count — see `#point_count`.
    def point_count=(n)
      C::Graphics.sfCircleShape_setPointCount(@handle, Integer(n))
    end

    # Interior fill color.
    def fill_color = Color.from_native(C::Graphics.sfCircleShape_getFillColor(@handle))

    # Set the fill color.
    def fill_color=(c)
      C::Graphics.sfCircleShape_setFillColor(@handle, c.to_native)
    end

    # Outline color (only visible when `#outline_thickness > 0`).
    def outline_color = Color.from_native(C::Graphics.sfCircleShape_getOutlineColor(@handle))

    # Set the outline color.
    def outline_color=(c)
      C::Graphics.sfCircleShape_setOutlineColor(@handle, c.to_native)
    end

    # Outline thickness in pixels. Outline is drawn outward by default —
    # set negative for inward.
    def outline_thickness = C::Graphics.sfCircleShape_getOutlineThickness(@handle)

    # Set the outline thickness.
    def outline_thickness=(t)
      C::Graphics.sfCircleShape_setOutlineThickness(@handle, t.to_f)
    end

    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:CircleShape, @handle, states_ptr)
    end

    attr_reader :handle # :nodoc:
  end
end
