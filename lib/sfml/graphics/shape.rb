module SFML
  # Abstract callback-driven shape — for when neither CircleShape,
  # RectangleShape, nor ConvexShape fits. Subclass and override
  # `#point_count` (returns Integer) and `#point(i)` (returns a
  # Vector2 or `[x, y]`). CSFML asks Ruby every frame for the point
  # list, so you can drive geometry from live data.
  #
  #   class Pentagon < SFML::Shape
  #     def point_count = 5
  #     def point(i)
  #       angle = i * 2 * Math::PI / 5 - Math::PI / 2
  #       [Math.cos(angle) * 50, Math.sin(angle) * 50]
  #     end
  #   end
  #
  #   pent = Pentagon.new(fill_color: SFML::Color.red, position: [400, 300])
  #   window.draw(pent)
  #
  # When your underlying geometry changes (e.g. the data feeding
  # `#point` updates), call `#update` to invalidate the cached
  # outline / bounds — otherwise the next draw will still use the
  # previously sampled points.
  #
  # CAVEATS
  # * Callbacks run on whichever thread invokes the draw. With
  #   single-threaded rendering (the SFML default) this is fine; if
  #   you're driving the renderer from a different thread, make sure
  #   `#point_count` / `#point` are thread-safe.
  # * Keep a Ruby reference to the Shape — if it's GC'd while CSFML
  #   still holds the function pointers, the next draw crashes.
  class Shape
    include Graphics::Transformable
    include Graphics::ShapeInspectable
    CSFML_PREFIX = :sfShape

    def initialize(**opts)
      # Hold strong refs so the GC doesn't disappear our FFI callbacks.
      @get_point_count_cb = FFI::Function.new(:size_t, [:pointer]) do |_user|
        Integer(point_count)
      end
      @get_point_cb = FFI::Function.new(C::System::Vector2f.by_value, [:size_t, :pointer]) do |i, _user|
        p = point(i)
        pt = p.is_a?(Vector2) ? p : Vector2.new(*p)
        v  = C::System::Vector2f.new
        v[:x] = pt.x.to_f; v[:y] = pt.y.to_f
        v
      end

      ptr = C::Graphics.sfShape_create(@get_point_count_cb, @get_point_cb, nil)
      raise GraphicsError, "sfShape_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfShape_destroy))

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

    # ---- Subclass hooks ----

    def point_count
      raise NoMethodError, "#{self.class} must override #point_count"
    end

    def point(_index)
      raise NoMethodError, "#{self.class} must override #point(index)"
    end

    # ---- Public API ----

    def fill_color = Color.from_native(C::Graphics.sfShape_getFillColor(@handle))

    def fill_color=(c)
      C::Graphics.sfShape_setFillColor(@handle, c.to_native)
    end

    def outline_color = Color.from_native(C::Graphics.sfShape_getOutlineColor(@handle))

    def outline_color=(c)
      C::Graphics.sfShape_setOutlineColor(@handle, c.to_native)
    end

    def outline_thickness = C::Graphics.sfShape_getOutlineThickness(@handle)

    def outline_thickness=(t)
      C::Graphics.sfShape_setOutlineThickness(@handle, t.to_f)
    end

    # Recompute the outline + bounds from the current `#point_count` /
    # `#point(i)`. Call after the data driving your callbacks changes.
    # No-op on construction (CSFML samples the points once at the
    # first draw).
    def update
      C::Graphics.sfShape_update(@handle)
      self
    end

    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:Shape, @handle, states_ptr)
    end

    # Abstract Shape doesn't implement #dup — every subclass has its
    # own state and copy semantics. (CSFML has no `sfShape_copy`.)
    undef_method :dup
    undef_method :clone

    attr_reader :handle # :nodoc:
  end
end
