RSpec.describe SFML::InputActions do
  let(:app_class) do
    Class.new(SFML::App) do
      action :jump,   keys: [:space, :w]
      action :fire,   mouse_buttons: [:left]
      action :crouch, scancodes: [:scan_lshift]
      action :swap,   joy_buttons: [[0, 0]]
    end
  end

  it "stores bindings on the class with all four input categories" do
    bindings = app_class.action_bindings[:jump]
    expect(bindings[:keys]).to          eq([:space, :w])
    expect(bindings[:mouse_buttons]).to eq([])
    expect(bindings[:scancodes]).to     eq([])
    expect(bindings[:joy_buttons]).to   eq([])
  end

  it "normalises mouse_buttons / scancodes / joy_buttons to symbols/ints" do
    expect(app_class.action_bindings[:fire][:mouse_buttons]).to   eq([:left])
    expect(app_class.action_bindings[:crouch][:scancodes]).to     eq([:scan_lshift])
    expect(app_class.action_bindings[:swap][:joy_buttons]).to     eq([[0, 0]])
  end

  it "inherits bindings from parents" do
    child = Class.new(app_class) do
      action :pause, keys: [:p]
    end
    expect(child.action_bindings.keys).to include(:jump, :pause)
  end

  it "child class actions override parent on same name" do
    child = Class.new(app_class) do
      action :jump, keys: [:enter]
    end
    expect(child.action_bindings[:jump][:keys]).to eq([:enter])
  end

  describe "instance polling" do
    it "exposes #action_pressed? on Scene + App" do
      expect(app_class.instance_method(:action_pressed?)).to be_a(UnboundMethod)
      expect(SFML::Scene.instance_method(:action_pressed?)).to be_a(UnboundMethod)
    end

    it "axis(negative:, positive:) returns a Float in {-1, 0, +1}" do
      # We can't easily fake key state, but we can test the math
      # via an anonymous subclass that stubs action_pressed?.
      klass = Class.new(SFML::App) do
        action :left,  keys: [:a]
        action :right, keys: [:d]
        attr_accessor :_pressed
        def action_pressed?(name) = (@_pressed || []).include?(name)
      end

      app = klass.allocate
      app._pressed = []
      expect(app.axis(negative: :left, positive: :right)).to eq(0.0)
      app._pressed = [:right]
      expect(app.axis(negative: :left, positive: :right)).to eq(1.0)
      app._pressed = [:left]
      expect(app.axis(negative: :left, positive: :right)).to eq(-1.0)
      app._pressed = [:left, :right]
      expect(app.axis(negative: :left, positive: :right)).to eq(0.0)
    end
  end
end
