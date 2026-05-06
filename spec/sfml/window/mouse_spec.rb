RSpec.describe SFML::Mouse do
  describe "BUTTON_INDEX" do
    it "matches CSFML 3 sfMouseButton order: left, right, middle, extra1, extra2" do
      expect(described_class::BUTTONS).to eq(%i[left right middle extra1 extra2])
      expect(described_class::BUTTON_INDEX[:left]).to eq(0)
      expect(described_class::BUTTON_INDEX[:extra2]).to eq(4)
    end
  end

  describe "#button_pressed?" do
    it "accepts a known button without raising" do
      expect { described_class.button_pressed?(:left) }.not_to raise_error
    end

    it "returns a boolean" do
      result = described_class.button_pressed?(:right)
      expect([true, false]).to include(result)
    end

    it "honors x_button aliases" do
      expect { described_class.button_pressed?(:x_button1) }.not_to raise_error
      expect { described_class.button_pressed?(:x1) }.not_to raise_error
    end

    it "raises on unknown button names" do
      expect { described_class.button_pressed?(:scroll_lock) }
        .to raise_error(ArgumentError, /Unknown mouse button/)
    end
  end

  describe "#position (no window)" do
    # On a CI runner without a real display server (Linux headless), this
    # may segfault inside CSFML. Guard it.
    it "returns a Vector2 of integer-ish coords" do
      skip "needs a display server" unless ENV["DISPLAY"] || ENV["WAYLAND_DISPLAY"]
      pos = described_class.position
      expect(pos).to be_a(SFML::Vector2)
      expect(pos.x).to be_a(Integer)
      expect(pos.y).to be_a(Integer)
    end
  end
end
