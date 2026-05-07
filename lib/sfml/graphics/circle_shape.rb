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
    CSFML_PREFIX = :sfCircleShape

    def initialize(radius: 10.0, **opts)
      ptr = C::Graphics.sfCircleShape_create
      raise Error, "sfCircleShape_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfCircleShape_destroy))

      self.radius = radius
      self.point_count        = opts[:point_count]        if opts[:point_count]
      self.fill_color         = opts[:fill_color]         if opts.key?(:fill_color)
      self.outline_color      = opts[:outline_color]      if opts.key?(:outline_color)
      self.outline_thickness  = opts[:outline_thickness]  if opts.key?(:outline_thickness)
      self.position           = opts[:position]           if opts.key?(:position)
      self.origin             = opts[:origin]             if opts.key?(:origin)
      self.rotation           = opts[:rotation]           if opts.key?(:rotation)
      self.scale              = opts[:scale]              if opts.key?(:scale)
    end

    def radius = C::Graphics.sfCircleShape_getRadius(@handle)

    def radius=(value)
      C::Graphics.sfCircleShape_setRadius(@handle, value.to_f)
    end

    def point_count = C::Graphics.sfCircleShape_getPointCount(@handle)

    def point_count=(n)
      C::Graphics.sfCircleShape_setPointCount(@handle, Integer(n))
    end

    def fill_color = Color.from_native(C::Graphics.sfCircleShape_getFillColor(@handle))

    def fill_color=(c)
      C::Graphics.sfCircleShape_setFillColor(@handle, c.to_native)
    end

    def outline_color = Color.from_native(C::Graphics.sfCircleShape_getOutlineColor(@handle))

    def outline_color=(c)
      C::Graphics.sfCircleShape_setOutlineColor(@handle, c.to_native)
    end

    def outline_thickness = C::Graphics.sfCircleShape_getOutlineThickness(@handle)

    def outline_thickness=(t)
      C::Graphics.sfCircleShape_setOutlineThickness(@handle, t.to_f)
    end

    def draw_on(target) # :nodoc:
      target._draw_native(:CircleShape, @handle)
    end

    attr_reader :handle # :nodoc:
  end
end
