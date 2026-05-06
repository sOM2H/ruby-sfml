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
    DEFAULT_STYLE = C::Window::Style::DEFAULT

    # The first form takes (width, height, title, **opts).
    # The second form takes (video_mode, title, **opts) for full control.
    #
    # Options:
    #   style:      bitmask of SFML::C::Window::Style constants
    #   fullscreen: true to use sfFullscreen state instead of sfWindowed
    #   framerate:  cap to N FPS via sfRenderWindow_setFramerateLimit
    #   vsync:      enable vertical sync
    def initialize(*args, **opts)
      mode, title = parse_args(args)
      style = opts.fetch(:style, DEFAULT_STYLE)
      state = opts[:fullscreen] ? :fullscreen : :windowed

      ptr = C::Graphics.sfRenderWindow_create(
        mode.to_native,
        title.to_s,
        style,
        C::Window::State[state],
        nil,
      )
      raise Error, "sfRenderWindow_create returned NULL" if ptr.null?

      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfRenderWindow_destroy))
      @event_buffer = C::Window::Event.new

      self.framerate_limit = opts[:framerate] if opts[:framerate]
      self.vsync = opts[:vsync]               unless opts[:vsync].nil?
    end

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

    def clear(color = Color::BLACK)
      C::Graphics.sfRenderWindow_clear(@handle, color.to_native)
      self
    end

    # Draw any object that responds to #draw_on. Sprite, CircleShape,
    # RectangleShape and Text all do. Polymorphic dispatch instead of a
    # type-switch keeps the door open for user-defined drawables (e.g. a
    # composite scene node that calls window.draw on each child).
    def draw(drawable)
      drawable.draw_on(@handle)
      self
    end

    def display
      C::Graphics.sfRenderWindow_display(@handle)
      self
    end

    def title=(value)
      C::Graphics.sfRenderWindow_setTitle(@handle, value.to_s)
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
