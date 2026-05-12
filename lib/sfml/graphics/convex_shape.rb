module SFML
  # An arbitrary convex polygon. Define its outline by listing points in
  # order (clockwise or counter-clockwise — just stay consistent). The
  # shape must remain convex — drawing a non-convex point set produces
  # visual artifacts (CSFML doesn't validate).
  #
  #   star = SFML::ConvexShape.new(
  #     points: [[60, 0], [80, 40], [120, 50], [90, 80],
  #              [100, 120], [60, 95], [20, 120], [30, 80],
  #              [0, 50], [40, 40]],
  #     fill_color: SFML::Color.yellow,
  #   )
  #   window.draw(star)
  class ConvexShape
    include Graphics::Transformable
    include Graphics::ShapeInspectable
    CSFML_PREFIX = :sfConvexShape

    def initialize(points: nil, **opts)
      ptr = C::Graphics.sfConvexShape_create
      raise GraphicsError, "sfConvexShape_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfConvexShape_destroy))

      self.points = points if points
      self.fill_color        = opts[:fill_color]        if opts.key?(:fill_color)
      self.outline_color     = opts[:outline_color]     if opts.key?(:outline_color)
      self.outline_thickness = opts[:outline_thickness] if opts.key?(:outline_thickness)
      self.texture           = opts[:texture]           if opts.key?(:texture)
      self.texture_rect      = opts[:texture_rect]      if opts.key?(:texture_rect)
      self.position          = opts[:position]          if opts.key?(:position)
      self.origin            = opts[:origin]            if opts.key?(:origin)
      self.rotation          = opts[:rotation]          if opts.key?(:rotation)
      self.scale             = opts[:scale]             if opts.key?(:scale)
    end

    def point_count = C::Graphics.sfConvexShape_getPointCount(@handle)

    # Returns the polygon vertices as an Array of Vector2.
    def points
      n = point_count
      (0...n).map do |i|
        Vector2.from_native(C::Graphics.sfConvexShape_getPoint(@handle, i))
      end
    end

    # Replace every point. Accepts a list of [x, y] arrays or Vector2s.
    def points=(list)
      C::Graphics.sfConvexShape_setPointCount(@handle, list.length)
      list.each_with_index do |pt, i|
        vec = pt.is_a?(Vector2) ? pt : Vector2.new(*pt)
        C::Graphics.sfConvexShape_setPoint(@handle, i, vec.to_native_f)
      end
    end

    # Mutate a single vertex by index.
    def set_point(index, point)
      vec = point.is_a?(Vector2) ? point : Vector2.new(*point)
      C::Graphics.sfConvexShape_setPoint(@handle, Integer(index), vec.to_native_f)
    end

    def fill_color = Color.from_native(C::Graphics.sfConvexShape_getFillColor(@handle))

    def fill_color=(c)
      C::Graphics.sfConvexShape_setFillColor(@handle, c.to_native)
    end

    def outline_color = Color.from_native(C::Graphics.sfConvexShape_getOutlineColor(@handle))

    def outline_color=(c)
      C::Graphics.sfConvexShape_setOutlineColor(@handle, c.to_native)
    end

    def outline_thickness = C::Graphics.sfConvexShape_getOutlineThickness(@handle)

    def outline_thickness=(t)
      C::Graphics.sfConvexShape_setOutlineThickness(@handle, t.to_f)
    end

    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:ConvexShape, @handle, states_ptr)
    end

    attr_reader :handle # :nodoc:
  end
end
