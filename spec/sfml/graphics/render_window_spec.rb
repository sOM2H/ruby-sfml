RSpec.describe SFML::RenderWindow do
  before { skip "no display server" unless ENV["DISPLAY"] || ENV["WAYLAND_DISPLAY"] }

  describe "#icon=" do
    it "accepts an SFML::Image without raising" do
      win = described_class.new(320, 240, "icon spec")
      img = SFML::Image.new(32, 32, fill: SFML::Color.new(50, 100, 200))
      expect { win.icon = img }.not_to raise_error
      win.close
    end

    it "rejects non-Image arguments" do
      win = described_class.new(320, 240, "icon spec")
      expect { win.icon = :not_an_image }
        .to raise_error(ArgumentError, /requires a SFML::Image/)
      win.close
    end
  end
end
