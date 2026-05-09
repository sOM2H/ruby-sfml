RSpec.describe SFML::Scene do
  # Scene tests don't need a window — we instantiate scenes against
  # a stub app that records lifecycle events.
  let(:app) do
    a = Object.new
    log = []
    a.define_singleton_method(:log) { log }
    a.define_singleton_method(:window) { :w }
    a.define_singleton_method(:width)  { 800 }
    a.define_singleton_method(:height) { 600 }
    a.define_singleton_method(:switch_to) { |s| log << [:app_switch_to, s] }
    a
  end

  describe "convenience accessors" do
    it "delegates window/width/height to the host app" do
      scene = described_class.new(app)
      expect(scene.window).to eq(:w)
      expect(scene.width).to  eq(800)
      expect(scene.height).to eq(600)
    end
  end

  describe "switch_to delegates to the host app" do
    it "passes through to app.switch_to" do
      scene = described_class.new(app)
      scene.switch_to(:other)
      expect(app.log).to eq([[:app_switch_to, :other]])
    end
  end

  describe "lifecycle hooks default to no-ops" do
    it "doesn't raise when called" do
      scene = described_class.new(app)
      expect { scene.setup }.not_to raise_error
      expect { scene.update(0.0) }.not_to raise_error
      expect { scene.draw }.not_to raise_error
      expect { scene.on_event({}) }.not_to raise_error
      expect { scene.on_resize(800, 600) }.not_to raise_error
      expect { scene.teardown }.not_to raise_error
    end
  end

  describe "on_key class DSL" do
    let(:scene_class) do
      Class.new(SFML::Scene) do
        on_key :enter, :go
        on_key :p     do |scene| scene.poke end
      end
    end

    it "stores symbol handlers" do
      expect(scene_class.key_handlers[:enter]).to eq(:go)
    end

    it "stores block handlers as Procs" do
      expect(scene_class.key_handlers[:p]).to be_a(Proc)
    end

    it "subclass on_key bindings layer on top of parent" do
      child = Class.new(scene_class) do
        on_key :enter, :stop
        on_key :esc,   :back
      end
      expect(child.key_handlers).to include(enter: :stop, esc: :back)
      expect(child.key_handlers[:p]).to be_a(Proc)   # inherited from parent
    end
  end
end

RSpec.describe "SFML::App scene integration" do
  # A Scene that records lifecycle events for assertion.
  let(:recorder_scene) do
    Class.new(SFML::Scene) do
      attr_reader :log

      on_key :s, :poke

      def initialize(app)
        super
        @log = []
      end

      def setup           = @log << :setup
      def teardown        = @log << :teardown
      def update(dt)      = @log << [:update, dt]
      def draw            = @log << :draw
      def on_event(e)     = @log << [:event, e[:type]]
      def on_resize(w, h) = @log << [:resize, w, h]

      def poke = @log << :s_pressed
    end
  end

  # Lightweight harness: subclass App and stub out the parts that
  # need an actual window so we can drive _dispatch / lifecycle in
  # isolation.
  let(:app_class) do
    rs = recorder_scene
    Class.new(SFML::App) do
      define_singleton_method(:_recorder_scene) { rs }
      initial_scene rs
    end
  end

  let(:app) do
    instance = app_class.allocate
    instance.instance_variable_set(:@window, nil)
    instance.instance_variable_set(:@background_color, nil)
    instance
  end

  it "switch_to instantiates a Class with self as host" do
    app.switch_to(recorder_scene)
    expect(app.current_scene).to be_a(recorder_scene)
    expect(app.current_scene.app).to eq(app)
  end

  it "switch_to fires teardown on the previous scene before setup on the new one" do
    a = app.switch_to(recorder_scene)
    b = app.switch_to(recorder_scene)
    expect(a.log).to include(:setup, :teardown)
    expect(b.log).to include(:setup)
    expect(b.log).not_to include(:teardown)   # b is still active
  end

  it "App#setup auto-switches to initial_scene" do
    app.setup
    expect(app.current_scene).to be_a(recorder_scene)
    expect(app.current_scene.log).to include(:setup)
  end

  it "App#update / #draw / #on_event / #on_resize forward to the active scene" do
    app.setup
    app.update(0.1)
    app.draw
    app.on_event({type: :foo})
    app.on_resize(900, 700)

    log = app.current_scene.log
    expect(log).to include([:update, 0.1])
    expect(log).to include(:draw)
    expect(log).to include([:event, :foo])
    expect(log).to include([:resize, 900, 700])
  end

  it "scene-level on_key bindings fire when the scene is active" do
    app.setup
    app.send(:_dispatch, {type: :key_pressed, code: :s})
    expect(app.current_scene.log).to include(:s_pressed)
  end

  it "app-level on_key wins when scene doesn't bind that key" do
    app_quit = app
    quit_called = false
    app_quit.define_singleton_method(:quit) { quit_called = true }
    app_quit.class.on_key(:escape, :quit)

    app.setup
    app.send(:_dispatch, {type: :key_pressed, code: :escape})
    expect(quit_called).to be true
  end

  it "scene-level binding shadows app-level for the same key" do
    app.class.on_key(:s, :_app_s)
    app.define_singleton_method(:_app_s) { @app_s_called = true }

    app.setup
    app.send(:_dispatch, {type: :key_pressed, code: :s})
    # Scene's :s handler ran, not app's.
    expect(app.current_scene.log).to include(:s_pressed)
    expect(app.instance_variable_get(:@app_s_called)).to be_nil
  end
end
