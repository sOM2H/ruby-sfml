module SFML
  # Subclass-friendly main loop. Removes the boilerplate of window
  # creation, event pumping, clock management, and clear/display so
  # a small app fits in a few methods.
  #
  #   class MyApp < SFML::App
  #     antialiasing 4               # class-level config — applies to every instance
  #     framerate    120
  #     background   SFML::Color.new(18, 20, 28)
  #
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
  #   MyApp.new(title: "Hello").run
  #
  # The loop auto-handles :closed and :key_pressed/:escape by calling
  # #quit; everything else is forwarded to #on_event. Override that
  # to handle keys, mouse, etc.
  #
  # ## Configuration
  #
  # Every constructor kwarg is also a class-level macro: declare
  # defaults with `antialiasing 4` etc. inside the class body, and
  # `MyApp.new` picks them up. Per-instance kwargs still win on a
  # case-by-case basis. Subclasses inherit their parent's settings
  # — set one in a base class, override in a subclass.
  class App
    CONFIG_KEYS = %i[
      width height title
      framerate vsync background
      style fullscreen
      antialiasing context
      fixed_timestep
    ].freeze

    # Cap on catch-up update calls per frame when running with
    # `fixed_timestep`. Prevents the "spiral of death" where a slow
    # frame queues so many physics steps that the next frame is
    # even slower. After this many steps, residual time is dropped.
    FIXED_TIMESTEP_MAX_CATCHUP = 5

    class << self
      CONFIG_KEYS.each do |key|
        # Each macro doubles as a reader (no args) and a writer
        # (one arg). When reading, walks up the inheritance chain so
        # a subclass picks up the parent's value if it hasn't
        # overridden it.
        define_method(key) do |*args|
          ivar = "@#{key}"
          if args.empty?
            return instance_variable_get(ivar) if instance_variable_defined?(ivar)
            return superclass.send(key) if superclass.respond_to?(key)

            nil
          else
            instance_variable_set(ivar, args.first)
          end
        end
      end

      include Keybindings   # provides `on_key` + `key_handlers`
      include InputActions  # provides `action` + `action_bindings`

      # Set the scene class the app should switch into automatically
      # at `setup` time. Inheritable: a subclass that doesn't set
      # one inherits the parent's choice.
      def initial_scene(klass = nil)
        @initial_scene = klass if klass
        return @initial_scene if instance_variable_defined?(:@initial_scene)
        superclass.respond_to?(:initial_scene) ? superclass.initial_scene : nil
      end
    end

    include InputQueries

    attr_reader   :window
    attr_accessor :background_color

    # Per-instance kwargs override anything set at the class level.
    # Anything not given here OR at the class level falls back to
    # the hard-coded defaults below.
    def initialize(**opts)
      cfg = self.class

      width        = opts[:width]        || cfg.width        || 800
      height       = opts[:height]       || cfg.height       || 600
      title        = opts[:title]        || cfg.title        || cfg.name
      framerate    = opts[:framerate]    || cfg.framerate    || 60
      vsync        = opts.fetch(:vsync,        cfg.vsync)
      background   = opts[:background]   || cfg.background   || Color::BLACK
      style        = opts.fetch(:style,        cfg.style)
      fullscreen   = opts.fetch(:fullscreen,   cfg.fullscreen)
      fullscreen   = false if fullscreen.nil?
      antialiasing = opts.fetch(:antialiasing, cfg.antialiasing)
      context      = opts.fetch(:context,      cfg.context)

      window_opts = { framerate: framerate, fullscreen: fullscreen }
      window_opts[:vsync]        = vsync         unless vsync.nil?
      window_opts[:style]        = style         unless style.nil?
      window_opts[:antialiasing] = antialiasing  unless antialiasing.nil?
      window_opts[:context]      = context       unless context.nil?

      @window           = RenderWindow.new(width, height, title, **window_opts)
      @background_color = background
    end

    # Width and height shortcuts that always reflect the current
    # window size — matters once the user is allowed to resize.
    def width  = @window.size.x
    def height = @window.size.y

    # Close the window. The main loop exits at the start of the
    # next frame.
    def quit
      @window.close
      self
    end

    # ---- Scenes ----
    #
    # `current_scene` is whatever the app last activated via
    # `switch_to`. When non-nil, App's default `update` / `draw` /
    # `on_event` / `on_resize` forward to it; key bindings on the
    # scene class shadow ones on the app class while the scene is
    # active.

    attr_reader :current_scene

    # Activate `scene_or_class`. Tears down the previous scene
    # before calling `setup` on the new one. Accepts either:
    #   * a Scene subclass — instantiated with `self` as host
    #   * an existing Scene instance — used as-is
    def switch_to(scene_or_class)
      new_scene =
        case scene_or_class
        when Class then scene_or_class.new(self)
        else            scene_or_class
        end
      @current_scene&.teardown
      @current_scene = new_scene
      @current_scene&.setup
      @current_scene
    end

    # ---- Pause / resume ----
    #
    # While paused, `update(dt)` is *not* called — the world stops
    # advancing. `draw` keeps running so the window still updates
    # (handy for pause overlays that need to be drawn over a
    # frozen scene).

    def pause   = (@paused = true)
    def resume  = (@paused = false)
    def toggle_pause = (@paused = !paused?)
    def paused? = @paused == true

    # Fraction of a fixed timestep accumulated since the last
    # `update`. In range [0.0, 1.0). Use it in `#draw` to
    # interpolate between the previous and current world state:
    #
    #   def draw
    #     pos = @prev_pos.lerp(@curr_pos, interpolation_alpha)
    #     ...
    #   end
    #
    # Only meaningful when `fixed_timestep` is set; otherwise 0.
    attr_reader :interpolation_alpha

    # The main entry point. Calls #setup once, then runs the
    # per-frame loop until the window closes.
    #
    # When `fixed_timestep N` is set on the class, `update(dt)` is
    # called exactly N times per second (with a fixed dt), and
    # rendering runs as fast as vsync/framerate allows. This is
    # the standard pattern for deterministic physics — without it,
    # large-dt frames produce different results than small-dt frames.
    def run
      setup
      clock           = Clock.new
      ts              = self.class.fixed_timestep
      step_seconds    = ts && (1.0 / ts)
      dt_fixed        = ts && Time.seconds(step_seconds)
      accumulator     = 0.0
      @interpolation_alpha = 0.0

      while @window.open?
        frame_dt = clock.restart
        @window.each_event { |event| _dispatch(event) }

        if dt_fixed
          accumulator += frame_dt.as_seconds
          steps = 0
          while accumulator >= step_seconds && steps < FIXED_TIMESTEP_MAX_CATCHUP
            update(dt_fixed) unless paused?
            accumulator -= step_seconds
            steps += 1
          end
          # If we hit the catch-up cap, drop residual time — better
          # to slightly slow the simulation than spiral into longer
          # and longer frames.
          accumulator = 0.0 if steps == FIXED_TIMESTEP_MAX_CATCHUP
          @interpolation_alpha = accumulator / step_seconds
        else
          update(frame_dt) unless paused?
        end

        @window.clear(@background_color)
        draw
        @window.display
      end
      teardown
      self
    end

    # ---- Override these in subclasses --------------------------------------
    #
    # Defaults forward to the current scene when one is active. The
    # `initial_scene` class macro auto-instantiates a scene at
    # `setup` time so subclasses with `initial_scene Foo` don't
    # have to define `setup` themselves.

    def setup
      if (klass = self.class.initial_scene)
        switch_to(klass)
      end
    end

    def update(dt)
      @current_scene&.update(dt)
    end

    def draw
      @current_scene&.draw
    end

    # The framework consumes:
    #   * `:closed` — closes the window (always)
    #   * `:resized` — forwarded to `on_resize`
    #   * `:key_pressed` whose code matches a scene- or app-level
    #     `on_key` binding
    # Everything else lands here. Override to handle game-specific
    # input. By default forwards to the current scene's `on_event`.
    def on_event(event)
      @current_scene&.on_event(event)
    end

    # Default: forward to the current scene. Override to additionally
    # do app-wide layout fixups; call `super` to keep the scene in
    # the loop.
    def on_resize(width, height)
      @current_scene&.on_resize(width, height)
    end

    # Called once after the main loop exits. Tears down the active
    # scene by default.
    def teardown
      @current_scene&.teardown
    end

    private

    def _dispatch(event)
      case event
      in {type: :closed}
        quit
      in {type: :resized, size: {x:, y:}}
        # `:resized` fires BOTH the structured hook and the generic
        # event sink — apps that forward `on_event` to a sub-system
        # (`@gui.on_event(event)`, etc.) keep getting the event,
        # while apps that just want clean (w, h) override the hook.
        on_resize(x, y)
        on_event(event)
      in {type: :key_pressed, code:}
        # Scene-level bindings win over app-level (CSS-style cascade:
        # the more-specific layer overrides the more-general one).
        if @current_scene && (h = @current_scene.class.key_handlers[code])
          _invoke_scene_key(h)
        elsif (h = self.class.key_handlers[code])
          _invoke_key_handler(h)
        else
          on_event(event)
        end
      else
        on_event(event)
      end
    end

    def _invoke_key_handler(handler)
      case handler
      when Symbol then send(handler)
      when Proc   then handler.call(self)
      end
    end

    def _invoke_scene_key(handler)
      case handler
      when Symbol then @current_scene.send(handler)
      when Proc   then handler.call(@current_scene)
      end
    end
  end
end