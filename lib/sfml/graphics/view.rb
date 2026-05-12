module SFML
  # A 2D camera. A View defines what part of the world is visible in the
  # window: a centre point, a size in world units, an optional rotation,
  # and a viewport rectangle (in normalised window coords [0,1]) that
  # places the view inside the window — useful for split-screen or for
  # rendering a mini-map alongside the main camera.
  #
  # Two flows you'll typically use:
  #
  #   # 1. Define from a centre + size:
  #   camera = SFML::View.new(center: [400, 300], size: [800, 600])
  #
  #   # 2. Define from a world rectangle (top-left + size):
  #   camera = SFML::View.from_rect(SFML::Rect.new([0, 0], [1600, 1200]))
  #
  #   window.view = camera         # apply
  #   window.draw(stuff)           # everything draws through the camera
  #   window.view = window.default_view   # restore the 1:1 default
  #
  # All coordinate inputs accept either a SFML::Vector2 or a [x, y] array.
  class View
    # Build a View. All four kwargs may be passed up-front or set
    # later. `_handle:` is for internal wrapping of CSFML pointers.
    def initialize(center: nil, size: nil, rotation: nil, viewport: nil, _handle: nil)
      ptr = _handle || C::Graphics.sfView_create
      raise GraphicsError, "sfView_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfView_destroy))

      self.center   = center   if center
      self.size     = size     if size
      self.rotation = rotation if rotation
      self.viewport = viewport if viewport
    end

    # Build a View whose rectangle covers the given world Rect.
    def self.from_rect(rect)
      raise ArgumentError, "View.from_rect needs a SFML::Rect" unless rect.is_a?(Rect)

      native = C::Graphics::FloatRect.new
      native[:position][:x] = rect.x.to_f
      native[:position][:y] = rect.y.to_f
      native[:size][:x]     = rect.width.to_f
      native[:size][:y]     = rect.height.to_f

      ptr = C::Graphics.sfView_createFromRect(native)
      raise GraphicsError, "sfView_createFromRect returned NULL" if ptr.null?
      new(_handle: ptr)
    end

    # @!visibility private
    # Wrap a CSFML view pointer that we don't own (e.g. the value returned
    # by sfRenderWindow_getView). We deep-copy via sfView_copy so the Ruby
    # object owns its own lifetime.
    def self.from_borrowed(ptr)
      raise GraphicsError, "borrowed view pointer is NULL" if ptr.null?
      copy = C::Graphics.sfView_copy(ptr)
      new(_handle: copy)
    end

    # Centre point of the view in world coordinates.
    def center
      Vector2.from_native(C::Graphics.sfView_getCenter(@handle))
    end

    # Set the center.
    def center=(value)
      C::Graphics.sfView_setCenter(@handle, _vec2(value).to_native_f)
    end

    # Visible area in world units (NOT pixels). Halving this zooms in.
    def size
      Vector2.from_native(C::Graphics.sfView_getSize(@handle))
    end

    # Set the size.
    def size=(value)
      C::Graphics.sfView_setSize(@handle, _vec2(value).to_native_f)
    end

    # Rotation in degrees (counter-clockwise).
    def rotation
      C::Graphics.sfView_getRotation(@handle)
    end

    # Set the rotation.
    def rotation=(degrees)
      C::Graphics.sfView_setRotation(@handle, degrees.to_f)
    end

    # Viewport in normalised [0,1] window coordinates. Default is the full
    # window (Rect.new([0,0], [1,1])). Use [0, 0, 0.5, 1] for left half,
    # [0.75, 0, 0.25, 0.25] for a top-right mini-map, etc.
    def viewport
      Rect.from_native(C::Graphics.sfView_getViewport(@handle))
    end

    # Set the viewport.
    def viewport=(rect)
      raise ArgumentError, "View#viewport= needs a SFML::Rect" unless rect.is_a?(Rect)
      C::Graphics.sfView_setViewport(@handle, _to_floatrect(rect))
    end

    # Scissor rect in normalised [0,1] window coords — pixels
    # *outside* this rect are clipped before rendering. Default
    # `[0, 0, 1, 1]` (no clipping). Use it to render UI inside a
    # sub-region of the window without re-projecting.
    def scissor
      Rect.from_native(C::Graphics.sfView_getScissor(@handle))
    end

    # Set the scissor.
    def scissor=(rect)
      raise ArgumentError, "View#scissor= needs a SFML::Rect" unless rect.is_a?(Rect)
      C::Graphics.sfView_setScissor(@handle, _to_floatrect(rect))
    end

    # Pan the camera by an offset in world units.
    def move(offset)
      C::Graphics.sfView_move(@handle, _vec2(offset).to_native_f)
      self
    end

    # Rotate the camera by `degrees`, relative to current rotation.
    def rotate(degrees)
      C::Graphics.sfView_rotate(@handle, degrees.to_f)
      self
    end

    # Multiply the visible area by `factor`. Factor < 1.0 zooms in;
    # factor > 1.0 zooms out.
    def zoom(factor)
      C::Graphics.sfView_zoom(@handle, factor.to_f)
      self
    end

    attr_reader :handle # :nodoc:

    private

    def _to_floatrect(rect)
      native = C::Graphics::FloatRect.new
      native[:position][:x] = rect.x.to_f
      native[:position][:y] = rect.y.to_f
      native[:size][:x]     = rect.width.to_f
      native[:size][:y]     = rect.height.to_f
      native
    end

    def _vec2(value)
      value.is_a?(Vector2) ? value : Vector2.new(*value)
    end
  end
end
