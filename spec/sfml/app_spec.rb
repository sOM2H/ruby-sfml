RSpec.describe SFML::App do
  describe "fixed_timestep DSL" do
    it "is configurable via the class macro" do
      klass = Class.new(described_class) do
        fixed_timestep 60
      end
      expect(klass.fixed_timestep).to eq(60)
    end

    it "inherits like other config keys" do
      parent = Class.new(described_class) { fixed_timestep 30 }
      child  = Class.new(parent)
      expect(child.fixed_timestep).to eq(30)
    end

    it "child can override the parent's value" do
      parent = Class.new(described_class) { fixed_timestep 30 }
      child  = Class.new(parent) { fixed_timestep 144 }
      expect(child.fixed_timestep).to eq(144)
      expect(parent.fixed_timestep).to eq(30)
    end

    it "is nil by default (variable timestep)" do
      klass = Class.new(described_class)
      expect(klass.fixed_timestep).to be_nil
    end
  end

  describe "InputActions wiring" do
    it "extends App with the `action` macro" do
      klass = Class.new(described_class) do
        action :jump, keys: [:space]
      end
      expect(klass.action_bindings).to have_key(:jump)
    end

    it "instances respond to action_pressed? and axis" do
      klass = Class.new(described_class)
      app = klass.allocate
      expect(app.action_pressed?(:never_bound)).to be false
      expect(app.axis(negative: :a, positive: :b)).to eq(0.0)
    end
  end
end
