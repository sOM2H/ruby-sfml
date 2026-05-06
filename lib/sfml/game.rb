module SFML
  # Subclass-friendly main loop. Removes the boilerplate of window creation,
  # event pumping, clock management, and clear/display so a small game fits
  # in a few methods.
  #
  #   class MyGame < SFML::Game
  #     def setup
  #       @ball = SFML::CircleShape.new(radius: 30, position: [200, 200],
  #                                     fill_color: SFML::Color.white)
  #     end
  #
  #     def update(dt)
  #       @ball.move([60 * dt.as_seconds, 30 * dt.as_seconds])
  #     end
  #
  #     def draw
  #       window.draw(@ball)
  #     end
  #   end
  #
  #   MyGame.new(title: "Hello").run
  #
  # The loop auto-handles :closed and :key_pressed/:escape by calling #quit;
  # everything else is forwarded to #on_event. Override that to handle keys,
  # mouse, etc.
  class Game
    attr_reader   :window
    attr_accessor :background_color

    def initialize(
      width: 800, height: 600, title: nil,
      framerate: 60, vsync: nil,
      background: Color::BLACK,
      style: nil, fullscreen: false
    )
      window_opts = { framerate: framerate, fullscreen: fullscreen }
      window_opts[:vsync] = vsync   unless vsync.nil?
      window_opts[:style] = style   unless style.nil?

      @window           = RenderWindow.new(width, height, title || self.class.name, **window_opts)
      @background_color = background
    end

    # Width and height shortcuts that always reflect the current window size,
    # which matters once the user is allowed to resize.
    def width  = @window.size.x
    def height = @window.size.y

    # Close the window. The main loop exits at the start of the next frame.
    def quit
      @window.close
      self
    end

    # The main entry point. Calls #setup once, then runs the per-frame loop
    # until the window closes.
    def run
      setup
      clock = Clock.new
      while @window.open?
        dt = clock.restart
        @window.each_event { |event| _dispatch(event) }
        update(dt)
        @window.clear(@background_color)
        draw
        @window.display
      end
      teardown
      self
    end

    # ---- Override these in subclasses --------------------------------------

    # Called once, just before the first frame. Build initial state here.
    def setup; end

    # Called every frame. `dt` is a SFML::Time covering the previous frame.
    def update(dt); end

    # Called every frame after #update. Use window.draw(...) for any drawables.
    def draw; end

    # Called for events the framework didn't auto-handle (everything except
    # :closed and the Esc key). Call #quit from here to exit on a custom key.
    def on_event(event); end

    # Called once after the window closes. Useful for saving state. Default
    # is a no-op.
    def teardown; end

    private

    def _dispatch(event)
      case event
      in {type: :closed}                     then quit
      in {type: :key_pressed, code: :escape} then quit
      else                                        on_event(event)
      end
    end
  end
end
