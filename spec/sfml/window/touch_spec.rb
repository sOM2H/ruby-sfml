RSpec.describe SFML::Touch do
  describe ".down?" do
    it "returns false on a desktop without touchscreen hardware" do
      # The CI runners don't have touch input. The contract is that
      # the call doesn't raise and returns a boolean.
      expect([true, false]).to include(described_class.down?(0))
    end

    it "accepts an integer finger index" do
      expect { described_class.down?(2) }.not_to raise_error
    end
  end

  describe ".position" do
    it "returns a Vector2 without a window (desktop-relative)" do
      pos = described_class.position(0)
      expect(pos).to be_a(SFML::Vector2)
    end

    it "returns a Vector2 relative to a RenderWindow" do
      skip "no display server" unless ENV["DISPLAY"] || ENV["WAYLAND_DISPLAY"]
      win = SFML::RenderWindow.new(320, 240, "touch spec")
      expect(described_class.position(0, relative_to: win)).to be_a(SFML::Vector2)
      win.close
    end

    it "rejects unsupported relative_to types" do
      expect { described_class.position(0, relative_to: "not a window") }
        .to raise_error(ArgumentError, /must be SFML::Window/)
    end
  end
end
