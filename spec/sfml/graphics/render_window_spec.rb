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

  describe "#native_handle" do
    it "returns a non-null FFI::Pointer" do
      win = described_class.new(320, 240, "native handle")
      expect(win.native_handle).to be_a(FFI::Pointer)
      expect(win.native_handle.null?).to be false
      win.close
    end
  end

  describe "#minimum_size= / #maximum_size=" do
    it "accepts a [w, h] array, a Vector2, and nil without raising" do
      win = described_class.new(640, 480, "size limits spec")
      expect { win.minimum_size = [320, 240] }.not_to raise_error
      expect { win.maximum_size = SFML::Vector2[1920, 1080] }.not_to raise_error
      expect { win.minimum_size = nil }.not_to raise_error
      expect { win.maximum_size = nil }.not_to raise_error
      win.close
    end
  end
end
