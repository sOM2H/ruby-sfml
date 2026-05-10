module SFML
  # The main drawing surface. Wraps sfRenderWindow.
  #
  #   window = SFML::RenderWindow.new(800, 600, "Hello")
  #
  #   while window.open?
  #     window.each_event do |event|
  #       case event
  #       in {type: :closed}                     then window.close
  #       in {type: :key_pressed, code: :escape} then window.close
  #       end
  #     end
  #
  #     window.clear(SFML::Color.cornflower_blue)
  #     window.display
  #   end
  class RenderWindow
    include Graphics::RenderTarget
    CSFML_PREFIX = :sfRenderWindow

    DEFAULT_STYLE = C::Window::Style::DEFAULT

    # The first form takes (width, height, title, **opts).
    # The second form takes (video_mode, title, **opts) for full control.
    #
    # Options:
    #   style:        bitmask of SFML::C::Window::Style constants
    #   fullscreen:   true to use sfFullscreen state instead of sfWindowed
    #   framerate:    cap to N FPS via sfRenderWindow_setFramerateLimit
    #   vsync:        enable vertical sync
    #   antialiasing: shorthand — MSAA level (2 / 4 / 8). Same as
    #                 passing `context: ContextSettings.new(antialiasing: N)`
    #   context:      a SFML::ContextSettings for full GL-context control
    def initialize(*args, **opts)
      mode, title = parse_args(args)
      style = opts.fetch(:style, DEFAULT_STYLE)
      state = opts[:fullscreen] ? :fullscreen : :windowed

      settings = _resolve_context_settings(opts)
      # Hold a reference for the duration of the C call so the
      # struct's memory survives until CSFML has copied it.
      @ctx_struct = settings ? settings.to_native : nil
      ctx_ptr     = @ctx_struct ? @ctx_struct.to_ptr : nil

      ptr = C::Graphics.sfRenderWindow_create(
        mode.to_native,
        title.to_s,
        style,
        C::Window::State[state],
        ctx_ptr,
      )
      raise Error, "sfRenderWindow_create returned NULL" if ptr.null?

      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfRenderWindow_destroy))
      @event_buffer = C::Window::Event.new
      @requested_context = settings

      self.framerate_limit = opts[:framerate] if opts[:framerate]
      self.vsync = opts[:vsync]               unless opts[:vsync].nil?
    end

    # The actual ContextSettings the driver gave us. May differ
    # from what we requested — the driver picks the closest level
    # of MSAA / GL version it supports.
    def context_settings
      ContextSettings.from_native(C::Graphics.sfRenderWindow_getSettings(@handle))
    end

    # What we asked for at creation time, if anything (otherwise nil).
    attr_reader :requested_context

    def open?
      C::Graphics.sfRenderWindow_isOpen(@handle)
    end

    def close
      C::Graphics.sfRenderWindow_close(@handle)
      self
    end

    # Returns the next pending Event or nil if the queue is empty.
    def poll_event
      return nil unless C::Graphics.sfRenderWindow_pollEvent(@handle, @event_buffer)
      Event.from_native(@event_buffer)
    end

    # Yields every pending event for this frame, then returns. Without a block
    # returns an Enumerator.
    def each_event
      return enum_for(:each_event) unless block_given?
      while (event = poll_event)
        yield event
      end
      self
    end

    def title=(value)
      C::Graphics.sfRenderWindow_setTitle(@handle, value.to_s)
    end

    # Apply a SFML::Cursor as the visible mouse pointer over this
    # window. Keeps a Ruby reference so the Cursor object's lifetime
    # spans at least until the next assignment.
    def cursor=(cursor)
      raise ArgumentError, "RenderWindow#cursor= requires a SFML::Cursor" unless cursor.is_a?(Cursor)
      C::Graphics.sfRenderWindow_setMouseCursor(@handle, cursor.handle)
      @cursor = cursor
    end

    # Toggle the OS mouse pointer's visibility while it's over the window.
    def cursor_visible=(visible)
      C::Graphics.sfRenderWindow_setMouseCursorVisible(@handle, visible ? true : false)
    end

    # Lock the mouse pointer inside the window's client area while
    # focused — useful for FPS-style games or when dragging widgets
    # that need pixel-precise input.
    def cursor_grabbed=(grabbed)
      C::Graphics.sfRenderWindow_setMouseCursorGrabbed(@handle, grabbed ? true : false)
    end

    def framerate_limit=(value)
      C::Graphics.sfRenderWindow_setFramerateLimit(@handle, Integer(value))
    end

    def vsync=(enabled)
      C::Graphics.sfRenderWindow_setVerticalSyncEnabled(@handle, enabled ? true : false)
    end

    def size
      v = C::Graphics.sfRenderWindow_getSize(@handle)
      Vector2.new(v[:x], v[:y])
    end

    # Replace the window's title-bar / taskbar icon with the pixels from
    # the given SFML::Image. The OS scales it as needed; 32×32 RGBA
    # is the typical sweet spot.
    def icon=(image)
      raise ArgumentError, "RenderWindow#icon= requires a SFML::Image" unless image.is_a?(Image)

      size = C::System::Vector2u.new
      size[:x] = image.width
      size[:y] = image.height
      C::Graphics.sfRenderWindow_setIcon(@handle, size, C::Graphics.sfImage_getPixelsPtr(image.handle))
    end

    # Constrain user-driven resizes. Accepts a [w, h] Array, a Vector2,
    # or nil to clear the limit. When set, the OS won't let the user
    # drag the window smaller (or larger) than this — programmatic
    # `size=` is not affected.
    def minimum_size=(value)
      C::Graphics.sfRenderWindow_setMinimumSize(@handle, _vec2u_or_nil(value))
    end

    def maximum_size=(value)
      C::Graphics.sfRenderWindow_setMaximumSize(@handle, _vec2u_or_nil(value))
    end

    # OS-specific native handle for the underlying window — `HWND` on
    # Windows, `NSView*` on macOS, X11 `Window` xid on Linux.
    def native_handle
      C::Graphics.sfRenderWindow_getNativeHandle(@handle)
    end

    # ---- Focus ----
    def focused?       = C::Graphics.sfRenderWindow_hasFocus(@handle)
    def request_focus  = C::Graphics.sfRenderWindow_requestFocus(@handle)

    # ---- OS-window state ----
    def visible=(value)
      C::Graphics.sfRenderWindow_setVisible(@handle, value ? true : false)
    end

    def key_repeat_enabled=(value)
      C::Graphics.sfRenderWindow_setKeyRepeatEnabled(@handle, value ? true : false)
    end

    def joystick_threshold=(value)
      C::Graphics.sfRenderWindow_setJoystickThreshold(@handle, Float(value))
    end

    # Top-left corner in desktop coordinates.
    def position
      Vector2.from_native(C::Graphics.sfRenderWindow_getPosition(@handle))
    end

    def position=(value)
      vec = value.is_a?(Vector2) ? value : Vector2.new(*value)
      v = C::System::Vector2i.new
      v[:x] = Integer(vec.x); v[:y] = Integer(vec.y)
      C::Graphics.sfRenderWindow_setPosition(@handle, v)
    end

    # `true` if the framebuffer is sRGB-capable (i.e. the GL
    # context was created with the sRGB attribute and the driver
    # honoured it).
    def srgb? = C::Graphics.sfRenderWindow_isSrgb(@handle)

    # ---- GL interop ----
    #
    # When mixing raw OpenGL calls with SFML rendering, surround
    # the OpenGL block with `push_gl_states` / `pop_gl_states` so
    # SFML's internal state survives. `reset_gl_states` is a
    # heavier "throw away whatever's been changed" reset.
    # `active=` toggles the GL context's activation on the
    # current thread — the only way to use SFML rendering from a
    # non-main thread.

    def active=(value)
      C::Graphics.sfRenderWindow_setActive(@handle, value ? true : false)
    end
    def push_gl_states  = C::Graphics.sfRenderWindow_pushGLStates(@handle)
    def pop_gl_states   = C::Graphics.sfRenderWindow_popGLStates(@handle)
    def reset_gl_states = C::Graphics.sfRenderWindow_resetGLStates(@handle)

    # Block until an event arrives or `timeout` (a SFML::Time)
    # elapses. Returns the next pending Event or nil on timeout.
    # Useful for low-power apps that don't need to redraw at
    # 60fps — wake on input.
    def wait_event(timeout: nil)
      t = timeout || Time.zero
      ok = C::Graphics.sfRenderWindow_waitEvent(@handle, t.to_native, @event_buffer)
      return nil unless ok
      Event.from_native(@event_buffer)
    end

    # The pixel-space rect a `view` projects onto inside this
    # window. Combines the view's normalised viewport with the
    # window's pixel size.
    def viewport(view = self.view)
      raise ArgumentError, "expected a SFML::View" unless view.is_a?(View)
      Rect.from_native(C::Graphics.sfRenderWindow_getViewport(@handle, view.handle))
    end

    # The pixel-space scissor rect — same idea as `viewport` but
    # for the view's `scissor` property. Pixels outside this rect
    # are clipped before rendering.
    def scissor(view = self.view)
      raise ArgumentError, "expected a SFML::View" unless view.is_a?(View)
      Rect.from_native(C::Graphics.sfRenderWindow_getScissor(@handle, view.handle))
    end

    # Wrap an existing OS-level window. `handle` is a platform native
    # handle (Integer address or FFI::Pointer). Useful for embedding
    # the renderer inside another framework's window (Qt, Gtk, raw
    # Win32, NSView).
    def self.from_handle(handle)
      ptr = handle.is_a?(FFI::Pointer) ? handle : FFI::Pointer.new(:void, Integer(handle))
      raw = C::Graphics.sfRenderWindow_createFromHandle(ptr, nil)
      raise Error, "sfRenderWindow_createFromHandle returned NULL" if raw.null?

      win = allocate
      win.instance_variable_set(:@handle,
        FFI::AutoPointer.new(raw, C::Graphics.method(:sfRenderWindow_destroy)))
      win.instance_variable_set(:@event_buffer, C::Window::Event.new)
      win
    end

    # Convenience driver loop. Yields the per-frame delta (SFML::Time) and
    # auto-pumps events + display. The block is responsible for #clear and
    # any drawing.
    #
    #   window.run do |dt, events|
    #     events.each { |e| ... }
    #     window.clear(...)
    #     window.draw(...)
    #   end
    def run
      clock = Clock.new
      while open?
        dt = clock.restart
        events = each_event.to_a
        yield dt, events
        display
      end
      self
    end

    attr_reader :handle # :nodoc:

    private

    def _resolve_context_settings(opts)
      if opts[:context]
        unless opts[:context].is_a?(ContextSettings)
          raise ArgumentError, "context: must be a SFML::ContextSettings"
        end
        opts[:context]
      elsif opts[:antialiasing]
        ContextSettings.new(antialiasing: opts[:antialiasing])
      end
    end

    def _vec2u_or_nil(value)
      return nil if value.nil?

      vec = value.is_a?(Vector2) ? value : Vector2.new(*value)
      v = C::System::Vector2u.new
      v[:x] = Integer(vec.x); v[:y] = Integer(vec.y)
      v
    end

    def parse_args(args)
      case args.length
      when 2
        # (video_mode, title)
        [args[0], args[1]]
      when 3
        # (width, height, title)
        [VideoMode.new(args[0], args[1]), args[2]]
      else
        raise ArgumentError,
              "RenderWindow.new takes either (video_mode, title) or " \
              "(width, height, title), got #{args.length} positional arg(s)"
      end
    end
  end
end
