module SFML
  # A chunk of game state with its own lifecycle — menu, gameplay,
  # game-over, settings overlay, etc. The host `SFML::App` keeps a
  # `current_scene` and forwards `update` / `draw` / `on_event` /
  # `on_resize` to it. Switch between scenes with `app.switch_to`
  # (or `switch_to` from inside a scene, which delegates).
  #
  #   class TitleScene < SFML::Scene
  #     on_key :enter, :start_game
  #
  #     def setup
  #       @gui = SFML::GUI::App.new(window: window, stylesheet: SHEET)
  #       # ... build UI ...
  #     end
  #
  #     def update(dt) = @gui.update(dt)
  #     def draw       = @gui.draw
  #
  #     def start_game
  #       switch_to PlayScene
  #     end
  #   end
  #
  #   class PlayScene < SFML::Scene
  #     # …
  #   end
  #
  #   class MyApp < SFML::App
  #     initial_scene TitleScene   # auto-switches to it on app setup
  #   end
  #
  # `SFML::Scene` carries its own `on_key` DSL — scene-level
  # bindings shadow app-level bindings while the scene is active.
  class Scene
    class << self
      include Keybindings
      include InputActions
    end

    include InputQueries

    # The Host SFML::App.
    attr_reader :app
    alias host app

    def initialize(app)
      @app = app
    end

    # Convenience accessors that match `SFML::App`'s.
    def window = @app.window
    # Returns the width.
    def width  = @app.width
    # Returns the height.
    def height = @app.height

    # Switch the host app to a new scene from inside this one.
    # Accepts a Scene class (instantiated with `app`) or an already-
    # constructed Scene instance.
    def switch_to(scene_or_class)
      @app.switch_to(scene_or_class)
    end

    # ---- Override these in subclasses --------------------------------------

    # Called once when the host app activates this scene (replacing
    # whatever scene was active before). Build per-scene state here.
    def setup; end

    # Called every frame the scene is active and the app isn't paused.
    def update(_dt); end

    # Called every frame after #update.
    def draw; end

    # Called for every event the framework didn't auto-handle (closed,
    # resized, and on_key bindings). Override to handle game-specific
    # input patterns.
    def on_event(_event); end

    # Window resize. Default: no-op.
    def on_resize(_width, _height); end

    # Called once when the host app switches away (or when the app
    # loop exits while this scene is active). Free per-scene
    # resources here.
    def teardown; end
  end
end
