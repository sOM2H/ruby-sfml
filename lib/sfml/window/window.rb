module SFML
  # A bare window with input + an OpenGL context, **without** SFML's
  # 2D batcher. Use this when you want raw OpenGL (or another
  # rendering library) and just need SFML to manage the platform-level
  # window and event loop. For 2D drawing with SFML's API, you want
  # SFML::RenderWindow instead.
  #
  #   win = SFML::Window.new(800, 600, "GL")
  #   while win.open?
  #     win.each_event do |event|
  #       case event
  #       in {type: :closed} then win.close
  #       in {type: :key_pressed, code: :escape} then win.close
  #       else
  #       end
  #     end
  #
  #     # ... draw with raw OpenGL calls here ...
  #
  #     win.display
  #   end
  class Window
    DEFAULT_STYLE = C::Window::Style::DEFAULT

    def initialize(*args, **opts)
      mode, title = parse_args(args)
      style = opts.fetch(:style, DEFAULT_STYLE)
      state = opts[:fullscreen] ? :fullscreen : :windowed

      ptr = C::Window.sfWindow_create(
        mode.to_native,
        title.to_s,
        style,
        C::Window::State[state],
        nil,
      )
      raise WindowError, "sfWindow_create returned NULL" if ptr.null?

      @handle       = FFI::AutoPointer.new(ptr, C::Window.method(:sfWindow_destroy))
      @event_buffer = C::Window::Event.new

      self.framerate_limit = opts[:framerate] if opts[:framerate]
      self.vsync = opts[:vsync]               unless opts[:vsync].nil?
    end

    def open?
      C::Window.sfWindow_isOpen(@handle)
    end

    def close
      C::Window.sfWindow_close(@handle)
      self
    end

    def display
      C::Window.sfWindow_display(@handle)
      self
    end

    # Returns the next pending Event or nil. Same shape as RenderWindow#poll_event.
    def poll_event
      return nil unless C::Window.sfWindow_pollEvent(@handle, @event_buffer)
      Event.from_native(@event_buffer)
    end

    def each_event
      return enum_for(:each_event) unless block_given?
      while (event = poll_event)
        yield event
      end
      self
    end

    def title=(value)
      C::Window.sfWindow_setTitle(@handle, value.to_s)
    end

    def size
      v = C::Window.sfWindow_getSize(@handle)
      Vector2.new(v[:x], v[:y])
    end

    def size=(value)
      vec = value.is_a?(Vector2) ? value : Vector2.new(*value)
      v = C::System::Vector2u.new
      v[:x] = Integer(vec.x); v[:y] = Integer(vec.y)
      C::Window.sfWindow_setSize(@handle, v)
    end

    def position
      v = C::Window.sfWindow_getPosition(@handle)
      Vector2.new(v[:x], v[:y])
    end

    def position=(value)
      vec = value.is_a?(Vector2) ? value : Vector2.new(*value)
      v = C::System::Vector2i.new
      v[:x] = Integer(vec.x); v[:y] = Integer(vec.y)
      C::Window.sfWindow_setPosition(@handle, v)
    end

    def visible=(value)
      C::Window.sfWindow_setVisible(@handle, value ? true : false)
    end

    def framerate_limit=(value)
      C::Window.sfWindow_setFramerateLimit(@handle, Integer(value))
    end

    def vsync=(enabled)
      C::Window.sfWindow_setVerticalSyncEnabled(@handle, enabled ? true : false)
    end

    def key_repeat_enabled=(value)
      C::Window.sfWindow_setKeyRepeatEnabled(@handle, value ? true : false)
    end

    def request_focus
      C::Window.sfWindow_requestFocus(@handle)
    end

    def focused?
      C::Window.sfWindow_hasFocus(@handle)
    end

    # Make this window's GL context current on the calling thread.
    # Useful when juggling multiple windows / off-screen contexts.
    def active=(value)
      C::Window.sfWindow_setActive(@handle, value ? true : false)
    end

    # ---- Mouse cursor ----

    def cursor=(cursor)
      raise ArgumentError, "Window#cursor= requires a SFML::Cursor" unless cursor.is_a?(Cursor)
      C::Window.sfWindow_setMouseCursor(@handle, cursor.handle)
      @cursor = cursor   # keep alive
    end

    def cursor_visible=(visible)
      C::Window.sfWindow_setMouseCursorVisible(@handle, visible ? true : false)
    end

    def cursor_grabbed=(grabbed)
      C::Window.sfWindow_setMouseCursorGrabbed(@handle, grabbed ? true : false)
    end

    # ---- Misc state ----

    def joystick_threshold=(value)
      C::Window.sfWindow_setJoystickThreshold(@handle, Float(value))
    end

    # The actual GL context settings the driver gave us — may differ
    # from what was requested via `ContextSettings`.
    def context_settings
      ContextSettings.from_native(C::Window.sfWindow_getSettings(@handle))
    end

    # Block until the next event arrives or `timeout` (a SFML::Time)
    # elapses. `nil` timeout = wait forever (matches CSFML's
    # `sfTime_Zero` / no-timeout convention).
    def wait_event(timeout: nil)
      t = timeout || Time.zero
      ok = C::Window.sfWindow_waitEvent(@handle, t.to_native, @event_buffer)
      return nil unless ok
      Event.from_native(@event_buffer)
    end

    # Replace the window's title-bar / taskbar icon with the pixels from
    # the given SFML::Image. The OS scales it as needed; 32×32 RGBA
    # is the typical sweet spot.
    def icon=(image)
      raise ArgumentError, "Window#icon= requires a SFML::Image" unless image.is_a?(SFML::Image)

      size = C::System::Vector2u.new
      size[:x] = image.width
      size[:y] = image.height
      C::Window.sfWindow_setIcon(@handle, size, C::Graphics.sfImage_getPixelsPtr(image.handle))
    end

    # Constrain user-driven resizes. Accepts a [w, h] Array, a Vector2,
    # or nil to clear the limit. When set, the OS won't let the user
    # drag the window smaller (or larger) than this — programmatic
    # `size=` is not affected.
    def minimum_size=(value)
      C::Window.sfWindow_setMinimumSize(@handle, _vec2u_or_nil(value))
    end

    def maximum_size=(value)
      C::Window.sfWindow_setMaximumSize(@handle, _vec2u_or_nil(value))
    end

    # OS-specific native handle for the underlying window — `HWND` on
    # Windows, `NSView*` on macOS, X11 `Window` xid on Linux.
    # Returns an FFI::Pointer; cast or read as the platform expects.
    def native_handle
      C::Window.sfWindow_getNativeHandle(@handle)
    end

    # Wrap an existing OS-level window. `handle` is a platform native
    # handle (Integer address or FFI::Pointer). Useful when SFML is
    # being embedded inside another framework (Qt, Gtk, raw Win32,
    # Cocoa NSView). The framework owns the window's lifecycle; SFML
    # only renders into it.
    def self.from_handle(handle)
      ptr = handle.is_a?(FFI::Pointer) ? handle : FFI::Pointer.new(:void, Integer(handle))
      raw = C::Window.sfWindow_createFromHandle(ptr, nil)
      raise WindowError, "sfWindow_createFromHandle returned NULL" if raw.null?

      win = allocate
      win.instance_variable_set(:@handle,
        FFI::AutoPointer.new(raw, C::Window.method(:sfWindow_destroy)))
      win.instance_variable_set(:@event_buffer, C::Window::Event.new)
      win
    end

    attr_reader :handle # :nodoc:

    private

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
        [args[0], args[1]]
      when 3
        [VideoMode.new(args[0], args[1]), args[2]]
      else
        raise ArgumentError,
              "Window.new takes either (video_mode, title) or " \
              "(width, height, title), got #{args.length} positional arg(s)"
      end
    end
  end
end
